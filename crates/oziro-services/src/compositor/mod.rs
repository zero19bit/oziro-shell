//! Compositor adapters: a single normalized interface over concrete compositors.

pub mod hyprland;
pub mod kwin;

use crate::error::OziroResult;
use oziro_protocol::{WindowsResult, WorkspacesResult};
use std::sync::Arc;

/// Normalized operations every compositor adapter implements. Unsupported
/// operations return errors — they are never simulated.
pub trait Compositor: Send + Sync {
    /// Short adapter identifier, e.g. "hyprland" or "kwin".
    fn id(&self) -> &'static str;

    fn workspaces(&self) -> OziroResult<WorkspacesResult>;
    fn activate_workspace(&self, id: &str) -> OziroResult<()>;
    fn windows(&self) -> OziroResult<WindowsResult>;
    fn activate_window(&self, id: &str) -> OziroResult<()>;

    /// Starts a background monitor that forwards [`OziroEvent`]s.
    fn spawn_monitor(
        &self,
        sender: crate::EventSender,
    ) -> std::io::Result<std::thread::JoinHandle<()>>;
}

/// The best available adapter for this session, or none.
pub fn detect() -> Option<Arc<dyn Compositor>> {
    if let Some(adapter) = hyprland::HyprlandAdapter::detect() {
        return Some(Arc::new(adapter) as Arc<dyn Compositor>);
    }

    kwin::KWinAdapter::detect().map(|adapter| Arc::new(adapter) as Arc<dyn Compositor>)
}

/// An explicit "no compositor" result so the UI can show honest state.
pub fn unavailable(reason: &str) -> (WorkspacesResult, WindowsResult) {
    (
        WorkspacesResult {
            compositor: None,
            supported: false,
            unavailable_reason: Some(reason.to_owned()),
            workspaces: Vec::new(),
            active_id: None,
        },
        WindowsResult {
            compositor: None,
            supported: false,
            unavailable_reason: Some(reason.to_owned()),
            windows: Vec::new(),
            active_id: None,
        },
    )
}
