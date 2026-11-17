//! Display brightness through `/sys/class/backlight`.
//!
//! Reading is always supported when a device exists. Writing is advertised
//! only when the kernel node is opened writable without changing anything;
//! a permission error degrades to a read-only state instead of a fake toggle.

use crate::error::{OziroError, OziroResult};
use oziro_protocol::BrightnessState;
use std::fs::{self, OpenOptions};
use std::path::{Path, PathBuf};

const BACKLIGHT_ROOT: &str = "/sys/class/backlight";

fn unavailable(reason: impl Into<String>) -> BrightnessState {
    BrightnessState {
        available: false,
        unavailable_reason: Some(reason.into()),
        percent: None,
        device: None,
        supports_set: false,
    }
}

fn percent_from_raw(raw: u32, max: u32) -> f64 {
    if max == 0 { 0.0 } else { (raw as f64 / max as f64 * 100.0).clamp(0.0, 100.0) }
}

fn raw_from_percent(percent: f64, max: u32) -> u32 {
    let value = (percent / 100.0 * max as f64).round();

    if value.is_finite() { (value as u64).min(max as u64) as u32 } else { 0 }
}

struct BacklightDevice {
    name: String,
    root: PathBuf,
    max: u32,
    supports_set: bool,
}

impl BacklightDevice {
    fn discover() -> Option<Self> {
        let mut names = fs::read_dir(BACKLIGHT_ROOT)
            .ok()?
            .filter_map(Result::ok)
            .filter(|entry| entry.path().is_dir())
            .map(|entry| entry.file_name().to_string_lossy().into_owned())
            .collect::<Vec<_>>();

        names.sort();

        names.into_iter().find_map(|name| {
            let root = Path::new(BACKLIGHT_ROOT).join(&name);
            let max = fs::read_to_string(root.join("max_brightness"))
                .ok()?
                .trim()
                .parse::<u32>()
                .ok()
                .filter(|max| *max > 0)?;

            let supports_set = OpenOptions::new().write(true).open(root.join("brightness")).is_ok();

            Some(Self { name, root, max, supports_set })
        })
    }

    fn current_raw(&self) -> Option<u32> {
        fs::read_to_string(self.root.join("brightness")).ok()?.trim().parse::<u32>().ok()
    }

    fn state(&self) -> BrightnessState {
        let raw = self.current_raw();

        BrightnessState {
            available: true,
            unavailable_reason: if raw.is_none() {
                Some("Brightness value is not readable".to_owned())
            } else {
                None
            },
            percent: raw.map(|raw| percent_from_raw(raw, self.max)),
            device: Some(self.name.clone()),
            supports_set: self.supports_set,
        }
    }

    fn set(&self, percent: f64) -> OziroResult<()> {
        if !self.supports_set {
            return Err(OziroError::service_failed("Brightness is read-only for this user"));
        }

        let raw = raw_from_percent(percent, self.max);

        fs::write(self.root.join("brightness"), raw.to_string()).map_err(|error| {
            OziroError::service_failed(format!("Brightness write failed: {error}"))
        })
    }
}

#[derive(Default)]
pub struct BrightnessService {
    device: Option<BacklightDevice>,
}

impl BrightnessService {
    pub fn new() -> Self {
        Self { device: BacklightDevice::discover() }
    }

    pub fn get(&self) -> BrightnessState {
        match &self.device {
            Some(device) => device.state(),
            None => unavailable("No backlight device was found"),
        }
    }

    /// `percent` must be finite and inside 0–100; it is validated here even
    /// though the frontend clamps it as well.
    pub fn set(&self, percent: f64) -> OziroResult<BrightnessState> {
        if !percent.is_finite() || !(0.0..=100.0).contains(&percent) {
            return Err(OziroError::invalid_params("brightness must be between 0 and 100"));
        }

        let device = self
            .device
            .as_ref()
            .ok_or_else(|| OziroError::service_unavailable("No backlight device was found"))?;

        device.set(percent)?;
        Ok(device.state())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn percentages_convert_without_overflow() {
        assert_eq!(percent_from_raw(0, 100), 0.0);
        assert_eq!(percent_from_raw(50, 100), 50.0);
        assert_eq!(percent_from_raw(100, 100), 100.0);
        assert_eq!(percent_from_raw(1, 0), 0.0);
        assert_eq!(percent_from_raw(1000, 100), 100.0);
    }

    #[test]
    fn percentages_convert_to_raw_values() {
        assert_eq!(raw_from_percent(0.0, 100), 0);
        assert_eq!(raw_from_percent(50.0, 100), 50);
        assert_eq!(raw_from_percent(100.0, 100), 100);
        assert_eq!(raw_from_percent(50.0, 255), 128);
        assert_eq!(raw_from_percent(-10.0, 100), 0);
        assert_eq!(raw_from_percent(150.0, 100), 100);
    }

    #[test]
    fn invalid_percent_is_rejected_before_touching_sysfs() {
        let service = BrightnessService::default();
        assert_eq!(
            service.set(f64::NAN).unwrap_err().code,
            oziro_protocol::error_codes::INVALID_PARAMS
        );
        assert_eq!(
            service.set(101.0).unwrap_err().code,
            oziro_protocol::error_codes::INVALID_PARAMS
        );
    }

    #[test]
    fn missing_device_is_reported_honestly() {
        let state = unavailable("none");
        assert!(!state.available);
        assert!(!state.supports_set);
        assert_eq!(state.percent, None);
    }
}
