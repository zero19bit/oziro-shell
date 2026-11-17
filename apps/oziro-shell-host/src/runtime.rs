//! Allow-listed request dispatch. Every frontend method maps to one typed
//! operation here; arbitrary commands and filesystem paths never cross the
//! bridge.

use oziro_protocol::{
    AudioState, BatteryState, BluetoothState, BrightnessState, EventEnvelope, FailureEnvelope,
    FavoritesResult, IntegrationState, NetworkState, PROTOCOL_VERSION, RuntimeInfo, Settings,
    SuccessEnvelope, WindowsResult, WorkspacesResult, error_codes,
};
use oziro_services::apps::AppCatalog;
use oziro_services::compositor::{self, Compositor};
use oziro_services::error::{OziroError, OziroResult};
use oziro_services::icons::IconRegistry;
use oziro_services::notifications::NotificationsService;
use oziro_services::settings::SettingsStore;
use oziro_services::system::{
    audio, bluetooth::BluetoothService, brightness::BrightnessService, network::NetworkService,
    power::PowerService,
};
use oziro_services::{EventSender, OziroEvent, global_icons};
use serde::Deserialize;
use serde::de::DeserializeOwned;
use serde_json::{Value, json};
use std::sync::Arc;
use std::thread;
use std::time::Duration;

const APP_NAME: &str = "Oziro Desktop";
const POLL_INTERVAL: Duration = Duration::from_secs(3);

#[derive(Debug, Deserialize)]
struct SearchParams {
    query: String,
}

#[derive(Debug, Deserialize)]
#[serde(rename_all = "camelCase")]
struct DesktopIdParams {
    desktop_id: String,
}

#[derive(Debug, Deserialize)]
struct IdParams {
    id: String,
}

#[derive(Debug, Deserialize)]
struct FavoritesParams {
    favorites: Vec<String>,
}

#[derive(Debug, Deserialize)]
struct VolumeParams {
    volume: f64,
}

#[derive(Debug, Deserialize)]
struct MutedParams {
    muted: bool,
}

#[derive(Debug, Deserialize)]
struct EnabledParams {
    enabled: bool,
}

#[derive(Debug, Deserialize)]
struct PoweredParams {
    powered: bool,
}

#[derive(Debug, Deserialize)]
struct PercentParams {
    percent: f64,
}

#[derive(Debug, Deserialize)]
struct PatchParams {
    patch: Value,
}

fn params<T: DeserializeOwned>(params: Option<Value>) -> OziroResult<T> {
    let value = params.ok_or_else(|| OziroError::invalid_params("params are required"))?;

    serde_json::from_value(value)
        .map_err(|error| OziroError::invalid_params(format!("invalid params: {error}")))
}

fn to_value<T: serde::Serialize>(value: T) -> OziroResult<Value> {
    serde_json::to_value(value).map_err(|error| OziroError::internal(format!("serialize: {error}")))
}

pub struct HostRuntime {
    pub icons: Arc<IconRegistry>,
    pub apps: AppCatalog,
    pub settings: SettingsStore,
    pub compositor: Option<Arc<dyn Compositor>>,
    network: NetworkService,
    bluetooth: BluetoothService,
    power: PowerService,
    brightness: BrightnessService,
    notifications: NotificationsService,
    events: EventSender,
}

impl HostRuntime {
    pub fn new(events: EventSender) -> Self {
        let notifications = NotificationsService::new(events.clone());
        Self::build(events, notifications)
    }

    fn build(events: EventSender, notifications: NotificationsService) -> Self {
        let icons = global_icons();
        let apps = AppCatalog::new(icons.clone());

        if let Err(error) = apps.refresh() {
            eprintln!("[OZIRO APPS] catalog refresh failed: {error}");
        }

        let settings = match SettingsStore::load() {
            Ok(store) => store,
            Err(error) => {
                eprintln!("[OZIRO SETTINGS] load failed, using defaults: {error}");
                SettingsStore::load_from(std::path::Path::new("/nonexistent"))
                    .unwrap_or_else(|_| unreachable!("default settings are infallible"))
            }
        };

        let compositor = compositor::detect();

        match &compositor {
            Some(adapter) => eprintln!("[OZIRO COMPOSITOR] using {}", adapter.id()),
            None => eprintln!("[OZIRO COMPOSITOR] no supported compositor detected"),
        }

        Self {
            icons,
            apps,
            settings,
            compositor,
            network: NetworkService::new(),
            bluetooth: BluetoothService::new(),
            power: PowerService::new(),
            brightness: BrightnessService::new(),
            notifications,
            events,
        }
    }

    #[cfg(test)]
    fn for_tests(events: EventSender) -> Self {
        let notifications = NotificationsService::disabled(events.clone());
        Self::build(events, notifications)
    }

    pub fn initial_settings(&self) -> Settings {
        self.settings.get()
    }

    pub fn dispatch(&self, method: &str, request_params: Option<Value>) -> OziroResult<Value> {
        match method {
            "runtime.getInfo" => to_value(self.runtime_info()),
            "apps.list" => to_value(self.apps.list()),
            "apps.search" => {
                let request: SearchParams = params(request_params)?;
                to_value(self.apps.search(&request.query))
            }
            "apps.launch" => {
                let request: DesktopIdParams = params(request_params)?;
                self.apps.launch(&request.desktop_id)?;
                Ok(json!({}))
            }
            "apps.getFavorites" => to_value(self.favorites()),
            "apps.setFavorites" => {
                let request: FavoritesParams = params(request_params)?;
                let patch = json!({ "favorites": request.favorites });
                let updated = self.settings.update(&patch)?;
                (self.events)(OziroEvent::Settings(updated.clone()));
                to_value(FavoritesResult { favorites: updated.favorites })
            }
            "workspaces.list" => to_value(self.workspaces()),
            "workspaces.activate" => {
                let request: IdParams = params(request_params)?;
                self.compositor()?.activate_workspace(&request.id)?;
                Ok(json!({}))
            }
            "windows.list" => to_value(self.windows()),
            "windows.activate" => {
                let request: IdParams = params(request_params)?;
                self.compositor()?.activate_window(&request.id)?;
                Ok(json!({}))
            }
            "system.audio.get" => to_value(audio::get()),
            "system.audio.setVolume" => {
                let request: VolumeParams = params(request_params)?;
                to_value(audio::set_volume(request.volume)?)
            }
            "system.audio.setMuted" => {
                let request: MutedParams = params(request_params)?;
                to_value(audio::set_muted(request.muted)?)
            }
            "system.network.get" => to_value(self.network.snapshot()),
            "system.network.setWifiEnabled" => {
                let request: EnabledParams = params(request_params)?;
                to_value(self.network.set_wifi_enabled(request.enabled)?)
            }
            "system.network.setNetworkingEnabled" => {
                let request: EnabledParams = params(request_params)?;
                to_value(self.network.set_networking_enabled(request.enabled)?)
            }
            "system.bluetooth.get" => to_value(self.bluetooth.snapshot()),
            "system.bluetooth.setPowered" => {
                let request: PoweredParams = params(request_params)?;
                to_value(self.bluetooth.set_powered(request.powered)?)
            }
            "system.battery.get" => to_value(self.power.battery()),
            "system.brightness.get" => to_value(self.brightness.get()),
            "system.brightness.set" => {
                let request: PercentParams = params(request_params)?;
                to_value(self.brightness.set(request.percent)?)
            }
            "system.power.get" => to_value(self.power.power()),
            "settings.get" => to_value(self.settings.get()),
            "settings.update" => {
                let request: PatchParams = params(request_params)?;
                let updated = self.settings.update(&request.patch)?;
                (self.events)(OziroEvent::Settings(updated.clone()));
                to_value(updated)
            }
            "notifications.list" => to_value(self.notifications.list()),
            "notifications.getStatus" => to_value(self.notifications.status()),
            "notifications.dismiss" => {
                let request: IdParams = params(request_params)?;
                self.notifications.dismiss(&request.id)?;
                Ok(json!({}))
            }
            unknown => Err(OziroError::new(
                error_codes::UNKNOWN_METHOD,
                format!("unknown method: {unknown}"),
                false,
            )),
        }
    }

    fn compositor(&self) -> OziroResult<&Arc<dyn Compositor>> {
        self.compositor
            .as_ref()
            .ok_or_else(|| OziroError::compositor_unavailable("No supported compositor detected"))
    }

    fn runtime_info(&self) -> RuntimeInfo {
        let integration = match &self.compositor {
            Some(adapter) => IntegrationState::Connected { adapter: adapter.id().to_owned() },
            None => IntegrationState::NotConnected {
                reason: "No Hyprland or KWin session detected".to_owned(),
            },
        };

        RuntimeInfo {
            protocol_version: PROTOCOL_VERSION,
            app_name: APP_NAME.to_owned(),
            app_version: env!("CARGO_PKG_VERSION").to_owned(),
            integration,
        }
    }

    fn favorites(&self) -> FavoritesResult {
        FavoritesResult { favorites: self.settings.get().favorites }
    }

    fn workspaces(&self) -> WorkspacesResult {
        match &self.compositor {
            Some(adapter) => adapter
                .workspaces()
                .unwrap_or_else(|_| compositor::unavailable("Compositor did not answer").0),
            None => compositor::unavailable("No supported compositor detected").0,
        }
    }

    fn windows(&self) -> WindowsResult {
        match &self.compositor {
            Some(adapter) => adapter
                .windows()
                .unwrap_or_else(|_| compositor::unavailable("Compositor did not answer").1),
            None => compositor::unavailable("No supported compositor detected").1,
        }
    }
}

/// Starts the compositor's native monitor when available, forwarding events
/// through the same channel as every other host event.
pub fn spawn_compositor_monitor(runtime: &HostRuntime) {
    let Some(adapter) = runtime.compositor.clone() else {
        return;
    };

    match adapter.spawn_monitor(runtime.events.clone()) {
        Ok(_handle) => eprintln!("[OZIRO COMPOSITOR] monitor started for {}", adapter.id()),
        Err(error) => eprintln!("[OZIRO COMPOSITOR] monitor could not start: {error}"),
    }
}

/// Polls the services that do not expose a usable change subscription through
/// their Rust bindings. Only transitions are broadcast, so a quiet desktop
/// produces no UI work.
pub fn spawn_system_poller(runtime: Arc<HostRuntime>) {
    let _ = thread::Builder::new().name("oziro-system-poller".to_owned()).spawn(move || {
        let mut audio_state: Option<AudioState> = None;
        let mut network_state: Option<NetworkState> = None;
        let mut bluetooth_state: Option<BluetoothState> = None;
        let mut battery_state: Option<BatteryState> = None;
        let mut brightness_state: Option<BrightnessState> = None;

        loop {
            let next_audio = audio::get();
            if audio_state.as_ref() != Some(&next_audio) {
                (runtime.events)(OziroEvent::Audio(next_audio.clone()));
                audio_state = Some(next_audio);
            }

            let next_network = runtime.network.snapshot();
            if network_state.as_ref() != Some(&next_network) {
                (runtime.events)(OziroEvent::Network(next_network.clone()));
                network_state = Some(next_network);
            }

            let next_bluetooth = runtime.bluetooth.snapshot();
            if bluetooth_state.as_ref() != Some(&next_bluetooth) {
                (runtime.events)(OziroEvent::Bluetooth(next_bluetooth.clone()));
                bluetooth_state = Some(next_bluetooth);
            }

            let next_battery = runtime.power.battery();
            if battery_state.as_ref() != Some(&next_battery) {
                (runtime.events)(OziroEvent::Battery(next_battery.clone()));
                battery_state = Some(next_battery);
            }

            let next_brightness = runtime.brightness.get();
            if brightness_state.as_ref() != Some(&next_brightness) {
                (runtime.events)(OziroEvent::Brightness(next_brightness.clone()));
                brightness_state = Some(next_brightness);
            }

            thread::sleep(POLL_INTERVAL);
        }
    });
}

/* ------------------------------------------------------------------ */
/* Envelopes                                                          */
/* ------------------------------------------------------------------ */

pub fn success_envelope(request_id: &str, result: Value) -> String {
    serde_json::to_string(&SuccessEnvelope {
        protocol_version: PROTOCOL_VERSION,
        request_id: request_id.to_owned(),
        ok: true,
        result,
    })
    .unwrap_or_else(|_| "{}".to_owned())
}

pub fn failure_envelope(request_id: &str, error: &OziroError) -> String {
    serde_json::to_string(&FailureEnvelope {
        protocol_version: PROTOCOL_VERSION,
        request_id: request_id.to_owned(),
        ok: false,
        error: oziro_protocol::ErrorBody {
            code: error.code.to_owned(),
            message: error.message.clone(),
            retryable: error.retryable,
        },
    })
    .unwrap_or_else(|_| "{}".to_owned())
}

pub fn event_envelope(event: &OziroEvent) -> String {
    serde_json::to_string(&EventEnvelope {
        protocol_version: PROTOCOL_VERSION,
        event: event.name().to_owned(),
        payload: event.payload(),
    })
    .unwrap_or_else(|_| "{}".to_owned())
}

/// Methods handled by the GTK surface manager instead of the service runtime.
pub fn is_ui_method(method: &str) -> bool {
    matches!(method, "ui.openPopup" | "ui.closePopup" | "ui.resizeSurface")
}

#[cfg(test)]
mod tests {
    use super::*;
    use oziro_protocol::{NetworkType, PopupSurface};

    #[test]
    fn params_are_required_and_typed() {
        assert_eq!(params::<IdParams>(None).unwrap_err().code, error_codes::INVALID_PARAMS);
        assert_eq!(
            params::<IdParams>(Some(json!({ "id": 42 }))).unwrap_err().code,
            error_codes::INVALID_PARAMS
        );

        let parsed: IdParams = params(Some(json!({ "id": "abc" }))).unwrap();
        assert_eq!(parsed.id, "abc");
    }

    #[test]
    fn desktop_ids_use_camel_case() {
        let parsed: DesktopIdParams =
            params(Some(json!({ "desktopId": "org.kde.konsole.desktop" }))).unwrap();
        assert_eq!(parsed.desktop_id, "org.kde.konsole.desktop");
    }

    #[test]
    fn unknown_methods_are_rejected() {
        let runtime = HostRuntime::for_tests(Arc::new(|_| {}));
        let error =
            runtime.dispatch("system.execute", Some(json!({ "command": "rm" }))).unwrap_err();
        assert_eq!(error.code, error_codes::UNKNOWN_METHOD);
    }

    #[test]
    fn ui_methods_are_recognized() {
        assert!(is_ui_method("ui.openPopup"));
        assert!(is_ui_method("ui.closePopup"));
        assert!(is_ui_method("ui.resizeSurface"));
        assert!(!is_ui_method("apps.list"));
    }

    #[test]
    fn envelopes_match_the_frontend_contract() {
        let success = success_envelope("req-1", json!({ "ok": true }));
        let parsed: SuccessEnvelope = serde_json::from_str(&success).unwrap();
        assert!(parsed.ok);
        assert_eq!(parsed.protocol_version, 1);

        let failure = failure_envelope("req-2", &OziroError::invalid_params("bad"));
        let parsed: FailureEnvelope = serde_json::from_str(&failure).unwrap();
        assert!(!parsed.ok);
        assert_eq!(parsed.error.code, error_codes::INVALID_PARAMS);
    }

    #[test]
    fn popup_surfaces_parse_from_lowercase_names() {
        let parsed: PopupSurface = serde_json::from_value(json!("launcher")).unwrap();
        assert_eq!(parsed, PopupSurface::Launcher);
        assert!(serde_json::from_value::<PopupSurface>(json!("nope")).is_err());
    }

    #[test]
    fn runtime_info_reports_protocol_and_version() {
        let runtime = HostRuntime::for_tests(Arc::new(|_| {}));
        let info = runtime.runtime_info();
        assert_eq!(info.protocol_version, PROTOCOL_VERSION);
        assert_eq!(info.app_name, APP_NAME);
        assert!(!info.app_version.is_empty());
    }

    #[test]
    fn network_types_stay_in_sync_with_the_protocol() {
        // Guards against accidentally renaming the serde representation.
        assert_eq!(serde_json::to_value(NetworkType::Wifi).unwrap(), json!("wifi"));
    }
}
