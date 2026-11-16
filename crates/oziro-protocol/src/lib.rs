//! Shared, transport-independent types for communication between Oziro UI and Rust.

pub const PROTOCOL_VERSION: u16 = 1;

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum IntegrationState {
    NotConnected { reason: String },
    Connected { adapter: String },
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct RuntimeInfo {
    pub protocol_version: u16,
    pub app_name: String,
    pub app_version: String,
    pub integration: IntegrationState,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct RequestEnvelope {
    pub protocol_version: u16,
    pub request_id: String,
    pub method: String,
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn protocol_version_is_explicit() {
        assert_eq!(PROTOCOL_VERSION, 1);
    }

    #[test]
    fn disconnected_state_carries_a_reason() {
        let state = IntegrationState::NotConnected { reason: "not implemented".to_owned() };

        assert_eq!(state, IntegrationState::NotConnected { reason: "not implemented".to_owned() });
    }
}
