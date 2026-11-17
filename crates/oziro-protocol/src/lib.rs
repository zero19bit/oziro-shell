//! Shared, transport-independent types for communication between Oziro UI and Rust.
//!
//! These types mirror `frontend/packages/protocol/src/index.ts`. The JSON shapes
//! must stay identical on both sides; roundtrip tests enforce the envelope shape.

use serde::{Deserialize, Serialize};

pub const PROTOCOL_VERSION: u16 = 1;

/* ------------------------------------------------------------------ */
/* Runtime                                                            */
/* ------------------------------------------------------------------ */

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
#[serde(tag = "state", rename_all = "kebab-case")]
pub enum IntegrationState {
    NotConnected { reason: String },
    Connected { adapter: String },
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct RuntimeInfo {
    pub protocol_version: u16,
    pub app_name: String,
    pub app_version: String,
    pub integration: IntegrationState,
}

/* ------------------------------------------------------------------ */
/* Envelopes                                                          */
/* ------------------------------------------------------------------ */

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct RequestEnvelope {
    pub protocol_version: u16,
    pub request_id: String,
    pub method: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub params: Option<serde_json::Value>,
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct ErrorBody {
    pub code: String,
    pub message: String,
    pub retryable: bool,
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct SuccessEnvelope {
    pub protocol_version: u16,
    pub request_id: String,
    pub ok: bool,
    pub result: serde_json::Value,
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct FailureEnvelope {
    pub protocol_version: u16,
    pub request_id: String,
    pub ok: bool,
    pub error: ErrorBody,
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct EventEnvelope {
    pub protocol_version: u16,
    pub event: String,
    pub payload: serde_json::Value,
}

/* ------------------------------------------------------------------ */
/* Domain types                                                       */
/* ------------------------------------------------------------------ */

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct Workspace {
    pub id: String,
    pub name: String,
    pub index: u32,
    pub active: bool,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct WindowInfo {
    pub id: String,
    pub title: String,
    #[serde(rename = "appId")]
    pub app_id: Option<String>,
    #[serde(rename = "workspaceId")]
    pub workspace_id: Option<String>,
    pub active: bool,
    #[serde(rename = "iconToken")]
    pub icon_token: Option<String>,
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct WorkspacesResult {
    pub compositor: Option<String>,
    pub supported: bool,
    #[serde(rename = "unavailableReason")]
    pub unavailable_reason: Option<String>,
    pub workspaces: Vec<Workspace>,
    #[serde(rename = "activeId")]
    pub active_id: Option<String>,
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct WindowsResult {
    pub compositor: Option<String>,
    pub supported: bool,
    #[serde(rename = "unavailableReason")]
    pub unavailable_reason: Option<String>,
    pub windows: Vec<WindowInfo>,
    #[serde(rename = "activeId")]
    pub active_id: Option<String>,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct AppEntry {
    #[serde(rename = "desktopId")]
    pub desktop_id: String,
    pub name: String,
    #[serde(rename = "genericName")]
    pub generic_name: Option<String>,
    pub comment: Option<String>,
    pub categories: Vec<String>,
    #[serde(rename = "iconToken")]
    pub icon_token: Option<String>,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct AppsResult {
    pub apps: Vec<AppEntry>,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct FavoritesResult {
    pub favorites: Vec<String>,
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct AudioState {
    pub available: bool,
    #[serde(rename = "unavailableReason")]
    pub unavailable_reason: Option<String>,
    pub volume: Option<f64>,
    pub muted: Option<bool>,
    #[serde(rename = "sinkName")]
    pub sink_name: Option<String>,
    #[serde(rename = "sinkDescription")]
    pub sink_description: Option<String>,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum NetworkType {
    Ethernet,
    Wifi,
    Vpn,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct NetworkState {
    pub available: bool,
    #[serde(rename = "unavailableReason")]
    pub unavailable_reason: Option<String>,
    #[serde(rename = "networkingEnabled")]
    pub networking_enabled: Option<bool>,
    #[serde(rename = "wifiEnabled")]
    pub wifi_enabled: Option<bool>,
    pub connectivity: Connectivity,
    #[serde(rename = "activeType")]
    pub active_type: Option<NetworkType>,
    #[serde(rename = "activeName")]
    pub active_name: Option<String>,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum Connectivity {
    None,
    Portal,
    Limited,
    Full,
    Unknown,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct BluetoothState {
    pub available: bool,
    #[serde(rename = "unavailableReason")]
    pub unavailable_reason: Option<String>,
    pub powered: Option<bool>,
    #[serde(rename = "connectedDevices")]
    pub connected_devices: Option<u32>,
    #[serde(rename = "adapterName")]
    pub adapter_name: Option<String>,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "kebab-case")]
pub enum BatteryStateKind {
    Charging,
    Discharging,
    FullyCharged,
    Unknown,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum BatteryWarningLevel {
    None,
    Low,
    Critical,
    Unknown,
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct BatteryState {
    pub available: bool,
    #[serde(rename = "unavailableReason")]
    pub unavailable_reason: Option<String>,
    pub percent: Option<f64>,
    pub state: BatteryStateKind,
    #[serde(rename = "timeToEmptySeconds")]
    pub time_to_empty_seconds: Option<u64>,
    #[serde(rename = "timeToFullSeconds")]
    pub time_to_full_seconds: Option<u64>,
    #[serde(rename = "warningLevel")]
    pub warning_level: BatteryWarningLevel,
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct BrightnessState {
    pub available: bool,
    #[serde(rename = "unavailableReason")]
    pub unavailable_reason: Option<String>,
    pub percent: Option<f64>,
    pub device: Option<String>,
    #[serde(rename = "supportsSet")]
    pub supports_set: bool,
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct PowerState {
    #[serde(rename = "uptimeSeconds")]
    pub uptime_seconds: u64,
    #[serde(rename = "sessionDesktop")]
    pub session_desktop: Option<String>,
    pub battery: Option<BatteryState>,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum ThemeMode {
    Dark,
    Light,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum PanelAlignment {
    Left,
    Center,
    Right,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum DockPosition {
    Bottom,
    Left,
    Right,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct Settings {
    pub theme: ThemeMode,
    #[serde(rename = "liquidGlass")]
    pub liquid_glass: bool,
    #[serde(rename = "blurIntensity")]
    pub blur_intensity: u32,
    #[serde(rename = "panelHeight")]
    pub panel_height: u32,
    #[serde(rename = "panelAlignment")]
    pub panel_alignment: PanelAlignment,
    #[serde(rename = "dockSize")]
    pub dock_size: u32,
    #[serde(rename = "dockPosition")]
    pub dock_position: DockPosition,
    #[serde(rename = "reducedMotion")]
    pub reduced_motion: bool,
    pub animations: bool,
    pub favorites: Vec<String>,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum NotificationDaemonMode {
    External,
    Oziro,
    None,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct NotificationStatus {
    pub daemon: NotificationDaemonMode,
    #[serde(rename = "daemonOwner")]
    pub daemon_owner: Option<String>,
    #[serde(rename = "canReceive")]
    pub can_receive: bool,
    #[serde(rename = "canDismiss")]
    pub can_dismiss: bool,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum NotificationUrgency {
    Low,
    Normal,
    Critical,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct StoredNotification {
    pub id: String,
    #[serde(rename = "appName")]
    pub app_name: String,
    #[serde(rename = "appIcon")]
    pub app_icon: Option<String>,
    pub summary: String,
    pub body: String,
    #[serde(rename = "timestampMs")]
    pub timestamp_ms: u64,
    pub urgency: NotificationUrgency,
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct NotificationsResult {
    pub status: NotificationStatus,
    pub notifications: Vec<StoredNotification>,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum PopupSurface {
    Launcher,
    Control,
    Notifications,
    Overview,
    Settings,
}

impl PopupSurface {
    pub fn as_str(self) -> &'static str {
        match self {
            Self::Launcher => "launcher",
            Self::Control => "control",
            Self::Notifications => "notifications",
            Self::Overview => "overview",
            Self::Settings => "settings",
        }
    }
}

/* ------------------------------------------------------------------ */
/* Defaults                                                           */
/* ------------------------------------------------------------------ */

/// Default settings mirrored by the frontend preview adapter. Both sides must
/// agree; protocol tests keep them in sync.
pub fn default_settings() -> Settings {
    Settings {
        theme: ThemeMode::Dark,
        liquid_glass: true,
        blur_intensity: 24,
        panel_height: 54,
        panel_alignment: PanelAlignment::Center,
        dock_size: 56,
        dock_position: DockPosition::Bottom,
        reduced_motion: false,
        animations: true,
        favorites: Vec::new(),
    }
}

/* ------------------------------------------------------------------ */
/* Errors                                                             */
/* ------------------------------------------------------------------ */

/// Stable machine-readable error codes shared with the frontend.
pub mod error_codes {
    pub const UNSUPPORTED_PROTOCOL: &str = "UNSUPPORTED_PROTOCOL";
    pub const UNKNOWN_METHOD: &str = "UNKNOWN_METHOD";
    pub const INVALID_PARAMS: &str = "INVALID_PARAMS";
    pub const COMPOSITOR_UNAVAILABLE: &str = "COMPOSITOR_UNAVAILABLE";
    pub const SERVICE_UNAVAILABLE: &str = "SERVICE_UNAVAILABLE";
    pub const SERVICE_FAILED: &str = "SERVICE_FAILED";
    pub const LAUNCH_FAILED: &str = "LAUNCH_FAILED";
    pub const NOTIFICATION_UNAVAILABLE: &str = "NOTIFICATION_UNAVAILABLE";
    pub const SETTINGS_IO_FAILED: &str = "SETTINGS_IO_FAILED";
    pub const INTERNAL: &str = "INTERNAL";
}

#[cfg(test)]
mod tests {
    use super::*;
    use error_codes as codes;

    fn envelope_json() -> &'static str {
        r#"{"protocolVersion":1,"requestId":"req-1","method":"apps.search","params":{"query":"files"}}"#
    }

    #[test]
    fn request_envelope_roundtrips() {
        let envelope: RequestEnvelope = serde_json::from_str(envelope_json()).expect("parse");

        assert_eq!(envelope.protocol_version, 1);
        assert_eq!(envelope.request_id, "req-1");
        assert_eq!(envelope.method, "apps.search");

        let params = envelope.params.as_ref().expect("params present");
        assert_eq!(params["query"], "files");

        let roundtrip: RequestEnvelope =
            serde_json::from_str(&serde_json::to_string(&envelope).expect("serialize"))
                .expect("re-parse");
        assert_eq!(envelope, roundtrip);
    }

    #[test]
    fn integration_state_uses_kebab_case_tags() {
        let connected = IntegrationState::Connected { adapter: "kwin".to_owned() };
        let json = serde_json::to_string(&connected).expect("serialize");
        assert_eq!(json, r#"{"state":"connected","adapter":"kwin"}"#);

        let parsed: IntegrationState = serde_json::from_str(&json).expect("parse");
        assert_eq!(parsed, connected);
    }

    #[test]
    fn audio_state_matches_frontend_field_names() {
        let state = AudioState {
            available: true,
            unavailable_reason: None,
            volume: Some(42.0),
            muted: Some(false),
            sink_name: Some("alsa_output.pci-0000_00_1f_3.analog-stereo".to_owned()),
            sink_description: Some("Built-in Audio".to_owned()),
        };

        let json = serde_json::to_value(&state).expect("serialize");
        assert!(json.get("sinkName").is_some());
        assert!(json.get("sinkName").and_then(serde_json::Value::as_f64).is_none());
        assert_eq!(json["sinkDescription"], "Built-in Audio");
        assert_eq!(json["volume"], 42.0);
    }

    #[test]
    fn popup_surface_serializes_lowercase() {
        assert_eq!(
            serde_json::to_value(PopupSurface::Launcher).expect("serialize"),
            serde_json::Value::String("launcher".to_owned())
        );
    }

    #[test]
    fn settings_roundtrips_with_frontend_names() {
        let settings = default_settings();
        let json = serde_json::to_value(&settings).expect("serialize");

        assert_eq!(json["liquidGlass"], true);
        assert_eq!(json["blurIntensity"], 24);
        assert_eq!(json["panelHeight"], 54);
        assert_eq!(json["panelAlignment"], "center");
        assert_eq!(json["dockSize"], 56);
        assert_eq!(json["dockPosition"], "bottom");
        assert_eq!(json["reducedMotion"], false);
        assert_eq!(json["theme"], "dark");

        let parsed: Settings = serde_json::from_value(json).expect("re-parse");
        assert_eq!(parsed, settings);
    }

    #[test]
    fn error_codes_are_stable_strings() {
        assert_eq!(codes::INVALID_PARAMS, "INVALID_PARAMS");
        assert_eq!(codes::COMPOSITOR_UNAVAILABLE, "COMPOSITOR_UNAVAILABLE");
    }
}
