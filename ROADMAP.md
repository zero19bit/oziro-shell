# Oziro Roadmap

## Phase 0 — Engineering Foundation

- [x] Establish frontend and Rust workspace layout
- [x] Define a versioned frontend/core protocol shape
- [x] Isolate preview and native adapters
- [x] Add basic tests, lint, formatting, and documentation
- [ ] Verify on the owner's Arch machine
- [ ] Generate and review the initial npm lockfile

## Phase 1 — Native Runtime Proof of Concept

- [ ] Confirm GTK4 / WebKitGTK / GTK4 Layer Shell build dependencies
- [ ] Build a minimal Rust GTK host
- [ ] Render the React UI inside WebKitGTK
- [ ] Create one real Wayland layer surface
- [ ] Validate startup, shutdown, and clean failure behavior
- [ ] Implement a narrow typed bridge

## Phase 2 — Compositor Adapter

- [ ] Define compositor capabilities and normalized events
- [ ] Implement Hyprland IPC adapter
- [ ] Add reconnect and timeout behavior
- [ ] Test workspaces, active window, monitors, and focus operations
- [ ] Keep unsupported operations explicit

## Phase 3 — Shell MVP

- [ ] Top Panel
- [ ] Dock
- [ ] Application Launcher
- [ ] Settings foundation
- [ ] Theme tokens and light/dark themes
- [ ] Low-effects mode

## Phase 4 — System Services

- [ ] D-Bus service boundary
- [ ] Audio via PipeWire / WirePlumber
- [ ] NetworkManager integration
- [ ] Bluetooth via BlueZ
- [ ] Power via UPower
- [ ] Notification integration

## Phase 5 — Reliability and Expansion

- [ ] Overview
- [ ] Notification Center
- [ ] Quick Settings
- [ ] Multi-monitor behavior
- [ ] Session recovery
- [ ] Performance and security review
- [ ] Arch packaging and upgrade strategy

A checkbox is completed only after implementation and verification, not merely because code compiles.
