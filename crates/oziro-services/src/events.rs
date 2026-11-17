//! Event plumbing shared by all services.

use oziro_protocol::{
    AudioState, BatteryState, BluetoothState, BrightnessState, NetworkState, NotificationsResult,
    Settings, WindowsResult, WorkspacesResult,
};
use std::sync::Arc;

/// Everything that can be broadcast to the UI, serialized by the host.
#[derive(Debug, Clone)]
pub enum OziroEvent {
    Workspaces(WorkspacesResult),
    Windows(WindowsResult),
    Audio(AudioState),
    Network(NetworkState),
    Bluetooth(BluetoothState),
    Battery(BatteryState),
    Brightness(BrightnessState),
    Settings(Settings),
    Notifications(NotificationsResult),
}

impl OziroEvent {
    pub fn name(&self) -> &'static str {
        match self {
            Self::Workspaces(_) => "compositor.workspaces",
            Self::Windows(_) => "compositor.windows",
            Self::Audio(_) => "system.audio",
            Self::Network(_) => "system.network",
            Self::Bluetooth(_) => "system.bluetooth",
            Self::Battery(_) => "system.battery",
            Self::Brightness(_) => "system.brightness",
            Self::Settings(_) => "settings.changed",
            Self::Notifications(_) => "notifications.changed",
        }
    }

    pub fn payload(&self) -> serde_json::Value {
        let serialized = match self {
            Self::Workspaces(value) => serde_json::to_value(value),
            Self::Windows(value) => serde_json::to_value(value),
            Self::Audio(value) => serde_json::to_value(value),
            Self::Network(value) => serde_json::to_value(value),
            Self::Bluetooth(value) => serde_json::to_value(value),
            Self::Battery(value) => serde_json::to_value(value),
            Self::Brightness(value) => serde_json::to_value(value),
            Self::Settings(value) => serde_json::to_value(value),
            Self::Notifications(value) => serde_json::to_value(value),
        };

        serialized.unwrap_or(serde_json::Value::Null)
    }
}

pub type EventSender = Arc<dyn Fn(OziroEvent) + Send + Sync>;

/// Simple fan-out hub used by the host.
#[derive(Default)]
pub struct EventHub {
    subscribers: Vec<EventSender>,
}

impl EventHub {
    pub fn subscribe(&mut self, sender: EventSender) {
        self.subscribers.push(sender);
    }

    pub fn emit(&self, event: OziroEvent) {
        for sender in &self.subscribers {
            sender(event.clone());
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use oziro_protocol::BatteryStateKind;

    #[test]
    fn event_names_match_the_contract() {
        let battery = BatteryState {
            available: true,
            unavailable_reason: None,
            percent: Some(80.0),
            state: BatteryStateKind::Discharging,
            time_to_empty_seconds: None,
            time_to_full_seconds: None,
            warning_level: oziro_protocol::BatteryWarningLevel::None,
        };

        assert_eq!(OziroEvent::Battery(battery).name(), "system.battery");
    }

    #[test]
    fn payload_serializes_with_frontend_names() {
        let battery = BatteryState {
            available: true,
            unavailable_reason: None,
            percent: Some(80.0),
            state: BatteryStateKind::Charging,
            time_to_empty_seconds: None,
            time_to_full_seconds: Some(60),
            warning_level: oziro_protocol::BatteryWarningLevel::Low,
        };

        let payload = OziroEvent::Battery(battery).payload();

        assert_eq!(payload["timeToFullSeconds"], 60);
        assert_eq!(payload["warningLevel"], "low");
        assert_eq!(payload["state"], "charging");
    }
}
