//! Bluetooth state through BlueZ's ObjectManager API.
//!
//! `GetManagedObjects` gives the adapter and device objects in one round trip;
//! only `Powered`, `Alias`/`Name`, and `Connected` are consumed.

use crate::error::{OziroError, OziroResult};
use oziro_protocol::BluetoothState;
use std::collections::HashMap;
use zbus::blocking::{Connection, Proxy};
use zbus::zvariant::{OwnedObjectPath, OwnedValue};

const BLUEZ_DESTINATION: &str = "org.bluez";
const BLUEZ_ROOT: &str = "/";
const OBJECT_MANAGER: &str = "org.freedesktop.DBus.ObjectManager";
const ADAPTER_INTERFACE: &str = "org.bluez.Adapter1";
const DEVICE_INTERFACE: &str = "org.bluez.Device1";

type ManagedObjects = HashMap<OwnedObjectPath, HashMap<String, HashMap<String, OwnedValue>>>;
type Properties = HashMap<String, OwnedValue>;

fn unavailable(reason: impl Into<String>) -> BluetoothState {
    BluetoothState {
        available: false,
        unavailable_reason: Some(reason.into()),
        powered: None,
        connected_devices: None,
        adapter_name: None,
    }
}

fn bool_property(properties: &Properties, key: &str) -> Option<bool> {
    properties.get(key).and_then(|value| bool::try_from(value).ok())
}

fn string_property(properties: &Properties, key: &str) -> Option<String> {
    properties
        .get(key)
        .and_then(|value| <&str>::try_from(value).ok())
        .map(str::to_owned)
        .filter(|value| !value.is_empty())
}

#[derive(Debug, PartialEq, Eq)]
struct AdapterSnapshot {
    path: String,
    powered: bool,
    name: Option<String>,
    connected_devices: u32,
}

fn summarize(objects: &ManagedObjects) -> Option<AdapterSnapshot> {
    let mut adapter = None;
    let mut connected_devices = 0u32;

    for (path, interfaces) in objects {
        if let Some(properties) = interfaces.get(ADAPTER_INTERFACE) {
            adapter = Some(AdapterSnapshot {
                path: path.as_str().to_owned(),
                powered: bool_property(properties, "Powered").unwrap_or(false),
                name: string_property(properties, "Alias")
                    .or_else(|| string_property(properties, "Name")),
                connected_devices: 0,
            });
        }

        if let Some(properties) = interfaces.get(DEVICE_INTERFACE) {
            if bool_property(properties, "Connected") == Some(true) {
                connected_devices += 1;
            }
        }
    }

    adapter.map(|mut adapter| {
        adapter.connected_devices = connected_devices;
        adapter
    })
}

pub struct BluetoothService {
    connection: Option<Connection>,
}

impl BluetoothService {
    pub fn new() -> Self {
        Self { connection: Connection::system().ok() }
    }

    fn managed_objects(&self) -> OziroResult<ManagedObjects> {
        let connection = self
            .connection
            .as_ref()
            .ok_or_else(|| OziroError::service_unavailable("System bus unavailable"))?;

        let reply = connection
            .call_method(
                Some(BLUEZ_DESTINATION),
                BLUEZ_ROOT,
                Some(OBJECT_MANAGER),
                "GetManagedObjects",
                &(),
            )
            .map_err(|error| OziroError::service_unavailable(format!("BlueZ: {error}")))?;

        reply
            .body()
            .deserialize()
            .map_err(|error| OziroError::service_unavailable(format!("BlueZ reply: {error}")))
    }

    fn adapter(&self) -> OziroResult<AdapterSnapshot> {
        let objects = self.managed_objects()?;

        summarize(&objects)
            .ok_or_else(|| OziroError::service_unavailable("No Bluetooth adapter is present"))
    }

    pub fn snapshot(&self) -> BluetoothState {
        match self.adapter() {
            Ok(adapter) => BluetoothState {
                available: true,
                unavailable_reason: None,
                powered: Some(adapter.powered),
                connected_devices: Some(adapter.connected_devices),
                adapter_name: adapter.name,
            },
            Err(error) => unavailable(error.message),
        }
    }

    pub fn set_powered(&self, powered: bool) -> OziroResult<BluetoothState> {
        let adapter = self.adapter()?;
        let connection = self
            .connection
            .as_ref()
            .ok_or_else(|| OziroError::service_unavailable("System bus unavailable"))?;

        let proxy =
            Proxy::new(connection, BLUEZ_DESTINATION, adapter.path.as_str(), ADAPTER_INTERFACE)
                .map_err(|error| OziroError::service_failed(format!("BlueZ adapter: {error}")))?;

        proxy.set_property("Powered", powered).map_err(|error| {
            OziroError::service_failed(format!("Bluetooth toggle failed: {error}"))
        })?;

        Ok(self.snapshot())
    }
}

impl Default for BluetoothService {
    fn default() -> Self {
        Self::new()
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use zbus::zvariant::Value;

    fn properties(items: &[(&str, Value<'static>)]) -> Properties {
        items
            .iter()
            .map(|(key, value)| {
                ((*key).to_owned(), OwnedValue::try_from(value.try_clone().unwrap()).unwrap())
            })
            .collect()
    }

    #[test]
    fn missing_adapter_is_none() {
        let objects = ManagedObjects::new();
        assert_eq!(summarize(&objects), None);
    }

    #[test]
    fn adapter_and_connected_devices_are_summarized() {
        let mut objects = ManagedObjects::new();

        let mut adapter_interfaces = HashMap::new();
        adapter_interfaces.insert(
            ADAPTER_INTERFACE.to_owned(),
            properties(&[("Powered", Value::from(true)), ("Alias", Value::from("oziro"))]),
        );
        objects.insert(OwnedObjectPath::try_from("/org/bluez/hci0").unwrap(), adapter_interfaces);

        let mut device_interfaces = HashMap::new();
        device_interfaces
            .insert(DEVICE_INTERFACE.to_owned(), properties(&[("Connected", Value::from(true))]));
        objects.insert(
            OwnedObjectPath::try_from("/org/bluez/hci0/dev_AA").unwrap(),
            device_interfaces,
        );

        let snapshot = summarize(&objects).expect("adapter");
        assert_eq!(
            snapshot,
            AdapterSnapshot {
                path: "/org/bluez/hci0".to_owned(),
                powered: true,
                name: Some("oziro".to_owned()),
                connected_devices: 1,
            }
        );
    }

    #[test]
    fn unavailable_state_is_explicit() {
        let state = unavailable("no bluez");
        assert!(!state.available);
        assert_eq!(state.powered, None);
        assert_eq!(state.connected_devices, None);
    }
}
