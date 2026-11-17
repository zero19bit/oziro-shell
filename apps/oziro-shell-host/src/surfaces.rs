//! GTK layer-shell surfaces. Each surface hosts the same bundle with a
//! different `?surface=` value; popups are separate tiny windows so no
//! full-screen transparent surface ever blocks input.
//!
//! Panel and dock are created eagerly; other surfaces are created on first
//! use so a closed popup costs no WebKit process.

use gtk::prelude::*;
use gtk::{Application, ApplicationWindow};
use gtk4_layer_shell::{Edge, KeyboardMode, Layer, LayerShell};
use oziro_protocol::{DockPosition, PopupSurface, Settings};
use std::collections::HashMap;
use std::rc::Rc;
use webkit6::UserContentManager;
use webkit6::prelude::*;

const PANEL_CHROME: i32 = 14;
const PANEL_MIN_HEIGHT: i32 = 44;
const PANEL_MAX_HEIGHT: i32 = 96;

const DOCK_PADDING: i32 = 24;
const DOCK_MARGIN: i32 = 8;
const DOCK_MIN_SIZE: i32 = 72;
const DOCK_MAX_SIZE: i32 = 2200;

const POPUP_TOP_GAP: i32 = 8;
const POPUP_SIDE_MARGIN: i32 = 12;
const POPUP_BOTTOM_MARGIN: i32 = 12;

const LAUNCHER_SIZE: (i32, i32) = (760, 680);
const CONTROL_SIZE: (i32, i32) = (420, 560);
const SETTINGS_SIZE: (i32, i32) = (420, 560);
const NOTIFICATIONS_SIZE: (i32, i32) = (390, 500);

const MAX_BRIDGE_MESSAGE_BYTES: usize = 128 * 1024;

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub enum SurfaceId {
    Panel,
    Dock,
    Launcher,
    Control,
    Settings,
    Notifications,
    Overview,
}

impl SurfaceId {
    fn param(self) -> &'static str {
        match self {
            Self::Panel => "panel",
            Self::Dock => "dock",
            Self::Launcher => "launcher",
            Self::Control => "control",
            Self::Settings => "settings",
            Self::Notifications => "notifications",
            Self::Overview => "overview",
        }
    }

    fn from_popup(surface: PopupSurface) -> Self {
        match surface {
            PopupSurface::Launcher => Self::Launcher,
            PopupSurface::Control => Self::Control,
            PopupSurface::Notifications => Self::Notifications,
            PopupSurface::Overview => Self::Overview,
            PopupSurface::Settings => Self::Settings,
        }
    }

    fn is_popup(self) -> bool {
        !matches!(self, Self::Panel | Self::Dock)
    }
}

pub struct SurfaceManager {
    application: Application,
    base_url: String,
    requests: Rc<dyn Fn(String)>,
    windows: HashMap<SurfaceId, ApplicationWindow>,
    views: Vec<webkit6::WebView>,
    settings: Settings,
    dock_content: (i32, i32),
}

impl SurfaceManager {
    pub fn new(
        application: &Application,
        base_url: &str,
        settings: Settings,
        requests: Rc<dyn Fn(String)>,
    ) -> Self {
        let mut manager = Self {
            application: application.clone(),
            base_url: base_url.to_owned(),
            requests,
            windows: HashMap::new(),
            views: Vec::new(),
            dock_content: (360, 80),
            settings,
        };

        manager.create_surface(SurfaceId::Panel);
        manager.create_surface(SurfaceId::Dock);
        manager.apply_settings(manager.settings.clone());

        for surface in [SurfaceId::Panel, SurfaceId::Dock] {
            if let Some(window) = manager.windows.get(&surface) {
                window.present();
            }
        }

        manager
    }

    fn create_surface(&mut self, surface: SurfaceId) {
        let window = ApplicationWindow::builder()
            .application(&self.application)
            .title(format!("Oziro {}", surface.param()))
            .decorated(false)
            .build();

        window.add_css_class("oziro-surface");
        window.init_layer_shell();
        window.set_namespace(Some(&format!("oziro-{}", surface.param())));

        let layer = if surface == SurfaceId::Overview { Layer::Overlay } else { Layer::Top };
        window.set_layer(layer);

        for edge in [Edge::Top, Edge::Bottom, Edge::Left, Edge::Right] {
            window.set_anchor(edge, false);
            window.set_margin(edge, 0);
        }

        window.set_exclusive_zone(0);

        let keyboard_mode = match surface {
            SurfaceId::Panel | SurfaceId::Dock => KeyboardMode::None,
            SurfaceId::Launcher | SurfaceId::Overview => KeyboardMode::Exclusive,
            _ => KeyboardMode::OnDemand,
        };
        window.set_keyboard_mode(keyboard_mode);

        let user_content = UserContentManager::new();
        user_content.register_script_message_handler("oziro", None);

        let requests = self.requests.clone();
        user_content.connect_script_message_received(Some("oziro"), move |_, value| {
            let message = value.to_str().to_string();

            if message.len() <= MAX_BRIDGE_MESSAGE_BYTES {
                requests(message);
            }
        });

        let web_view = webkit6::WebView::builder().user_content_manager(&user_content).build();

        let webkit_settings = webkit6::Settings::default();
        webkit_settings.set_enable_developer_extras(cfg!(debug_assertions));
        webkit_settings.set_enable_write_console_messages_to_stdout(cfg!(debug_assertions));
        web_view.set_settings(&webkit_settings);

        let transparent = webkit6::gdk::RGBA::new(0.0, 0.0, 0.0, 0.0);
        web_view.set_background_color(&transparent);
        web_view.set_hexpand(true);
        web_view.set_vexpand(true);

        web_view.connect_load_failed(|_, event, uri, error| {
            eprintln!("[OZIRO WEBKIT] load failed: event={event:?} uri={uri} error={error}");
            false
        });

        web_view.connect_web_process_terminated(|_, reason| {
            eprintln!("[OZIRO WEBKIT] web process terminated: {reason:?}");
        });

        window.set_child(Some(&web_view));

        let url = format!("{}?surface={}", self.base_url, surface.param());
        eprintln!("[OZIRO] Loading {url}");
        web_view.load_uri(&url);

        self.views.push(web_view);
        self.windows.insert(surface, window);
    }

    /// Creates a surface on demand and applies its current geometry.
    fn ensure_surface(&mut self, surface: SurfaceId) {
        if self.windows.contains_key(&surface) {
            return;
        }

        self.create_surface(surface);

        match surface {
            SurfaceId::Panel => self.apply_panel_geometry(),
            SurfaceId::Dock => self.apply_dock_geometry(),
            _ => self.apply_popup_geometry(),
        }
    }

    fn panel_height(&self) -> i32 {
        (self.settings.panel_height as i32 + PANEL_CHROME).clamp(PANEL_MIN_HEIGHT, PANEL_MAX_HEIGHT)
    }

    fn apply_settings(&mut self, settings: Settings) {
        self.settings = settings;
        self.apply_panel_geometry();
        self.apply_dock_geometry();
        self.apply_popup_geometry();
    }

    fn apply_panel_geometry(&self) {
        let Some(panel) = self.windows.get(&SurfaceId::Panel) else {
            return;
        };

        let height = self.panel_height();

        for edge in [Edge::Top, Edge::Bottom, Edge::Left, Edge::Right] {
            panel.set_anchor(edge, false);
            panel.set_margin(edge, 0);
        }

        panel.set_anchor(Edge::Top, true);
        panel.set_anchor(Edge::Left, true);
        panel.set_anchor(Edge::Right, true);
        panel.set_exclusive_zone(height);
        panel.set_default_size(1, height);
    }

    fn apply_popup_geometry(&self) {
        let top = self.panel_height() + POPUP_TOP_GAP;

        if let Some(window) = self.windows.get(&SurfaceId::Launcher) {
            window.set_anchor(Edge::Bottom, false);
            window.set_anchor(Edge::Right, false);
            window.set_anchor(Edge::Top, true);
            window.set_anchor(Edge::Left, true);
            window.set_margin(Edge::Top, top);
            window.set_margin(Edge::Left, POPUP_SIDE_MARGIN);
            window.set_default_size(LAUNCHER_SIZE.0, LAUNCHER_SIZE.1);
        }

        for (surface, size) in
            [(SurfaceId::Control, CONTROL_SIZE), (SurfaceId::Settings, SETTINGS_SIZE)]
        {
            if let Some(window) = self.windows.get(&surface) {
                window.set_anchor(Edge::Bottom, false);
                window.set_anchor(Edge::Left, false);
                window.set_anchor(Edge::Top, true);
                window.set_anchor(Edge::Right, true);
                window.set_margin(Edge::Top, top);
                window.set_margin(Edge::Right, POPUP_SIDE_MARGIN);
                window.set_default_size(size.0, size.1);
            }
        }

        if let Some(window) = self.windows.get(&SurfaceId::Notifications) {
            window.set_anchor(Edge::Top, false);
            window.set_anchor(Edge::Left, false);
            window.set_anchor(Edge::Bottom, true);
            window.set_anchor(Edge::Right, true);
            window.set_margin(Edge::Bottom, POPUP_BOTTOM_MARGIN);
            window.set_margin(Edge::Right, POPUP_SIDE_MARGIN);
            window.set_default_size(NOTIFICATIONS_SIZE.0, NOTIFICATIONS_SIZE.1);
        }

        if let Some(window) = self.windows.get(&SurfaceId::Overview) {
            for edge in [Edge::Top, Edge::Bottom, Edge::Left, Edge::Right] {
                window.set_anchor(edge, true);
                window.set_margin(edge, 0);
            }
        }
    }

    fn apply_dock_geometry(&self) {
        let Some(dock) = self.windows.get(&SurfaceId::Dock) else {
            return;
        };

        for edge in [Edge::Top, Edge::Bottom, Edge::Left, Edge::Right] {
            dock.set_anchor(edge, false);
            dock.set_margin(edge, 0);
        }

        let width = (self.dock_content.0 + DOCK_PADDING).clamp(DOCK_MIN_SIZE, DOCK_MAX_SIZE);
        let height = (self.dock_content.1 + DOCK_PADDING).clamp(DOCK_MIN_SIZE, DOCK_MAX_SIZE);

        match self.settings.dock_position {
            DockPosition::Bottom => {
                dock.set_anchor(Edge::Bottom, true);
                dock.set_margin(Edge::Bottom, DOCK_MARGIN);
                dock.set_exclusive_zone(height + DOCK_MARGIN);
            }
            DockPosition::Left => {
                dock.set_anchor(Edge::Left, true);
                dock.set_margin(Edge::Left, DOCK_MARGIN);
                dock.set_exclusive_zone(width + DOCK_MARGIN);
            }
            DockPosition::Right => {
                dock.set_anchor(Edge::Right, true);
                dock.set_margin(Edge::Right, DOCK_MARGIN);
                dock.set_exclusive_zone(width + DOCK_MARGIN);
            }
        }

        dock.set_default_size(width, height);
        dock.set_default_size(width, height);
    }

    pub fn toggle(&mut self, surface: PopupSurface) {
        let id = SurfaceId::from_popup(surface);

        match id {
            SurfaceId::Control => self.hide_surface(SurfaceId::Settings),
            SurfaceId::Settings => self.hide_surface(SurfaceId::Control),
            SurfaceId::Overview => {
                for other in [
                    SurfaceId::Launcher,
                    SurfaceId::Control,
                    SurfaceId::Settings,
                    SurfaceId::Notifications,
                ] {
                    self.hide_surface(other);
                }
            }
            _ => self.hide_surface(SurfaceId::Overview),
        }

        self.ensure_surface(id);

        let Some(window) = self.windows.get(&id) else {
            return;
        };

        if window.is_visible() {
            window.set_visible(false);
        } else {
            self.apply_popup_geometry();
            window.present();
        }
    }

    pub fn hide(&mut self, surface: PopupSurface) {
        self.hide_surface(SurfaceId::from_popup(surface));
    }

    fn hide_surface(&mut self, surface: SurfaceId) {
        if surface.is_popup() {
            if let Some(window) = self.windows.get(&surface) {
                window.set_visible(false);
            }
        }
    }

    /// The dock reports its own content box; the host adds room for hover
    /// shadows and tooltips and keeps the surface anchored to the chosen edge.
    pub fn resize_dock(&mut self, width: i32, height: i32) {
        if !(1..=4096).contains(&width) || !(1..=4096).contains(&height) {
            return;
        }

        if self.dock_content == (width, height) {
            return;
        }

        self.dock_content = (width, height);
        self.apply_dock_geometry();
    }

    pub fn apply_settings_event(&mut self, settings: Settings) {
        self.apply_settings(settings);
    }

    pub fn broadcast_event(&self, envelope_json: &str) {
        let payload = match serde_json::to_string(envelope_json) {
            Ok(payload) => payload,
            Err(_) => return,
        };

        self.evaluate_all(&format!(
            "if (window.__oziroEvent) {{ window.__oziroEvent({payload}); }}"
        ));
    }

    pub fn resolve(&self, request_id: &str, response_json: &str) {
        let (Ok(id), Ok(payload)) =
            (serde_json::to_string(request_id), serde_json::to_string(response_json))
        else {
            return;
        };

        self.evaluate_all(&format!(
            "if (window.__oziroResolve) {{ window.__oziroResolve({id}, {payload}); }}"
        ));
    }

    fn evaluate_all(&self, script: &str) {
        for view in &self.views {
            view.evaluate_javascript(script, None, None, None::<&gtk::gio::Cancellable>, |_| {});
        }
    }

    #[cfg(test)]
    pub fn surface_params() -> Vec<&'static str> {
        [
            SurfaceId::Panel,
            SurfaceId::Dock,
            SurfaceId::Launcher,
            SurfaceId::Control,
            SurfaceId::Settings,
            SurfaceId::Notifications,
            SurfaceId::Overview,
        ]
        .into_iter()
        .map(SurfaceId::param)
        .collect()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn every_surface_has_a_distinct_query_value() {
        let params = SurfaceManager::surface_params();
        let unique: std::collections::HashSet<_> = params.iter().collect();
        assert_eq!(unique.len(), params.len());
        assert!(params.contains(&"panel"));
        assert!(params.contains(&"overview"));
    }

    #[test]
    fn popup_mapping_covers_every_protocol_surface() {
        for surface in [
            PopupSurface::Launcher,
            PopupSurface::Control,
            PopupSurface::Settings,
            PopupSurface::Notifications,
            PopupSurface::Overview,
        ] {
            assert!(SurfaceId::from_popup(surface).is_popup());
        }
    }
}
