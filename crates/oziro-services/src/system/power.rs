//! Power and battery state through UPower, with uptime and session metadata
//! read from standard Linux interfaces.

use crate::error::OziroError;
use oziro_protocol::{BatteryState, BatteryStateKind, BatteryWarningLevel, PowerState};
use zbus::blocking::{Connection, Proxy};

const UPOWER_DESTINATION: &str = "org.freedesktop.UPower";
const DISPLAY_DEVICE_PATH: &str = "/org/freedesktop/UPower/devices/DisplayDevice";
const DEVICE_INTERFACE: &str = "org.freedesktop.UPower.Device";

fn unavailable(reason: impl Into<String>) -> BatteryState {
    BatteryState {
        available: false,
        unavailable_reason: Some(reason.into()),
        percent: None,
        state: BatteryStateKind::Unknown,
        time_to_empty_seconds: None,
        time_to_full_seconds: None,
        warning_level: BatteryWarningLevel::Unknown,
    }
}

fn map_state(raw: u32) -> BatteryStateKind {
    match raw {
        1 => BatteryStateKind::Charging,
        2 => BatteryStateKind::Discharging,
        4 => BatteryStateKind::FullyCharged,
        _ => BatteryStateKind::Unknown,
    }
}

fn map_warning_level(raw: u32) -> BatteryWarningLevel {
    match raw {
        1 => BatteryWarningLevel::None,
        2 => BatteryWarningLevel::Low,
        3 => BatteryWarningLevel::Critical,
        _ => BatteryWarningLevel::Unknown,
    }
}

fn positive_seconds(value: i64) -> Option<u64> {
    u64::try_from(value).ok().filter(|seconds| *seconds > 0)
}

pub struct PowerService {
    connection: Option<Connection>,
}

impl PowerService {
    pub fn new() -> Self {
        Self { connection: Connection::system().ok() }
    }

    fn device_proxy(&self) -> Result<Proxy<'_>, OziroError> {
        let connection = self
            .connection
            .as_ref()
            .ok_or_else(|| OziroError::service_unavailable("System bus unavailable"))?;

        Proxy::new(connection, UPOWER_DESTINATION, DISPLAY_DEVICE_PATH, DEVICE_INTERFACE)
            .map_err(|error| OziroError::service_unavailable(format!("UPower: {error}")))
    }

    pub fn battery(&self) -> BatteryState {
        let proxy = match self.device_proxy() {
            Ok(proxy) => proxy,
            Err(error) => return unavailable(error.message),
        };

        let present = match proxy.get_property::<bool>("IsPresent") {
            Ok(present) => present,
            Err(error) => return unavailable(format!("UPower is not responding: {error}")),
        };

        if !present {
            return unavailable("No battery is present");
        }

        let percent = proxy
            .get_property::<f64>("Percentage")
            .ok()
            .filter(|value| (0.0..=100.0).contains(value));
        let state =
            proxy.get_property::<u32>("State").map(map_state).unwrap_or(BatteryStateKind::Unknown);
        let time_to_empty_seconds =
            proxy.get_property::<i64>("TimeToEmpty").ok().and_then(positive_seconds);
        let time_to_full_seconds =
            proxy.get_property::<i64>("TimeToFull").ok().and_then(positive_seconds);
        let warning_level = proxy
            .get_property::<u32>("WarningLevel")
            .map(map_warning_level)
            .unwrap_or(BatteryWarningLevel::Unknown);

        BatteryState {
            available: true,
            unavailable_reason: None,
            percent,
            state,
            time_to_empty_seconds,
            time_to_full_seconds,
            warning_level,
        }
    }

    pub fn power(&self) -> PowerState {
        PowerState {
            uptime_seconds: uptime_seconds().unwrap_or(0),
            session_desktop: std::env::var("XDG_CURRENT_DESKTOP")
                .ok()
                .filter(|value| !value.is_empty()),
            battery: Some(self.battery()),
        }
    }
}

impl Default for PowerService {
    fn default() -> Self {
        Self::new()
    }
}

fn uptime_seconds() -> Option<u64> {
    let contents = std::fs::read_to_string("/proc/uptime").ok()?;
    let seconds = contents.split_whitespace().next()?;
    let seconds = seconds.parse::<f64>().ok()?;

    if seconds.is_finite() && seconds >= 0.0 { Some(seconds as u64) } else { None }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn upower_state_values_are_mapped() {
        assert_eq!(map_state(1), BatteryStateKind::Charging);
        assert_eq!(map_state(2), BatteryStateKind::Discharging);
        assert_eq!(map_state(4), BatteryStateKind::FullyCharged);
        assert_eq!(map_state(0), BatteryStateKind::Unknown);
        assert_eq!(map_state(3), BatteryStateKind::Unknown);
    }

    #[test]
    fn warning_levels_are_mapped() {
        assert_eq!(map_warning_level(1), BatteryWarningLevel::None);
        assert_eq!(map_warning_level(2), BatteryWarningLevel::Low);
        assert_eq!(map_warning_level(3), BatteryWarningLevel::Critical);
        assert_eq!(map_warning_level(0), BatteryWarningLevel::Unknown);
    }

    #[test]
    fn zero_seconds_means_unknown() {
        assert_eq!(positive_seconds(0), None);
        assert_eq!(positive_seconds(-1), None);
        assert_eq!(positive_seconds(90), Some(90));
    }

    #[test]
    fn unavailable_state_is_explicit() {
        let state = unavailable("no upower");
        assert!(!state.available);
        assert_eq!(state.percent, None);
        assert_eq!(state.state, BatteryStateKind::Unknown);
    }
}
