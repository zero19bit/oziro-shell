# Oziro Roadmap

## Phase 0 — Engineering Foundation

- [x] Establish frontend and Rust workspace layout
- [x] Define a versioned frontend/core protocol shape
- [x] Isolate preview and native adapters
- [x] Add basic tests, lint, formatting, and documentation
- [x] Verify on the owner's Arch machine
- [x] Generate and review the initial npm lockfile

## Phase 1 — Native Runtime Proof of Concept

- [x] Confirm GTK4 / WebKitGTK / GTK4 Layer Shell build dependencies
- [x] Build a minimal Rust GTK host
- [x] Render the React UI inside WebKitGTK
- [x] Create one real Wayland layer surface
- [x] Validate startup, shutdown, and clean failure behavior
- [x] Implement a narrow typed bridge

## Phase 2 — Compositor Adapter

- [x] Define compositor capabilities and normalized events
- [x] Implement Hyprland IPC adapter
- [x] Add reconnect and timeout behavior
- [x] Test workspaces, active window, monitors, and focus operations
- [x] Keep unsupported operations explicit

## Phase 3 — Shell MVP

- [x] Top Panel
- [x] Dock
- [x] Application Launcher
- [x] Settings foundation
- [x] Theme tokens and light/dark themes
- [x] Low-effects mode

## Phase 4 — System Services

- [x] D-Bus service boundary
- [x] Audio via PipeWire / WirePlumber
- [x] NetworkManager integration
- [x] Bluetooth via BlueZ
- [x] Power via UPower
- [x] Notification integration

## Phase 5 — Reliability and Expansion

- [x] Overview
- [x] Notification Center
- [x] Quick Settings
- [x] Multi-monitor behavior
- [ ] Session recovery
- [x] Performance and security review
- [ ] Arch packaging and upgrade strategy

A checkbox is completed only after implementation and verification, not merely because code compiles.