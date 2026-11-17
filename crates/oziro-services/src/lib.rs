//! Oziro Linux service layer: application catalog, compositor adapters,
//! and system service integrations. All OS access lives behind this crate;
//! the GTK host and the frontend never talk to the system directly.

pub mod apps;
pub mod compositor;
pub mod error;
pub mod events;
pub mod icons;
pub mod notifications;
pub mod settings;
pub mod system;

pub use error::{OziroError, OziroResult};
pub use events::{EventHub, EventSender, OziroEvent};

use icons::IconRegistry;
use std::sync::{Arc, OnceLock};

/// Resolves an icon name to an opaque serving token, or None when no
/// real icon file exists in an allowed root.
pub fn icon_for_name(name: &str) -> Option<String> {
    global_icons().register_icon_name(name)
}

static GLOBAL_ICONS: OnceLock<Arc<IconRegistry>> = OnceLock::new();

/// Process-wide icon registry shared by the app catalog, compositor adapters,
/// and the host's icon endpoint.
pub fn global_icons() -> Arc<IconRegistry> {
    GLOBAL_ICONS.get_or_init(|| Arc::new(IconRegistry::new())).clone()
}
