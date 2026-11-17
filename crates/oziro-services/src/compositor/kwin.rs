//! KWin compositor adapter using only D-Bus capabilities that were verified
//! against a live Plasma 6 session:
//!
//! - `org.kde.KWin.VirtualDesktopManager` — workspace list, switching, and
//!   change signals (verified: /VirtualDesktopManager introspection).
//! - `org.kde.krunner1` on `/WindowsRunner` — `Match("")` lists running
//!   windows, `Run(id, "")` activates one (verified live).
//!
//! Not available through this interface (reported as unsupported, never
//! simulated): window open/close events, minimize/close operations, and the
//! identity of the focused window.

use crate::error::{OziroError, OziroResult};
use crate::{EventSender, OziroEvent, icon_for_name};
use oziro_protocol::{WindowInfo, WindowsResult, Workspace, WorkspacesResult};
use serde::Deserialize;
use std::collections::HashMap;
use std::sync::Arc;
use zbus::blocking::Connection;
use zbus::zvariant::{OwnedValue, Type};

const KWIN_DESTINATION: &str = "org.kde.KWin";
const VIRTUAL_DESKTOP_PATH: &str = "/VirtualDesktopManager";
const VIRTUAL_DESKTOP_IFACE: &str = "org.kde.KWin.VirtualDesktopManager";
const WINDOWS_RUNNER_PATH: &str = "/WindowsRunner";
const WINDOWS_RUNNER_IFACE: &str = "org.kde.krunner1";

/// One row of `Match("")` output: `a(sssuda{sv})`.
#[derive(Debug, Type, Deserialize)]
#[zvariant(signature = "(sssuda{sv})")]
struct KWinMatch {
    id: String,
    title: String,
    icon: String,
    _relevance: u32,
    _score: f64,
    _properties: HashMap<String, OwnedValue>,
}

fn virtual_desktop_proxy(session: &Connection) -> OziroResult<zbus::blocking::Proxy<'_>> {
    zbus::blocking::Proxy::new(
        session,
        KWIN_DESTINATION,
        VIRTUAL_DESKTOP_PATH,
        VIRTUAL_DESKTOP_IFACE,
    )
    .map_err(|error| {
        OziroError::compositor_unavailable(format!("KWin VirtualDesktopManager: {error}"))
    })
}

fn windows_runner_proxy(session: &Connection) -> OziroResult<zbus::blocking::Proxy<'_>> {
    zbus::blocking::Proxy::new(session, KWIN_DESTINATION, WINDOWS_RUNNER_PATH, WINDOWS_RUNNER_IFACE)
        .map_err(|error| OziroError::compositor_unavailable(format!("KWin WindowsRunner: {error}")))
}

fn workspaces_via(session: &Connection) -> OziroResult<WorkspacesResult> {
    let proxy = virtual_desktop_proxy(session)?;

    // `desktops` is `a(iss)`; tuples convert directly from zvariant values and
    // avoid a second serde hop.
    let desktops: Vec<(u32, String, String)> = proxy
        .get_property("desktops")
        .map_err(|error| OziroError::compositor_unavailable(format!("KWin desktops: {error}")))?;

    let current: String = proxy
        .get_property("current")
        .map_err(|error| OziroError::compositor_unavailable(format!("KWin current: {error}")))?;

    let workspaces = desktops
        .into_iter()
        .map(|(position, id, name)| Workspace {
            active: id == current,
            name: if name.is_empty() { id.clone() } else { name },
            id,
            index: position,
        })
        .collect::<Vec<_>>();

    let active_id =
        workspaces.iter().find(|workspace| workspace.active).map(|workspace| workspace.id.clone());

    Ok(WorkspacesResult {
        compositor: Some("kwin".to_owned()),
        supported: true,
        unavailable_reason: None,
        workspaces,
        active_id,
    })
}

fn windows_via(session: &Connection) -> OziroResult<WindowsResult> {
    let proxy = windows_runner_proxy(session)?;

    let reply = proxy
        .call_method("Match", &"")
        .map_err(|error| OziroError::compositor_unavailable(format!("KWin Match: {error}")))?;

    let matches: Vec<KWinMatch> = reply.body().deserialize().map_err(|error| {
        OziroError::compositor_unavailable(format!("KWin Match parse: {error}"))
    })?;

    let windows = matches
        .into_iter()
        .filter(|row| !row.id.is_empty() && !row.title.trim().is_empty())
        .map(|row| {
            let icon_token = if row.icon.is_empty() { None } else { icon_for_name(&row.icon) };

            WindowInfo {
                id: row.id,
                title: row.title,
                app_id: if row.icon.is_empty() { None } else { Some(row.icon.clone()) },
                workspace_id: None,
                active: false,
                icon_token,
            }
        })
        .collect::<Vec<_>>();

    Ok(WindowsResult {
        compositor: Some("kwin".to_owned()),
        supported: true,
        unavailable_reason: None,
        windows,
        active_id: None,
    })
}

#[derive(Clone)]
pub struct KWinAdapter {
    session: Arc<Connection>,
}

impl KWinAdapter {
    /// Detects a KWin session by probing the VirtualDesktopManager proxy.
    pub fn detect() -> Option<Self> {
        let session = Connection::session().ok()?;
        let adapter = Self { session: Arc::new(session) };

        let available = virtual_desktop_proxy(&adapter.session).is_ok();
        available.then_some(adapter)
    }

    pub fn workspaces(&self) -> OziroResult<WorkspacesResult> {
        workspaces_via(&self.session)
    }

    pub fn windows(&self) -> OziroResult<WindowsResult> {
        windows_via(&self.session)
    }
}

impl crate::compositor::Compositor for KWinAdapter {
    fn id(&self) -> &'static str {
        "kwin"
    }

    fn workspaces(&self) -> OziroResult<WorkspacesResult> {
        KWinAdapter::workspaces(self)
    }

    fn activate_workspace(&self, id: &str) -> OziroResult<()> {
        // The id must come from the desktops list itself.
        let valid = !id.is_empty()
            && id.len() <= 100
            && id.chars().all(|c| c.is_ascii_alphanumeric() || matches!(c, '-' | '_'));

        if !valid {
            return Err(OziroError::invalid_params("workspace id is not valid"));
        }

        let proxy = virtual_desktop_proxy(&self.session)?;
        proxy
            .set_property("current", id.to_owned())
            .map_err(|error| OziroError::service_failed(format!("KWin switch failed: {error}")))
    }

    fn windows(&self) -> OziroResult<WindowsResult> {
        KWinAdapter::windows(self)
    }

    fn activate_window(&self, id: &str) -> OziroResult<()> {
        let valid = !id.is_empty()
            && id.len() <= 255
            && id.chars().all(|c| c.is_ascii_alphanumeric() || matches!(c, '-' | '_'));

        if !valid {
            return Err(OziroError::invalid_params("window id is not valid"));
        }

        let proxy = windows_runner_proxy(&self.session)?;
        proxy
            .call_method("Run", &(id.to_owned(), "".to_owned()))
            .map_err(|error| OziroError::service_failed(format!("KWin focus failed: {error}")))?;
        Ok(())
    }

    /// Watches VirtualDesktopManager signals and forwards fresh workspace
    /// state. KWin offers no window change signals on this interface; window
    /// state refreshes are request-driven instead.
    fn spawn_monitor(&self, sender: EventSender) -> std::io::Result<std::thread::JoinHandle<()>> {
        let session = self.session.clone();

        std::thread::Builder::new().name("oziro-kwin-monitor".to_owned()).spawn(move || {
            let Ok(proxy) = virtual_desktop_proxy(&session) else {
                return;
            };

            let Ok(signals) = proxy.receive_all_signals() else {
                return;
            };

            for message in signals {
                let header = message.header();
                let from_manager = header
                    .interface()
                    .map(|name| name.as_str() == VIRTUAL_DESKTOP_IFACE)
                    .unwrap_or(false);

                let relevant = from_manager
                    && header
                        .member()
                        .map(|name| {
                            matches!(
                                name.as_str(),
                                "currentChanged"
                                    | "desktopCreated"
                                    | "desktopRemoved"
                                    | "desktopDataChanged"
                                    | "countChanged"
                            )
                        })
                        .unwrap_or(false);

                if !relevant {
                    continue;
                }

                match workspaces_via(&session) {
                    Ok(result) => sender(OziroEvent::Workspaces(result)),
                    Err(error) => {
                        eprintln!("[OZIRO KWIN] workspace refresh failed: {error}");
                    }
                }
            }
        })
    }
}
