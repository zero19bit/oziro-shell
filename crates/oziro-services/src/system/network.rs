//! Network state through NetworkManager's D-Bus API.
//!
//! Only properties NetworkManager exposes are read; Wi-Fi and networking
//! toggles use the documented read-write properties. Loopback and unknown
//! connection types are ignored when picking the active connection.

use crate::error::{OziroError, OziroResult};
use oziro_protocol::{Connectivity, NetworkState, NetworkType};
use zbus::blocking::{Connection, Proxy};
use zbus::zvariant::OwnedObjectPath;

const NM_DESTINATION: &str = "org.freedesktop.NetworkManager";
const NM_PATH: &str = "/org/freedesktop/NetworkManager";
const NM_INTERFACE: &str = "org.freedesktop.NetworkManager";
const ACTIVE_INTERFACE: &str = "org.freedesktop.NetworkManager.Connection.Active";

fn unavailable(reason: impl Into<String>) -> NetworkState {
    NetworkState {
        available: false,
        unavailable_reason: Some(reason.into()),
        networking_enabled: None,
        wifi_enabled: None,
        connectivity: Connectivity::Unknown,
        active_type: None,
        active_name: None,
    }
}

fn map_connectivity(raw: u32) -> Connectivity {
    match raw {
        1 => Connectivity::None,
        2 => Connectivity::Portal,
        3 => Connectivity::Limited,
        4 => Connectivity::Full,
        _ => Connectivity::Unknown,
    }
}

fn map_active_type(kind: &str) -> Option<NetworkType> {
    match kind {
        "802-11-wireless" => Some(NetworkType::Wifi),
        "802-3-ethernet" => Some(NetworkType::Ethernet),
        "vpn" | "wireguard" | "tun" => Some(NetworkType::Vpn),
        _ => None,
    }
}

pub struct NetworkService {
    connection: Option<Connection>,
}

impl NetworkService {
    pub fn new() -> Self {
        Self { connection: Connection::system().ok() }
    }

    fn proxy(&self) -> OziroResult<Proxy<'_>> {
        let connection = self
            .connection
            .as_ref()
            .ok_or_else(|| OziroError::service_unavailable("System bus unavailable"))?;

        Proxy::new(connection, NM_DESTINATION, NM_PATH, NM_INTERFACE)
            .map_err(|error| OziroError::service_unavailable(format!("NetworkManager: {error}")))
    }

    fn active_connection(&self) -> Option<(NetworkType, String)> {
        let connection = self.connection.as_ref()?;
        let proxy = self.proxy().ok()?;
        let paths: Vec<OwnedObjectPath> = proxy.get_property("ActiveConnections").ok()?;

        let mut fallback = None;

        for path in paths {
            let Ok(active) =
                Proxy::new(connection, NM_DESTINATION, path.as_str(), ACTIVE_INTERFACE)
            else {
                continue;
            };

            let id = active.get_property::<String>("Id").unwrap_or_default();
            let kind = active.get_property::<String>("Type").unwrap_or_default();

            if kind == "loopback" || id.is_empty() {
                continue;
            }

            match map_active_type(&kind) {
                Some(network_type) => return Some((network_type, id)),
                None if fallback.is_none() => fallback = Some((NetworkType::Ethernet, id.clone())),
                None => {}
            }
        }

        fallback
    }

    pub fn snapshot(&self) -> NetworkState {
        let proxy = match self.proxy() {
            Ok(proxy) => proxy,
            Err(error) => return unavailable(error.message),
        };

        let networking_enabled = match proxy.get_property::<bool>("NetworkingEnabled") {
            Ok(value) => value,
            Err(error) => {
                return unavailable(format!("NetworkManager is not responding: {error}"));
            }
        };

        let wifi_enabled = proxy.get_property::<bool>("WirelessEnabled").ok();
        let connectivity = proxy
            .get_property::<u32>("Connectivity")
            .map(map_connectivity)
            .unwrap_or(Connectivity::Unknown);
        let active = self.active_connection();

        NetworkState {
            available: true,
            unavailable_reason: None,
            networking_enabled: Some(networking_enabled),
            wifi_enabled,
            connectivity,
            active_type: active.as_ref().map(|(kind, _)| *kind),
            active_name: active.map(|(_, name)| name),
        }
    }

    pub fn set_wifi_enabled(&self, enabled: bool) -> OziroResult<NetworkState> {
        let proxy = self.proxy()?;
        proxy
            .set_property("WirelessEnabled", enabled)
            .map_err(|error| OziroError::service_failed(format!("Wi-Fi toggle failed: {error}")))?;

        Ok(self.snapshot())
    }

    pub fn set_networking_enabled(&self, enabled: bool) -> OziroResult<NetworkState> {
        let proxy = self.proxy()?;
        proxy.set_property("NetworkingEnabled", enabled).map_err(|error| {
            OziroError::service_failed(format!("Networking toggle failed: {error}"))
        })?;

        Ok(self.snapshot())
    }
}

impl Default for NetworkService {
    fn default() -> Self {
        Self::new()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn connectivity_values_match_networkmanager() {
        assert_eq!(map_connectivity(0), Connectivity::Unknown);
        assert_eq!(map_connectivity(1), Connectivity::None);
        assert_eq!(map_connectivity(2), Connectivity::Portal);
        assert_eq!(map_connectivity(3), Connectivity::Limited);
        assert_eq!(map_connectivity(4), Connectivity::Full);
        assert_eq!(map_connectivity(99), Connectivity::Unknown);
    }

    #[test]
    fn connection_types_are_mapped_conservatively() {
        assert_eq!(map_active_type("802-11-wireless"), Some(NetworkType::Wifi));
        assert_eq!(map_active_type("802-3-ethernet"), Some(NetworkType::Ethernet));
        assert_eq!(map_active_type("wireguard"), Some(NetworkType::Vpn));
        assert_eq!(map_active_type("loopback"), None);
        assert_eq!(map_active_type("bridge"), None);
    }

    #[test]
    fn unavailable_state_is_explicit() {
        let state = unavailable("no bus");
        assert!(!state.available);
        assert_eq!(state.networking_enabled, None);
        assert_eq!(state.connectivity, Connectivity::Unknown);
    }
}
