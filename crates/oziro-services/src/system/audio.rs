//! Audio through PulseAudio's client library, which on the target platform is
//! served by `pipewire-pulse`. Only the default output sink is exposed.

use crate::error::{OziroError, OziroResult};
use libpulse_binding as pulse;
use oziro_protocol::AudioState;
use pulse::callbacks::ListResult;
use pulse::context::{Context, FlagSet, State};
use pulse::mainloop::standard::{IterateResult, Mainloop};
use pulse::operation::{Operation, State as OperationState};
use pulse::volume::{ChannelVolumes, Volume, VolumeLinear};
use std::cell::RefCell;
use std::rc::Rc;

fn unavailable(reason: impl Into<String>) -> AudioState {
    AudioState {
        available: false,
        unavailable_reason: Some(reason.into()),
        volume: None,
        muted: None,
        sink_name: None,
        sink_description: None,
    }
}

fn pulse_error(context: &str, error: impl std::fmt::Display) -> OziroError {
    OziroError::service_unavailable(format!("{context}: {error}"))
}

/// A connected PulseAudio context plus the mainloop driving it.
struct Session {
    mainloop: Mainloop,
    context: Context,
}

impl Session {
    fn connect() -> OziroResult<Self> {
        let mainloop = Mainloop::new()
            .ok_or_else(|| OziroError::service_unavailable("PulseAudio mainloop unavailable"))?;

        let mut context = Context::new(&mainloop, "Oziro Desktop")
            .ok_or_else(|| OziroError::service_unavailable("PulseAudio context unavailable"))?;

        // Never autospawn a second sound server; absent PipeWire is a normal state.
        context
            .connect(None, FlagSet::NOAUTOSPAWN, None)
            .map_err(|error| pulse_error("PulseAudio connect", error))?;

        let mut session = Self { mainloop, context };
        session.wait_ready()?;
        Ok(session)
    }

    fn wait_ready(&mut self) -> OziroResult<()> {
        loop {
            match self.context.get_state() {
                State::Ready => return Ok(()),
                State::Failed | State::Terminated => {
                    return Err(OziroError::service_unavailable("PulseAudio connection failed"));
                }
                _ => self.iterate()?,
            }
        }
    }

    fn iterate(&mut self) -> OziroResult<()> {
        match self.mainloop.iterate(true) {
            IterateResult::Success(_) => Ok(()),
            IterateResult::Quit(_) => {
                Err(OziroError::service_unavailable("PulseAudio mainloop quit unexpectedly"))
            }
            IterateResult::Err(error) => Err(pulse_error("PulseAudio mainloop", error)),
        }
    }

    fn wait_operation<C: ?Sized>(&mut self, operation: &Operation<C>) -> OziroResult<()> {
        loop {
            match operation.get_state() {
                OperationState::Running => self.iterate()?,
                OperationState::Done | OperationState::Cancelled => return Ok(()),
            }
        }
    }

    fn default_sink(&mut self) -> OziroResult<DefaultSink> {
        let default_name = Rc::new(RefCell::new(None::<String>));

        {
            let introspector = self.context.introspect();
            let slot = Rc::clone(&default_name);
            let operation = introspector.get_server_info(move |info| {
                if let Some(name) = &info.default_sink_name {
                    *slot.borrow_mut() = Some(name.to_string());
                }
            });

            self.wait_operation(&operation)?;
        }

        let name = default_name
            .borrow_mut()
            .take()
            .ok_or_else(|| OziroError::service_unavailable("No default audio sink"))?;

        let sink = Rc::new(RefCell::new(None::<DefaultSink>));

        {
            let introspector = self.context.introspect();
            let slot = Rc::clone(&sink);
            let operation = introspector.get_sink_info_by_name(&name, move |result| {
                if let ListResult::Item(info) = result {
                    let channels = info.volume.get();
                    let average = if channels.is_empty() {
                        0.0
                    } else {
                        channels.iter().map(|volume| VolumeLinear::from(*volume).0).sum::<f64>()
                            / channels.len() as f64
                    };

                    *slot.borrow_mut() = Some(DefaultSink {
                        index: info.index,
                        name: info.name.as_ref().map(ToString::to_string),
                        description: info.description.as_ref().map(ToString::to_string),
                        volume: (average * 100.0).clamp(0.0, 100.0),
                        muted: info.mute,
                        channels: info.volume.len(),
                    });
                }
            });

            self.wait_operation(&operation)?;
        }

        sink.borrow_mut().take().ok_or_else(|| {
            OziroError::service_unavailable(format!("Audio sink `{name}` not found"))
        })
    }

    fn set_volume(&mut self, sink: &DefaultSink, percent: f64) -> OziroResult<()> {
        let mut volumes = ChannelVolumes::default();
        volumes.set(sink.channels.max(1), Volume::from(VolumeLinear(percent / 100.0)));

        let mut introspector = self.context.introspect();
        let operation = introspector.set_sink_volume_by_index(sink.index, &volumes, None);
        self.wait_operation(&operation)
    }

    fn set_muted(&mut self, sink: &DefaultSink, muted: bool) -> OziroResult<()> {
        let mut introspector = self.context.introspect();
        let operation = introspector.set_sink_mute_by_index(sink.index, muted, None);
        self.wait_operation(&operation)
    }
}

struct DefaultSink {
    index: u32,
    name: Option<String>,
    description: Option<String>,
    volume: f64,
    muted: bool,
    channels: u8,
}

fn state_from(sink: &DefaultSink) -> AudioState {
    AudioState {
        available: true,
        unavailable_reason: None,
        volume: Some((sink.volume * 10.0).round() / 10.0),
        muted: Some(sink.muted),
        sink_name: sink.name.clone(),
        sink_description: sink.description.clone(),
    }
}

/// Snapshot of the default output sink.
pub fn get() -> AudioState {
    let mut session = match Session::connect() {
        Ok(session) => session,
        Err(error) => return unavailable(error.message),
    };

    match session.default_sink() {
        Ok(sink) => state_from(&sink),
        Err(error) => unavailable(error.message),
    }
}

/// Sets the default sink volume (0–100). The value is validated here even
/// though the frontend also clamps it.
pub fn set_volume(percent: f64) -> OziroResult<AudioState> {
    if !percent.is_finite() || !(0.0..=100.0).contains(&percent) {
        return Err(OziroError::invalid_params("volume must be between 0 and 100"));
    }

    let mut session = Session::connect()?;
    let sink = session.default_sink()?;
    session.set_volume(&sink, percent)?;

    // Re-read instead of assuming the daemon applied the value verbatim.
    let sink = session.default_sink()?;
    Ok(state_from(&sink))
}

/// Sets the default sink mute switch.
pub fn set_muted(muted: bool) -> OziroResult<AudioState> {
    let mut session = Session::connect()?;
    let sink = session.default_sink()?;
    session.set_muted(&sink, muted)?;

    let sink = session.default_sink()?;
    Ok(state_from(&sink))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn invalid_volume_is_rejected_before_connecting() {
        assert_eq!(set_volume(-1.0).unwrap_err().code, oziro_protocol::error_codes::INVALID_PARAMS);
        assert_eq!(
            set_volume(101.0).unwrap_err().code,
            oziro_protocol::error_codes::INVALID_PARAMS
        );
        assert_eq!(
            set_volume(f64::NAN).unwrap_err().code,
            oziro_protocol::error_codes::INVALID_PARAMS
        );
    }

    #[test]
    fn volume_mapping_roundtrips_through_linear_values() {
        for percent in [0.0, 25.0, 50.0, 75.0, 100.0] {
            let volume = Volume::from(VolumeLinear(percent / 100.0));
            let linear = VolumeLinear::from(volume).0;
            assert!((linear * 100.0 - percent).abs() < 0.01);
        }
    }

    #[test]
    fn unavailable_state_never_carries_invented_values() {
        let state = unavailable("no server");
        assert!(!state.available);
        assert_eq!(state.volume, None);
        assert_eq!(state.muted, None);
        assert_eq!(state.sink_name, None);
    }
}
