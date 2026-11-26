# Oziro v2 — native feasibility prototype

Status: experimental, not a release. No changes to the existing Rust/React application or host configuration.

## Run
Requires an active Hyprland Wayland session and Quickshell 0.3.x with Hyprland and PipeWire integrations. Run from this repository:
```sh
bash native/doctor.sh
quickshell -p "$PWD/native"
```
Do not run as root. Stop with Ctrl+C. Existing panels may compete for reserved space; temporarily stop your other panel manually if necessary. No autostart or installer is included.

## Implemented in source
- One panel per detected screen, with a live screen model.
- Monitor-specific workspace buttons and real workspace activation.
- Live clock, default PipeWire sink volume and mute toggle; unavailable state.
- Reusable button and a provisional dark/cyan visual direction.

## Not verified
The prototype has not been run on a Hyprland session in the authoring environment. Validate with two monitors, hotplug, workspace changes, default audio device changes, and no audio service. No dock, launcher, notifications, lock screen, packaging or performance guarantee yet.

## Architecture proposal
Quickshell/QML for Wayland surfaces and native integrations. Keep Rust for features that actually need an independent service. No local HTTP transport is required for this prototype. Any future daemon must use a user-owned Unix socket, validate peer identity and typed operations, and avoid handling login credentials itself. Use an audited session locker/PAM and OS-native authorization for privileged actions. Never save secrets in ordinary configuration. UI and services should report unavailable rather than fake success.

The native approach is a hypothesis to validate before replacing the current implementation. Final theme, target compositors, settings schema, installation and licensing must be decided before shipping.
