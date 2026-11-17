//! Structured errors shared by all Oziro services.
//!
//! Every error carries a stable machine-readable code that the bridge maps
//! onto the frontend error envelope.

use oziro_protocol::error_codes;
use std::fmt;

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct OziroError {
    pub code: &'static str,
    pub message: String,
    pub retryable: bool,
}

impl OziroError {
    pub fn new(code: &'static str, message: impl Into<String>, retryable: bool) -> Self {
        Self { code, message: message.into(), retryable }
    }

    pub fn invalid_params(message: impl Into<String>) -> Self {
        Self::new(error_codes::INVALID_PARAMS, message, false)
    }

    pub fn service_unavailable(message: impl Into<String>) -> Self {
        Self::new(error_codes::SERVICE_UNAVAILABLE, message, true)
    }

    pub fn service_failed(message: impl Into<String>) -> Self {
        Self::new(error_codes::SERVICE_FAILED, message, false)
    }

    pub fn compositor_unavailable(message: impl Into<String>) -> Self {
        Self::new(error_codes::COMPOSITOR_UNAVAILABLE, message, true)
    }

    pub fn launch_failed(message: impl Into<String>) -> Self {
        Self::new(error_codes::LAUNCH_FAILED, message, false)
    }

    pub fn notification_unavailable(message: impl Into<String>) -> Self {
        Self::new(error_codes::NOTIFICATION_UNAVAILABLE, message, true)
    }

    pub fn settings_io(message: impl Into<String>) -> Self {
        Self::new(error_codes::SETTINGS_IO_FAILED, message, true)
    }

    pub fn internal(message: impl Into<String>) -> Self {
        Self::new(error_codes::INTERNAL, message, false)
    }
}

impl fmt::Display for OziroError {
    fn fmt(&self, formatter: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(formatter, "{}: {}", self.code, self.message)
    }
}

impl std::error::Error for OziroError {}

pub type OziroResult<T> = Result<T, OziroError>;

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn errors_carry_stable_codes() {
        let error = OziroError::compositor_unavailable("no compositor running");

        assert_eq!(error.code, "COMPOSITOR_UNAVAILABLE");
        assert!(error.retryable);
        assert_eq!(error.to_string(), "COMPOSITOR_UNAVAILABLE: no compositor running");
    }

    #[test]
    fn invalid_params_is_not_retryable() {
        assert!(!OziroError::invalid_params("bad").retryable);
        assert!(OziroError::service_unavailable("absent").retryable);
        assert!(OziroError::settings_io("io").retryable);
        assert!(!OziroError::service_failed("boom").retryable);
    }
}
