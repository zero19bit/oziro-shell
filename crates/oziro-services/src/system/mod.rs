//! System integrations. Every module degrades to an explicit "unavailable"
//! state instead of inventing values; only the operations the backing service
//! actually exposes are implemented.

pub mod audio;
pub mod bluetooth;
pub mod brightness;
pub mod network;
pub mod power;
