//! Oziro Desktop shell host.
//!
//! GTK owns the Wayland layer surfaces. Each surface is a small WebView that
//! renders one part of the React UI; system access never leaves Rust. Frontend
//! requests are validated here and either handled on the GTK main thread
//! (`ui.*`) or dispatched to the service runtime on a worker thread.

#[path = "http.rs"]
mod http;
#[path = "runtime.rs"]
mod runtime;
#[path = "surfaces.rs"]
mod surfaces;

use gtk::Application;
use gtk::glib;
use gtk::prelude::*;
use oziro_protocol::{PROTOCOL_VERSION, PopupSurface, RequestEnvelope, error_codes};
use oziro_services::EventSender;
use oziro_services::error::{OziroError, OziroResult};
use runtime::HostRuntime;
use serde::Deserialize;
use serde::de::DeserializeOwned;
use serde_json::{Value, json};
use std::cell::{Cell, RefCell};
use std::rc::Rc;
use std::sync::Arc;
use std::sync::atomic::{AtomicUsize, Ordering};
use std::sync::mpsc;
use std::thread;
use std::time::Duration;
use surfaces::SurfaceManager;

const APPLICATION_ID: &str = "io.oziro.Desktop.ShellHost";

const MAX_PENDING_REQUESTS: usize = 8;
const MAX_REQUEST_BYTES: usize = 64 * 1024;
const EVENT_DRAIN_INTERVAL: Duration = Duration::from_millis(33);

type ManagerSlot = Rc<RefCell<Option<Rc<RefCell<SurfaceManager>>>>>;

#[derive(Debug, Deserialize)]
struct SurfaceParams {
    surface: PopupSurface,
}

#[derive(Debug, Deserialize)]
#[serde(rename_all = "camelCase")]
struct ResizeParams {
    width: i32,
    height: i32,
}

fn valid_request_id(id: &str) -> bool {
    !id.is_empty()
        && id.len() <= 128
        && id.chars().all(|character| {
            character.is_ascii_alphanumeric() || matches!(character, '-' | '_' | '.' | ':')
        })
}

fn parse_params<T: DeserializeOwned>(params: Option<Value>) -> OziroResult<T> {
    let value = params.ok_or_else(|| OziroError::invalid_params("params are required"))?;

    serde_json::from_value(value)
        .map_err(|error| OziroError::invalid_params(format!("invalid params: {error}")))
}

fn unknown_method(method: &str) -> OziroError {
    OziroError::new(error_codes::UNKNOWN_METHOD, format!("unknown method: {method}"), false)
}

fn dispatch_ui(
    manager: &mut SurfaceManager,
    method: &str,
    params: Option<Value>,
) -> OziroResult<Value> {
    match method {
        "ui.openPopup" => {
            let request: SurfaceParams = parse_params(params)?;
            manager.toggle(request.surface);
            Ok(json!({}))
        }
        "ui.closePopup" => {
            let request: SurfaceParams = parse_params(params)?;
            manager.hide(request.surface);
            Ok(json!({}))
        }
        "ui.resizeSurface" => {
            let request: ResizeParams = parse_params(params)?;
            manager.resize_dock(request.width, request.height);
            Ok(json!({}))
        }
        other => Err(unknown_method(other)),
    }
}

fn respond(manager_slot: &ManagerSlot, request_id: &str, response: String) {
    let manager = manager_slot.borrow().as_ref().cloned();

    if let Some(manager) = manager {
        manager.borrow().resolve(request_id, &response);
    }
}

/// Guards the in-flight counter even if a worker thread panics.
struct PendingGuard(Arc<AtomicUsize>);

impl Drop for PendingGuard {
    fn drop(&mut self) {
        self.0.fetch_sub(1, Ordering::AcqRel);
    }
}

fn dispatch_request(
    raw: &str,
    manager_slot: &ManagerSlot,
    runtime: &Arc<HostRuntime>,
    replies: &mpsc::Sender<(String, String)>,
    pending: &Arc<AtomicUsize>,
) {
    if raw.len() > MAX_REQUEST_BYTES {
        eprintln!("[OZIRO BRIDGE] rejected oversized request");
        return;
    }

    let envelope: RequestEnvelope = match serde_json::from_str(raw) {
        Ok(envelope) => envelope,
        Err(error) => {
            eprintln!("[OZIRO BRIDGE] malformed request: {error}");
            return;
        }
    };

    if !valid_request_id(&envelope.request_id) {
        eprintln!("[OZIRO BRIDGE] rejected request with an invalid id");
        return;
    }

    if envelope.protocol_version != PROTOCOL_VERSION {
        let error = OziroError::new(
            error_codes::UNSUPPORTED_PROTOCOL,
            format!("protocol version {} is not supported", envelope.protocol_version),
            false,
        );
        respond(
            manager_slot,
            &envelope.request_id,
            runtime::failure_envelope(&envelope.request_id, &error),
        );
        return;
    }

    if runtime::is_ui_method(&envelope.method) {
        let manager = manager_slot.borrow().as_ref().cloned();

        let Some(manager) = manager else {
            eprintln!("[OZIRO BRIDGE] UI request before surfaces were ready");
            return;
        };

        let response = {
            let mut manager = manager.borrow_mut();

            match dispatch_ui(&mut manager, &envelope.method, envelope.params) {
                Ok(result) => runtime::success_envelope(&envelope.request_id, result),
                Err(error) => runtime::failure_envelope(&envelope.request_id, &error),
            }
        };

        manager.borrow().resolve(&envelope.request_id, &response);
        return;
    }

    if pending.load(Ordering::Acquire) >= MAX_PENDING_REQUESTS {
        let error = OziroError::service_unavailable("Too many pending requests");
        respond(
            manager_slot,
            &envelope.request_id,
            runtime::failure_envelope(&envelope.request_id, &error),
        );
        return;
    }

    pending.fetch_add(1, Ordering::AcqRel);

    let guard = PendingGuard(pending.clone());
    let runtime = runtime.clone();
    let replies = replies.clone();
    let request_id = envelope.request_id;
    let fallback_id = request_id.clone();
    let method = envelope.method;
    let params = envelope.params;

    let spawned = thread::Builder::new().name("oziro-bridge-request".to_owned()).spawn(move || {
        let _guard = guard;

        let response = match runtime.dispatch(&method, params) {
            Ok(result) => runtime::success_envelope(&request_id, result),
            Err(error) => runtime::failure_envelope(&request_id, &error),
        };

        let _ = replies.send((request_id, response));
    });

    if let Err(error) = spawned {
        let failure = OziroError::service_failed(format!("request worker failed: {error}"));
        respond(manager_slot, &fallback_id, runtime::failure_envelope(&fallback_id, &failure));
    }
}

fn install_surface_css() {
    let provider = gtk::CssProvider::new();
    provider.load_from_data(
        "window.oziro-surface { background-color: transparent; }\n\
         window.oziro-surface > contents { background-color: transparent; }",
    );

    if let Some(display) = gtk::gdk::Display::default() {
        gtk::style_context_add_provider_for_display(
            &display,
            &provider,
            gtk::STYLE_PROVIDER_PRIORITY_APPLICATION,
        );
    }
}

fn activate(application: &Application) {
    if !gtk4_layer_shell::is_supported() {
        eprintln!("[OZIRO ERROR] Wayland Layer Shell is not supported.");
        application.quit();
        return;
    }

    install_surface_css();

    let (event_tx, event_rx) = mpsc::channel();
    let event_sender: EventSender = Arc::new(move |event| {
        let _ = event_tx.send(event);
    });

    let runtime = Arc::new(HostRuntime::new(event_sender));
    let settings = runtime.initial_settings();

    let base_url = match http::start_frontend_server(runtime.icons.clone()) {
        Ok(url) => url,
        Err(error) => {
            eprintln!("[OZIRO ERROR] {error}");
            application.quit();
            return;
        }
    };

    let (reply_tx, reply_rx) = mpsc::channel::<(String, String)>();
    let pending = Arc::new(AtomicUsize::new(0));
    let manager_slot: ManagerSlot = Rc::new(RefCell::new(None));

    let requests: Rc<dyn Fn(String)> = {
        let manager_slot = manager_slot.clone();
        let runtime = runtime.clone();
        let reply_tx = reply_tx.clone();
        let pending = pending.clone();

        Rc::new(move |raw: String| {
            dispatch_request(&raw, &manager_slot, &runtime, &reply_tx, &pending);
        })
    };

    let manager =
        Rc::new(RefCell::new(SurfaceManager::new(application, &base_url, settings, requests)));
    *manager_slot.borrow_mut() = Some(manager.clone());

    glib::timeout_add_local(EVENT_DRAIN_INTERVAL, {
        let manager = manager.clone();
        let event_rx = event_rx;
        let reply_rx = reply_rx;

        move || {
            while let Ok(event) = event_rx.try_recv() {
                if let oziro_services::OziroEvent::Settings(settings) = &event {
                    manager.borrow_mut().apply_settings_event(settings.clone());
                }

                let envelope = runtime::event_envelope(&event);
                manager.borrow().broadcast_event(&envelope);
            }

            while let Ok((request_id, response)) = reply_rx.try_recv() {
                manager.borrow().resolve(&request_id, &response);
            }

            glib::ControlFlow::Continue
        }
    });

    runtime::spawn_compositor_monitor(&runtime);
    runtime::spawn_system_poller(runtime.clone());

    eprintln!("[OZIRO] Shell ready (protocol {PROTOCOL_VERSION})");
}

fn main() -> glib::ExitCode {
    let application = Application::builder().application_id(APPLICATION_ID).build();

    let started = Rc::new(Cell::new(false));
    application.connect_activate(move |application| {
        if started.replace(true) {
            return;
        }

        activate(application);
    });

    application.run()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn application_id_uses_the_oziro_namespace() {
        assert!(APPLICATION_ID.starts_with("io.oziro."));
    }

    #[test]
    fn request_ids_are_strictly_validated() {
        assert!(valid_request_id("req-m5x1-1"));
        assert!(valid_request_id("abc_DEF:42.1"));
        assert!(!valid_request_id(""));
        assert!(!valid_request_id("has space"));
        assert!(!valid_request_id("semi;colon"));
        assert!(!valid_request_id(&"a".repeat(129)));
    }

    #[test]
    fn ui_params_are_typed() {
        let resize: ResizeParams =
            parse_params(Some(json!({ "width": 320, "height": 72 }))).expect("resize params");
        assert_eq!((resize.width, resize.height), (320, 72));

        let surface: SurfaceParams =
            parse_params(Some(json!({ "surface": "launcher" }))).expect("surface params");
        assert_eq!(surface.surface, PopupSurface::Launcher);

        assert!(parse_params::<ResizeParams>(None).is_err());
        assert!(parse_params::<SurfaceParams>(Some(json!({ "surface": "nope" }))).is_err());
        assert!(parse_params::<ResizeParams>(Some(json!({ "width": "wide" }))).is_err());
    }

    #[test]
    fn unknown_methods_carry_stable_codes() {
        assert_eq!(unknown_method("system.execute").code, error_codes::UNKNOWN_METHOD);
    }
}
