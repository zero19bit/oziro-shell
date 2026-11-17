//! Hyprland compositor adapter over its native Unix sockets.
//!
//! - `$XDG_RUNTIME_DIR/hypr/$SIG/.socket.sock` — request/reply commands.
//! - `$XDG_RUNTIME_DIR/hypr/$SIG/.socket2.sock` — event stream.
//!
//! All parsing is a pure function of the wire format so it is unit-testable
//! without a running compositor. No operations are invented: everything here
//! is the documented Hyprland IPC surface.

use crate::error::{OziroError, OziroResult};
use oziro_protocol::{WindowInfo, WindowsResult, Workspace, WorkspacesResult};
use serde::Deserialize;
use std::io::{BufRead, BufReader, Read, Write};
use std::os::unix::net::UnixStream;
use std::path::PathBuf;

pub const EVENT_SOCKET: &str = ".socket2.sock";
pub const COMMAND_SOCKET: &str = ".socket.sock";

/// Returns the Hyprland IPC directory when a Hyprland session is detected.
pub fn detect_socket_dir() -> Option<PathBuf> {
    let signature = std::env::var("HYPRLAND_INSTANCE_SIGNATURE").ok()?;
    let runtime = std::env::var("XDG_RUNTIME_DIR").ok()?;

    let dir = PathBuf::from(runtime).join("hypr").join(signature);
    let command_socket = dir.join(COMMAND_SOCKET);

    if command_socket.exists() { Some(dir) } else { None }
}

#[derive(Debug, Clone, PartialEq)]
pub enum HyprEvent {
    WorkspaceFocused(String),
    ActiveWindowChanged { address: Option<String> },
    WindowOpened,
    WindowClosed(String),
    WindowMoved(String),
    WorkspaceRemoved,
    Ignore(String),
}

/// Parses one event line from the event socket, e.g. `workspace>>3`.
pub fn parse_event(line: &str) -> HyprEvent {
    let (event, rest) = match line.split_once(">>") {
        Some(parts) => parts,
        None => return HyprEvent::Ignore(line.to_owned()),
    };

    match event {
        "workspace" => HyprEvent::WorkspaceFocused(rest.to_owned()),
        "workspacev2" => {
            let id = rest.split(',').next().unwrap_or(rest);
            HyprEvent::WorkspaceFocused(id.to_owned())
        }
        "activewindowv2" => {
            let address = if rest.is_empty() { None } else { Some(rest.to_owned()) };
            HyprEvent::ActiveWindowChanged { address }
        }
        "activewindow" => HyprEvent::ActiveWindowChanged { address: None },
        "openwindow" => HyprEvent::WindowOpened,
        "closewindow" => HyprEvent::WindowClosed(rest.to_owned()),
        "movewindowv2" | "movewindow" => {
            let address = rest.split(',').next().unwrap_or(rest);
            HyprEvent::WindowMoved(address.to_owned())
        }
        "destroyworkspace" | "createworkspace" => HyprEvent::WorkspaceRemoved,
        _ => HyprEvent::Ignore(line.to_owned()),
    }
}

/* ------------------------------------------------------------------ */
/* JSON payloads                                                      */
/* ------------------------------------------------------------------ */

#[derive(Debug, Deserialize)]
struct HyprWorkspace {
    id: i64,
    #[serde(default)]
    name: String,
}

#[derive(Debug, Deserialize)]
struct HyprClient {
    address: String,
    #[serde(default)]
    mapped: bool,
    #[serde(default)]
    hidden: bool,
    #[serde(default)]
    class: String,
    #[serde(default)]
    title: String,
    #[serde(default)]
    workspace: Option<HyprWorkspaceRef>,
    #[serde(rename = "focusHistoryID", default)]
    focus_history_id: Option<i64>,
}

#[derive(Debug, Deserialize)]
struct HyprWorkspaceRef {
    #[serde(default)]
    id: i64,
}

#[derive(Debug, Deserialize)]
struct HyprActiveWindow {
    #[serde(default)]
    address: String,
}

fn json_from_bytes(bytes: &[u8]) -> OziroResult<String> {
    String::from_utf8(bytes.to_vec())
        .map_err(|error| OziroError::compositor_unavailable(format!("bad Hyprland reply: {error}")))
}

/// Normalizes Hyprland workspaces into protocol workspaces.
pub fn parse_workspaces(json: &str, focused: Option<&str>) -> OziroResult<WorkspacesResult> {
    let raw: Vec<HyprWorkspace> = serde_json::from_str(json)
        .map_err(|error| OziroError::compositor_unavailable(format!("workspace parse: {error}")))?;

    let mut workspaces: Vec<Workspace> = raw
        .into_iter()
        .filter(|workspace| workspace.id > 0)
        .map(|workspace| {
            let id = workspace.id.to_string();
            let active = focused == Some(id.as_str());
            Workspace {
                id: id.clone(),
                name: if workspace.name.is_empty() { id.clone() } else { workspace.name.clone() },
                index: workspace.id as u32,
                active,
            }
        })
        .collect();

    workspaces.sort_by_key(|workspace| workspace.index);

    let active_id =
        workspaces.iter().find(|workspace| workspace.active).map(|workspace| workspace.id.clone());

    Ok(WorkspacesResult {
        compositor: Some("hyprland".to_owned()),
        supported: true,
        unavailable_reason: None,
        workspaces,
        active_id,
    })
}

/// Normalizes `j/clients` into protocol windows.
pub fn parse_windows(json: &str, active_address: Option<&str>) -> OziroResult<WindowsResult> {
    let raw: Vec<HyprClient> = serde_json::from_str(json)
        .map_err(|error| OziroError::compositor_unavailable(format!("window parse: {error}")))?;

    let mut clients: Vec<HyprClient> = raw
        .into_iter()
        .filter(|client| client.mapped && !client.hidden)
        .filter(|client| client.workspace.as_ref().is_some_and(|space| space.id > 0))
        .collect();

    // Most recently focused window first for overview ordering.
    clients.sort_by_key(|client| client.focus_history_id.unwrap_or(i64::MAX));

    let windows: Vec<WindowInfo> = clients
        .into_iter()
        .map(|client| {
            let workspace = client.workspace.expect("filtered above");
            let active = active_address == Some(client.address.as_str());

            WindowInfo {
                id: client.address,
                title: client.title,
                app_id: if client.class.is_empty() { None } else { Some(client.class) },
                workspace_id: Some(workspace.id.to_string()),
                active,
                icon_token: None,
            }
        })
        .collect();

    let active_id = windows.iter().find(|window| window.active).map(|window| window.id.clone());

    Ok(WindowsResult {
        compositor: Some("hyprland".to_owned()),
        supported: true,
        unavailable_reason: None,
        windows,
        active_id,
    })
}

/* ------------------------------------------------------------------ */
/* Socket client                                                      */
/* ------------------------------------------------------------------ */

/// Workspace identifiers accepted by the adapter: plain numbers or named
/// workspaces made of safe characters. No whitespace, no shell metacharacters.
fn valid_workspace_id(id: &str) -> bool {
    !id.is_empty()
        && id.len() <= 64
        && id.chars().all(|c| c.is_ascii_alphanumeric() || matches!(c, '-' | '_'))
}

/// Window identifiers must be Hyprland addresses (`0x` + hex digits).
fn valid_window_address(id: &str) -> bool {
    id.len() > 2 && id.starts_with("0x") && id[2..].chars().all(|c| c.is_ascii_hexdigit())
}

#[derive(Debug)]
pub struct HyprlandAdapter {
    socket_dir: PathBuf,
}

impl HyprlandAdapter {
    pub fn detect() -> Option<Self> {
        detect_socket_dir().map(|socket_dir| Self { socket_dir })
    }

    pub fn new_for_tests(socket_dir: PathBuf) -> Self {
        Self { socket_dir }
    }

    fn command_socket(&self) -> PathBuf {
        self.socket_dir.join(COMMAND_SOCKET)
    }

    /// Sends a command and returns the raw reply bytes.
    fn request(&self, command: &str) -> OziroResult<Vec<u8>> {
        let mut stream = UnixStream::connect(self.command_socket()).map_err(|error| {
            OziroError::compositor_unavailable(format!("Hyprland connect: {error}"))
        })?;

        stream.write_all(command.as_bytes()).map_err(|error| {
            OziroError::compositor_unavailable(format!("Hyprland write: {error}"))
        })?;

        let mut reader = BufReader::new(stream);
        let mut buffer = Vec::new();
        reader.read_to_end(&mut buffer).map_err(|error| {
            OziroError::compositor_unavailable(format!("Hyprland read: {error}"))
        })?;

        Ok(buffer)
    }

    fn request_string(&self, command: &str) -> OziroResult<String> {
        json_from_bytes(&self.request(command)?)
    }

    /// Non-JSON commands return a single status byte; treat "ok" as success.
    fn dispatch(&self, command: &str) -> OziroResult<()> {
        let reply = self.request(command)?;

        match reply.first() {
            Some(b'o') | Some(b'\0') | None => Ok(()),
            Some(b'i') => {
                let message = String::from_utf8_lossy(&reply);
                Err(OziroError::service_failed(format!("Hyprland rejected {command}: {message}")))
            }
            Some(_) => Ok(()),
        }
    }

    pub fn workspaces(&self) -> OziroResult<WorkspacesResult> {
        let focused = self
            .request_string("j/activeworkspace")
            .ok()
            .and_then(|json| serde_json::from_str::<HyprWorkspace>(&json).ok())
            .map(|workspace| workspace.id.to_string());

        let json = self.request_string("j/workspaces")?;
        parse_workspaces(&json, focused.as_deref())
    }

    pub fn activate_workspace(&self, id: &str) -> OziroResult<()> {
        if !valid_workspace_id(id) {
            return Err(OziroError::invalid_params("workspace id is not valid"));
        }

        self.dispatch(&format!("dispatch workspace {id}"))
    }

    pub fn windows(&self) -> OziroResult<WindowsResult> {
        let active = self
            .request_string("j/activewindow")
            .ok()
            .and_then(|json| serde_json::from_str::<HyprActiveWindow>(&json).ok())
            .filter(|window| !window.address.is_empty())
            .map(|window| window.address);

        let json = self.request_string("j/clients")?;
        parse_windows(&json, active.as_deref())
    }

    pub fn activate_window(&self, id: &str) -> OziroResult<()> {
        if !valid_window_address(id) {
            return Err(OziroError::invalid_params("window id must be a Hyprland address"));
        }

        self.dispatch(&format!("dispatch focuswindow address:{id}"))
    }

    /// Blocks forever reading the event socket, forwarding parsed events.
    /// Runs on a dedicated thread; returns only on IO error.
    pub fn watch_events(&self, on_event: impl Fn(HyprEvent)) -> OziroResult<()> {
        let stream = UnixStream::connect(self.socket_dir.join(EVENT_SOCKET)).map_err(|error| {
            OziroError::compositor_unavailable(format!("Hyprland events: {error}"))
        })?;

        let reader = BufReader::new(stream);

        for line in reader.lines() {
            match line {
                Ok(line) => {
                    if !line.is_empty() {
                        on_event(parse_event(&line));
                    }
                }
                Err(_) => break,
            }
        }

        Ok(())
    }
}

impl crate::compositor::Compositor for HyprlandAdapter {
    fn id(&self) -> &'static str {
        "hyprland"
    }

    fn workspaces(&self) -> OziroResult<WorkspacesResult> {
        HyprlandAdapter::workspaces(self)
    }

    fn activate_workspace(&self, id: &str) -> OziroResult<()> {
        HyprlandAdapter::activate_workspace(self, id)
    }

    fn windows(&self) -> OziroResult<WindowsResult> {
        HyprlandAdapter::windows(self)
    }

    fn activate_window(&self, id: &str) -> OziroResult<()> {
        HyprlandAdapter::activate_window(self, id)
    }

    fn spawn_monitor(
        &self,
        sender: crate::EventSender,
    ) -> std::io::Result<std::thread::JoinHandle<()>> {
        let socket_dir = self.socket_dir.clone();

        std::thread::Builder::new().name("oziro-hyprland-monitor".to_owned()).spawn(move || {
            let adapter = HyprlandAdapter { socket_dir };

            let result = adapter.watch_events(|event| {
                let update = match event {
                    HyprEvent::WorkspaceFocused(_) | HyprEvent::WorkspaceRemoved => {
                        adapter.workspaces().ok().map(crate::OziroEvent::Workspaces)
                    }
                    HyprEvent::WindowOpened
                    | HyprEvent::WindowClosed(_)
                    | HyprEvent::WindowMoved(_)
                    | HyprEvent::ActiveWindowChanged { .. } => {
                        adapter.windows().ok().map(crate::OziroEvent::Windows)
                    }
                    HyprEvent::Ignore(_) => None,
                };

                if let Some(update) = update {
                    sender(update);
                }
            });

            if let Err(error) = result {
                eprintln!("[OZIRO HYPRLAND] event monitor stopped: {error}");
            }
        })
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn detects_no_hyprland_session_outside_hyprland() {
        // This KDE session does not export the Hyprland signature.
        if std::env::var("HYPRLAND_INSTANCE_SIGNATURE").is_err() {
            assert!(detect_socket_dir().is_none());
        }
    }

    #[test]
    fn parses_event_lines() {
        assert_eq!(parse_event("workspace>>2"), HyprEvent::WorkspaceFocused("2".to_owned()));

        assert_eq!(parse_event("workspacev2>>2,WS2"), HyprEvent::WorkspaceFocused("2".to_owned()));

        assert_eq!(
            parse_event("activewindowv2>>0x1234"),
            HyprEvent::ActiveWindowChanged { address: Some("0x1234".to_owned()) }
        );

        assert_eq!(
            parse_event("activewindowv2>>"),
            HyprEvent::ActiveWindowChanged { address: None }
        );

        assert_eq!(parse_event("openwindow>>0x1,2,konsole,konsole"), HyprEvent::WindowOpened);

        assert_eq!(parse_event("closewindow>>0x1"), HyprEvent::WindowClosed("0x1".to_owned()));

        assert_eq!(parse_event("movewindowv2>>0x1,3"), HyprEvent::WindowMoved("0x1".to_owned()));

        assert_eq!(parse_event("tick>>"), HyprEvent::Ignore("tick>>".to_owned()));

        assert_eq!(parse_event("garbage"), HyprEvent::Ignore("garbage".to_owned()));
    }

    #[test]
    fn parses_workspaces_json() {
        let json = r#"[
            {"id":2,"name":"2","monitorID":0,"hasfullscreen":false},
            {"id":1,"name":"1","monitorID":0,"hasfullscreen":false},
            {"id":-1,"name":"special","monitorID":0,"hasfullscreen":false}
        ]"#;

        let result = parse_workspaces(json, Some("1")).expect("parse");

        assert!(result.supported);
        assert_eq!(result.compositor.as_deref(), Some("hyprland"));
        assert_eq!(result.workspaces.len(), 2);
        assert_eq!(result.workspaces[0].id, "1");
        assert!(result.workspaces[0].active);
        assert_eq!(result.active_id.as_deref(), Some("1"));
    }

    #[test]
    fn parses_clients_json() {
        let json = r#"[
            {
                "address":"0x55aa",
                "mapped":true,
                "hidden":false,
                "class":"konsole",
                "title":"konsole — zsh",
                "workspace":{"id":2,"name":"2"},
                "focusHistoryID":0
            },
            {
                "address":"0x55bb",
                "mapped":false,
                "hidden":false,
                "class":"hidden-app",
                "title":"hidden",
                "workspace":{"id":2,"name":"2"}
            },
            {
                "address":"0x55cc",
                "mapped":true,
                "hidden":false,
                "class":"firefox",
                "title":"Firefox",
                "workspace":{"id":1,"name":"1"},
                "focusHistoryID":1
            }
        ]"#;

        let result = parse_windows(json, Some("0x55cc")).expect("parse");

        assert_eq!(result.windows.len(), 2);
        assert_eq!(result.windows[0].app_id.as_deref(), Some("konsole"));
        assert!(!result.windows[0].active);
        assert!(result.windows[1].active);
        assert_eq!(result.active_id.as_deref(), Some("0x55cc"));
        assert_eq!(result.windows[1].workspace_id.as_deref(), Some("1"));
    }

    #[test]
    fn rejects_malformed_json() {
        assert!(parse_workspaces("not json", None).is_err());
        assert!(parse_windows("[broken", None).is_err());
    }

    #[test]
    fn workspace_and_window_ids_are_validated() {
        assert!(valid_workspace_id("2"));
        assert!(valid_workspace_id("my-workspace_1"));
        assert!(!valid_workspace_id(""));
        assert!(!valid_workspace_id("2; rm -rf /"));
        assert!(!valid_workspace_id("name with space"));

        assert!(valid_window_address("0xABCDEF"));
        assert!(!valid_window_address("$(pwd)"));
        assert!(!valid_window_address("0xGG"));
        assert!(!valid_window_address("0x"));
    }

    #[test]
    fn invalid_ids_are_rejected_before_socket_io() {
        let adapter = HyprlandAdapter::new_for_tests(PathBuf::from("/tmp/oziro-test-hypr"));

        assert_eq!(adapter.activate_workspace("2; rm -rf /").unwrap_err().code, "INVALID_PARAMS");
        assert_eq!(adapter.activate_window("$(pwd)").unwrap_err().code, "INVALID_PARAMS");
        assert_eq!(adapter.activate_window("0xGG").unwrap_err().code, "INVALID_PARAMS");
    }
}
