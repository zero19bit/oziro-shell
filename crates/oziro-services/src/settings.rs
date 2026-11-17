//! User settings, persisted under `$XDG_CONFIG_HOME/oziro/settings.json`.
//!
//! Values are validated/clamped at load and at every update so a corrupted or
//! hand-edited file can never produce invalid runtime state.

use crate::error::{OziroError, OziroResult};
use oziro_protocol::Settings;
use serde_json::Value;
use std::{
    fs,
    path::{Path, PathBuf},
    sync::RwLock,
};

pub const PANEL_HEIGHT_RANGE: (u32, u32) = (44, 64);
pub const DOCK_SIZE_RANGE: (u32, u32) = (44, 88);
pub const BLUR_RANGE: (u32, u32) = (0, 40);

const SETTINGS_DIR: &str = "oziro";
const SETTINGS_FILE: &str = "settings.json";

fn clamp_range(value: u32, range: (u32, u32)) -> u32 {
    value.clamp(range.0, range.1)
}

fn sanitize_favorite(entry: &str) -> Option<String> {
    let trimmed = entry.trim();

    if trimmed.is_empty() || trimmed.len() > 255 {
        return None;
    }

    if !trimmed.chars().all(|c| c.is_ascii_alphanumeric() || matches!(c, '.' | '-' | '_' | '+')) {
        return None;
    }

    if trimmed.contains("..") {
        return None;
    }

    Some(trimmed.to_owned())
}

pub fn sanitize_favorites(favorites: &[String]) -> Vec<String> {
    let mut seen = Vec::new();

    for entry in favorites {
        if let Some(clean) = sanitize_favorite(entry) {
            if !seen.contains(&clean) {
                seen.push(clean);
            }
        }
    }

    seen
}

fn clamp_settings(mut settings: Settings) -> Settings {
    settings.panel_height = clamp_range(settings.panel_height, PANEL_HEIGHT_RANGE);
    settings.dock_size = clamp_range(settings.dock_size, DOCK_SIZE_RANGE);
    settings.blur_intensity = clamp_range(settings.blur_intensity, BLUR_RANGE);
    settings.favorites = sanitize_favorites(&settings.favorites);
    settings
}

/// Provides the protocol defaults; lives here so the settings module is the
/// single source of truth on the Rust side.
pub fn default_settings() -> Settings {
    oziro_protocol::default_settings()
}

#[derive(Debug)]
pub struct SettingsStore {
    path: PathBuf,
    settings: RwLock<Settings>,
}

impl SettingsStore {
    pub fn config_dir() -> PathBuf {
        if let Ok(xdg) = std::env::var("XDG_CONFIG_HOME") {
            if !xdg.trim().is_empty() {
                return PathBuf::from(xdg);
            }
        }

        if let Ok(home) = std::env::var("HOME") {
            if !home.trim().is_empty() {
                return Path::new(&home).join(".config");
            }
        }

        PathBuf::from(".")
    }

    pub fn settings_path() -> PathBuf {
        Self::config_dir().join(SETTINGS_DIR).join(SETTINGS_FILE)
    }

    /// Loads settings from disk, falling back to defaults. The returned
    /// settings are always valid, and the store remembers the effective
    /// values even when nothing was persisted yet.
    pub fn load() -> OziroResult<Self> {
        Self::load_from(&Self::config_dir())
    }

    /// Same as [`load`] but with an explicit base directory (used by tests).
    pub fn load_from(base_dir: &Path) -> OziroResult<Self> {
        let path = base_dir.join(SETTINGS_DIR).join(SETTINGS_FILE);
        let settings = match fs::read(&path) {
            Ok(bytes) => serde_json::from_slice::<Value>(&bytes)
                .ok()
                .and_then(|value| serde_json::from_value::<Settings>(value).ok())
                .map(clamp_settings)
                .unwrap_or_else(default_settings),
            Err(_) => default_settings(),
        };

        let store = Self { path, settings: RwLock::new(settings) };

        Ok(store)
    }

    pub fn get(&self) -> Settings {
        self.settings.read().expect("settings lock").clone()
    }

    pub fn update(&self, patch: &Value) -> OziroResult<Settings> {
        let updated = {
            let mut current = self.settings.write().expect("settings lock");

            let merged = clamp_settings(merge_patch(&current, patch)?);

            *current = merged.clone();
            merged
        };

        self.persist()?;
        Ok(updated)
    }

    fn persist(&self) -> OziroResult<()> {
        if let Some(parent) = self.path.parent() {
            fs::create_dir_all(parent)
                .map_err(|error| OziroError::settings_io(format!("create config dir: {error}")))?;
        }

        let json = serde_json::to_vec_pretty(&self.get())
            .map_err(|error| OziroError::settings_io(format!("serialize settings: {error}")))?;

        let temp_path = self.path.with_extension("json.tmp");

        {
            use std::io::Write;

            #[cfg(unix)]
            use std::os::unix::fs::OpenOptionsExt;

            let mut file = fs::OpenOptions::new()
                .write(true)
                .create(true)
                .truncate(true)
                .mode(0o600)
                .open(&temp_path)
                .map_err(|error| OziroError::settings_io(format!("write settings: {error}")))?;

            file.write_all(&json)
                .map_err(|error| OziroError::settings_io(format!("write settings: {error}")))?;
        }

        fs::rename(&temp_path, &self.path)
            .map_err(|error| OziroError::settings_io(format!("replace settings: {error}")))?;

        Ok(())
    }
}

/// Applies a JSON merge patch for the known settings fields only. Unknown
/// fields are rejected so typos surface instead of silently doing nothing.
fn merge_patch(current: &Settings, patch: &Value) -> OziroResult<Settings> {
    let object = patch
        .as_object()
        .ok_or_else(|| OziroError::invalid_params("settings patch must be an object"))?;

    let mut merged = current.clone();

    for (key, value) in object {
        match key.as_str() {
            "theme" => {
                merged.theme = serde_json::from_value(value.clone())
                    .map_err(|_| OziroError::invalid_params("theme must be 'dark' or 'light'"))?
            }
            "liquidGlass" => merged.liquid_glass = parse_bool(value, "liquidGlass")?,
            "blurIntensity" => merged.blur_intensity = parse_u32(value, "blurIntensity")?,
            "panelHeight" => merged.panel_height = parse_u32(value, "panelHeight")?,
            "panelAlignment" => {
                merged.panel_alignment = serde_json::from_value(value.clone()).map_err(|_| {
                    OziroError::invalid_params("panelAlignment must be left/center/right")
                })?
            }
            "dockSize" => merged.dock_size = parse_u32(value, "dockSize")?,
            "dockPosition" => {
                merged.dock_position = serde_json::from_value(value.clone()).map_err(|_| {
                    OziroError::invalid_params("dockPosition must be bottom/left/right")
                })?
            }
            "reducedMotion" => merged.reduced_motion = parse_bool(value, "reducedMotion")?,
            "animations" => merged.animations = parse_bool(value, "animations")?,
            "favorites" => {
                let list = value
                    .as_array()
                    .ok_or_else(|| OziroError::invalid_params("favorites must be an array"))?;

                let entries: Vec<String> = list
                    .iter()
                    .map(|item| {
                        item.as_str().map(ToOwned::to_owned).ok_or_else(|| {
                            OziroError::invalid_params("favorites entries must be strings")
                        })
                    })
                    .collect::<OziroResult<_>>()?;

                merged.favorites = sanitize_favorites(&entries);
            }
            unknown => {
                return Err(OziroError::invalid_params(format!("unknown setting: {unknown}")));
            }
        }
    }

    Ok(merged)
}

fn parse_bool(value: &Value, field: &str) -> OziroResult<bool> {
    value.as_bool().ok_or_else(|| OziroError::invalid_params(format!("{field} must be a boolean")))
}

fn parse_u32(value: &Value, field: &str) -> OziroResult<u32> {
    let number = value
        .as_i64()
        .ok_or_else(|| OziroError::invalid_params(format!("{field} must be a number")))?;

    if !(0..=100_000).contains(&number) {
        return Err(OziroError::invalid_params(format!("{field} out of range")));
    }

    Ok(number as u32)
}

#[cfg(test)]
mod tests {
    use super::*;
    use oziro_protocol::{DockPosition, PanelAlignment, ThemeMode};

    fn store() -> (SettingsStore, PathBuf) {
        let dir = std::env::temp_dir().join(format!(
            "oziro-settings-test-{}-{:?}",
            std::process::id(),
            std::thread::current().id()
        ));
        let path = dir.join("oziro/settings.json");

        let _ = std::fs::remove_dir_all(&dir);

        (SettingsStore::load_from(&dir).expect("load store"), path)
    }

    #[test]
    fn defaults_match_frontend_preview() {
        let defaults = default_settings();

        assert_eq!(defaults.theme, ThemeMode::Dark);
        assert_eq!(defaults.blur_intensity, 24);
        assert_eq!(defaults.panel_height, 54);
        assert_eq!(defaults.dock_size, 56);
    }

    #[test]
    fn values_are_clamped_into_supported_ranges() {
        let (store, _path) = store();

        let merged = store
            .update(&serde_json::json!({
                "panelHeight": 400,
                "dockSize": 4,
                "blurIntensity": 999,
                "favorites": ["firefox.desktop", "../etc/passwd", "firefox.desktop", "a b"]
            }))
            .expect("update");

        assert_eq!(merged.panel_height, PANEL_HEIGHT_RANGE.1);
        assert_eq!(merged.dock_size, DOCK_SIZE_RANGE.0);
        assert_eq!(merged.blur_intensity, BLUR_RANGE.1);

        assert_eq!(merged.favorites, vec!["firefox.desktop".to_owned()]);
    }

    #[test]
    fn unknown_fields_are_rejected() {
        let raw = serde_json::json!({ "nonsense": true });
        let result = merge_patch(&default_settings(), &raw);

        assert!(result.is_err());
    }

    #[test]
    fn updates_persist_to_disk() {
        let (store, path) = store();

        let updated = store
            .update(&serde_json::json!({ "theme": "light", "dockPosition": "left" }))
            .expect("update");

        assert_eq!(updated.theme, ThemeMode::Light);
        assert_eq!(updated.dock_position, DockPosition::Left);

        let saved = std::fs::read(&path).expect("saved file");
        let parsed: Settings = serde_json::from_slice(&saved).expect("valid json");

        assert_eq!(parsed.theme, ThemeMode::Light);
        assert_eq!(parsed.dock_position, DockPosition::Left);

        let base = path
            .parent()
            .and_then(|parent| parent.parent())
            .map(Path::to_path_buf)
            .expect("base dir");
        let reloaded = SettingsStore::load_from(&base).expect("reload");
        assert_eq!(reloaded.get().theme, ThemeMode::Light);
    }

    #[test]
    fn corrupted_file_falls_back_to_defaults() {
        let (_store, path) = store();

        std::fs::create_dir_all(path.parent().expect("parent dir")).expect("create dir");
        std::fs::write(&path, b"{ not valid json").expect("write corrupt file");

        let base = path
            .parent()
            .and_then(|parent| parent.parent())
            .map(Path::to_path_buf)
            .expect("base dir");

        let reloaded = SettingsStore::load_from(&base).expect("reload still works");
        assert_eq!(reloaded.get(), default_settings());
    }

    #[test]
    fn sanitize_rejects_paths_and_duplicates() {
        let cleaned = sanitize_favorites(&[
            "ok.desktop".to_owned(),
            "../escape".to_owned(),
            "with space".to_owned(),
            "ok.desktop".to_owned(),
        ]);

        assert_eq!(cleaned, vec!["ok.desktop".to_owned()]);
    }

    #[test]
    fn enums_serialize_like_the_frontend() {
        assert_eq!(
            serde_json::to_value(PanelAlignment::Center).unwrap(),
            serde_json::json!("center")
        );
        assert_eq!(serde_json::to_value(DockPosition::Left).unwrap(), serde_json::json!("left"));
    }
}
