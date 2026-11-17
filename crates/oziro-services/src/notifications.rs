//! Notification state.
//!
//! If another daemon owns `org.freedesktop.Notifications` (the normal case on
//! Plasma), Oziro reports that honestly and exposes no history: reading another
//! process's private notification state is not possible over D-Bus. When the
//! name is free, Oziro serves the standard interface itself and keeps a bounded
//! in-memory history.

use crate::error::{OziroError, OziroResult};
use crate::{EventSender, OziroEvent};
use oziro_protocol::{
    NotificationDaemonMode, NotificationStatus, NotificationUrgency, NotificationsResult,
    StoredNotification,
};
use std::collections::HashMap;
use std::sync::atomic::{AtomicU32, Ordering};
use std::sync::{Arc, Mutex, MutexGuard};
use std::time::{SystemTime, UNIX_EPOCH};
use zbus::blocking::Connection;
use zbus::zvariant::OwnedValue;

const NOTIFICATIONS_NAME: &str = "org.freedesktop.Notifications";
const NOTIFICATIONS_PATH: &str = "/org/freedesktop/Notifications";
const HISTORY_LIMIT: usize = 100;

fn lock<T>(mutex: &Mutex<T>) -> MutexGuard<'_, T> {
    mutex.lock().unwrap_or_else(|poisoned| poisoned.into_inner())
}

fn unavailable_status(reason: Option<String>, owner: Option<String>) -> NotificationStatus {
    let _ = reason;

    NotificationStatus {
        daemon: if owner.is_some() {
            NotificationDaemonMode::External
        } else {
            NotificationDaemonMode::None
        },
        daemon_owner: owner,
        can_receive: false,
        can_dismiss: false,
    }
}

fn now_ms() -> u64 {
    SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map(|duration| duration.as_millis() as u64)
        .unwrap_or(0)
}

fn urgency_from_hints(hints: &HashMap<String, OwnedValue>) -> NotificationUrgency {
    match hints.get("urgency").and_then(|value| u8::try_from(value).ok()) {
        Some(0) => NotificationUrgency::Low,
        Some(2) => NotificationUrgency::Critical,
        _ => NotificationUrgency::Normal,
    }
}

fn truncate(value: &str, limit: usize) -> String {
    value.chars().take(limit).collect()
}

#[derive(Clone)]
struct Shared {
    status: Arc<Mutex<NotificationStatus>>,
    history: Arc<Mutex<Vec<StoredNotification>>>,
    next_id: Arc<AtomicU32>,
    sender: EventSender,
}

impl Shared {
    fn snapshot(&self) -> NotificationsResult {
        NotificationsResult {
            status: lock(&self.status).clone(),
            notifications: lock(&self.history).clone(),
        }
    }

    fn publish(&self) {
        (self.sender)(OziroEvent::Notifications(self.snapshot()));
    }

    fn set_status(&self, status: NotificationStatus) {
        *lock(&self.status) = status;
        self.publish();
    }

    fn store(
        &self,
        app_name: String,
        app_icon: String,
        summary: String,
        body: String,
        urgency: NotificationUrgency,
        replaces_id: u32,
    ) -> u32 {
        let mut history = lock(&self.history);

        let existing = if replaces_id != 0 {
            history.iter().position(|item| item.id == replaces_id.to_string())
        } else {
            None
        };

        let id = existing
            .map(|index| history.remove(index))
            .map(|item| item.id.parse::<u32>().unwrap_or(0))
            .filter(|id| *id != 0)
            .unwrap_or_else(|| self.next_id.fetch_add(1, Ordering::Relaxed));

        history.insert(
            0,
            StoredNotification {
                id: id.to_string(),
                app_name: truncate(&app_name, 128),
                app_icon: if app_icon.is_empty() { None } else { Some(truncate(&app_icon, 512)) },
                summary: truncate(&summary, 512),
                body: truncate(&body, 4096),
                timestamp_ms: now_ms(),
                urgency,
            },
        );

        history.truncate(HISTORY_LIMIT);
        id
    }

    fn dismiss(&self, id: u32) -> bool {
        let mut history = lock(&self.history);
        let previous = history.len();
        history.retain(|item| item.id != id.to_string());
        previous != history.len()
    }
}

struct NotificationsIface {
    shared: Shared,
}

#[zbus::interface(name = "org.freedesktop.Notifications")]
impl NotificationsIface {
    fn get_capabilities(&self) -> Vec<String> {
        vec!["body".to_owned(), "icon-static".to_owned()]
    }

    fn get_server_information(&self) -> (String, String, String, String) {
        (
            "Oziro".to_owned(),
            "Oziro Desktop".to_owned(),
            env!("CARGO_PKG_VERSION").to_owned(),
            "1.2".to_owned(),
        )
    }

    #[allow(clippy::too_many_arguments)]
    fn notify(
        &self,
        app_name: String,
        replaces_id: u32,
        app_icon: String,
        summary: String,
        body: String,
        _actions: Vec<String>,
        hints: HashMap<String, OwnedValue>,
        _expire_timeout: i32,
    ) -> u32 {
        let urgency = urgency_from_hints(&hints);
        let id = self.shared.store(app_name, app_icon, summary, body, urgency, replaces_id);
        self.shared.publish();
        id
    }

    fn close_notification(&self, id: u32) {
        if self.shared.dismiss(id) {
            self.shared.publish();
        }
    }
}

fn name_owner(connection: &Connection) -> OziroResult<Option<String>> {
    match connection.call_method(
        Some("org.freedesktop.DBus"),
        "/org/freedesktop/DBus",
        Some("org.freedesktop.DBus"),
        "GetNameOwner",
        &(NOTIFICATIONS_NAME,),
    ) {
        Ok(reply) => reply.body().deserialize::<String>().map(Some).map_err(|error| {
            OziroError::service_unavailable(format!("Notification owner: {error}"))
        }),
        Err(zbus::Error::MethodError(name, _, _))
            if name.as_str() == "org.freedesktop.DBus.Error.NameHasNoOwner" =>
        {
            Ok(None)
        }
        Err(error) => Err(OziroError::service_unavailable(format!("Notification bus: {error}"))),
    }
}

/// RAII-ish service: `connection` keeps the served name alive in Oziro mode.
pub struct NotificationsService {
    shared: Shared,
    _connection: Option<Connection>,
}

impl NotificationsService {
    /// A service that never touches the bus. Used by tests and by hosts that
    /// deliberately disable notification integration.
    pub fn disabled(sender: EventSender) -> Self {
        let shared = Shared {
            status: Arc::new(Mutex::new(unavailable_status(
                Some("Notifications are disabled".to_owned()),
                None,
            ))),
            history: Arc::new(Mutex::new(Vec::new())),
            next_id: Arc::new(AtomicU32::new(1)),
            sender,
        };

        Self { shared, _connection: None }
    }

    pub fn new(sender: EventSender) -> Self {
        let status = Arc::new(Mutex::new(unavailable_status(None, None)));
        let shared = Shared {
            status,
            history: Arc::new(Mutex::new(Vec::new())),
            next_id: Arc::new(AtomicU32::new(1)),
            sender,
        };

        let Ok(connection) = Connection::session() else {
            shared.set_status(unavailable_status(Some("Session bus unavailable".to_owned()), None));
            return Self { shared, _connection: None };
        };

        match name_owner(&connection) {
            Ok(Some(owner)) => {
                shared.set_status(NotificationStatus {
                    daemon: NotificationDaemonMode::External,
                    daemon_owner: Some(owner),
                    can_receive: false,
                    can_dismiss: false,
                });
                return Self { shared, _connection: None };
            }
            Ok(None) => {}
            Err(error) => {
                eprintln!("[OZIRO NOTIFY] owner check failed: {error}");
            }
        }

        match zbus::blocking::connection::Builder::session()
            .and_then(|builder| builder.name(NOTIFICATIONS_NAME))
            .and_then(|builder| {
                builder.serve_at(NOTIFICATIONS_PATH, NotificationsIface { shared: shared.clone() })
            })
            .and_then(|builder| builder.build())
        {
            Ok(connection) => {
                let owner = connection.unique_name().map(ToString::to_string);
                shared.set_status(NotificationStatus {
                    daemon: NotificationDaemonMode::Oziro,
                    daemon_owner: owner,
                    can_receive: true,
                    can_dismiss: true,
                });

                Self { shared, _connection: Some(connection) }
            }
            Err(error) => {
                eprintln!("[OZIRO NOTIFY] daemon unavailable: {error}");
                shared.set_status(unavailable_status(
                    Some(format!("Notification daemon unavailable: {error}")),
                    None,
                ));
                Self { shared, _connection: None }
            }
        }
    }

    pub fn list(&self) -> NotificationsResult {
        self.shared.snapshot()
    }

    pub fn status(&self) -> NotificationStatus {
        lock(&self.shared.status).clone()
    }

    pub fn dismiss(&self, id: &str) -> OziroResult<()> {
        let status = self.status();

        if status.daemon != NotificationDaemonMode::Oziro {
            return Err(OziroError::notification_unavailable(
                "Notification history is owned by another daemon",
            ));
        }

        let id = id
            .parse::<u32>()
            .map_err(|_| OziroError::invalid_params("notification id must be numeric"))?;

        if self.shared.dismiss(id) {
            self.shared.publish();
        }

        Ok(())
    }

    pub fn clear(&self) -> OziroResult<()> {
        let status = self.status();

        if status.daemon != NotificationDaemonMode::Oziro {
            return Err(OziroError::notification_unavailable(
                "Notification history is owned by another daemon",
            ));
        }

        let mut history = lock(&self.shared.history);
        if !history.is_empty() {
            history.clear();
            drop(history);
            self.shared.publish();
        }

        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::sync::Arc;

    fn shared() -> Shared {
        Shared {
            status: Arc::new(Mutex::new(NotificationStatus {
                daemon: NotificationDaemonMode::Oziro,
                daemon_owner: Some(":1.42".to_owned()),
                can_receive: true,
                can_dismiss: true,
            })),
            history: Arc::new(Mutex::new(Vec::new())),
            next_id: Arc::new(AtomicU32::new(1)),
            sender: Arc::new(|_| {}),
        }
    }

    #[test]
    fn new_notifications_get_increasing_ids() {
        let shared = shared();
        let first = shared.store(
            "app".to_owned(),
            String::new(),
            "summary".to_owned(),
            String::new(),
            NotificationUrgency::Normal,
            0,
        );
        let second = shared.store(
            "app".to_owned(),
            String::new(),
            "summary".to_owned(),
            String::new(),
            NotificationUrgency::Normal,
            0,
        );

        assert_eq!(first, 1);
        assert_eq!(second, 2);
        assert_eq!(lock(&shared.history).len(), 2);
        assert_eq!(lock(&shared.history)[0].id, "2");
    }

    #[test]
    fn replaces_id_updates_in_place() {
        let shared = shared();
        let id = shared.store(
            "app".to_owned(),
            String::new(),
            "first".to_owned(),
            String::new(),
            NotificationUrgency::Low,
            0,
        );
        let replaced = shared.store(
            "app".to_owned(),
            "icon".to_owned(),
            "second".to_owned(),
            "body".to_owned(),
            NotificationUrgency::Critical,
            id,
        );

        assert_eq!(replaced, id);
        let history = lock(&shared.history);
        assert_eq!(history.len(), 1);
        assert_eq!(history[0].summary, "second");
        assert_eq!(history[0].urgency, NotificationUrgency::Critical);
    }

    #[test]
    fn history_is_bounded() {
        let shared = shared();

        for index in 0..(HISTORY_LIMIT + 10) {
            shared.store(
                "app".to_owned(),
                String::new(),
                format!("notification {index}"),
                String::new(),
                NotificationUrgency::Normal,
                0,
            );
        }

        assert_eq!(lock(&shared.history).len(), HISTORY_LIMIT);
    }

    #[test]
    fn dismissal_removes_only_the_requested_id() {
        let shared = shared();
        let first = shared.store(
            "app".to_owned(),
            String::new(),
            "first".to_owned(),
            String::new(),
            NotificationUrgency::Normal,
            0,
        );
        shared.store(
            "app".to_owned(),
            String::new(),
            "second".to_owned(),
            String::new(),
            NotificationUrgency::Normal,
            0,
        );

        assert!(shared.dismiss(first));
        assert!(!shared.dismiss(first));
        assert_eq!(lock(&shared.history).len(), 1);
    }

    #[test]
    fn urgency_hints_are_mapped() {
        let mut hints = HashMap::new();
        hints.insert("urgency".to_owned(), OwnedValue::from(0u8));
        assert_eq!(urgency_from_hints(&hints), NotificationUrgency::Low);

        hints.insert("urgency".to_owned(), OwnedValue::from(2u8));
        assert_eq!(urgency_from_hints(&hints), NotificationUrgency::Critical);

        hints.insert(
            "urgency".to_owned(),
            OwnedValue::try_from(zbus::zvariant::Value::from("high")).unwrap(),
        );
        assert_eq!(urgency_from_hints(&hints), NotificationUrgency::Normal);
    }

    #[test]
    fn external_daemon_status_is_not_writable() {
        let status = unavailable_status(None, Some(":1.7".to_owned()));
        assert_eq!(status.daemon, NotificationDaemonMode::External);
        assert!(!status.can_receive);
        assert!(!status.can_dismiss);
    }
}
