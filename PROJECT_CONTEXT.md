# Oziro Desktop
Project Context and Development Status

## 1. Vision

Oziro Desktop is a fully custom Linux Desktop Environment
with its own visual identity, interaction model and system architecture.

It aims to provide:

- Excellent usability
- Maximum practical user freedom
- High performance and responsiveness
- Modern and customizable aesthetics

Liquid Glass and other modern visual effects are optional.

## 2. Initial Platform

- Distribution: Arch Linux
- Architecture: x86_64
- Display protocol: Wayland
- Current development session: KDE Plasma (KWin)
- Initial target compositor: Hyprland

Hyprland is not currently running in the development session.

## 3. Technology Stack

Preferred technologies:

- React
- TypeScript
- Rust
- D-Bus
- Hyprland IPC

Technology choices must be documented before major implementation.

## 4. Implemented Components

- Oziro Shell Host (GTK4 + WebKitGTK + GTK4 Layer Shell)
- Oziro Dock
- Oziro Panel
- Oziro Launcher
- Oziro Overview
- Oziro Notification Center
- Oziro Control Center
- Oziro Settings
- Oziro Core
- Oziro System Services
- Oziro Theme Engine
- Oziro Hardware Integration

## 5. Design Principles

- Original Oziro visual identity
- Optional Liquid Glass appearance
- Light and dark themes
- Customizable interface
- Smooth and purposeful animations
- Accessibility
- Reduced-effects mode
- Performance-conscious rendering

## 6. Development Environment

Known installed tools:

- Arch Linux
- Git 2.56.0
- Node.js 26.13.0
- npm 12.2.2
- Rust 1.99.0
- Cargo 1.99.0
- Wayland
- KDE Plasma

Git repository initialized at:

~/Projects/oziro-desktop

Rust is managed through Arch Linux packages.
rustup was removed during package installation.

## 7. Architecture Decisions

Current decisions:

- Arch Linux is the initial development platform.
- Wayland is the initial display protocol.
- The compositor integration is isolated behind a `Compositor` trait.
- The frontend must not directly control hardware.
- Rust provides the system integration layer.
- Existing desktop configurations must remain untouched.

## 8. Implementation Status

- [x] Phase 0 — Engineering Foundation
- [x] Phase 1 — Native Runtime Proof of Concept
- [x] Phase 2 — Compositor Adapter
- [x] Phase 3 — Shell MVP (Panel, Dock, Launcher, Settings)
- [x] Phase 4 — System Services (Audio, Network, Bluetooth, Power, Brightness)
- [x] Phase 5 — Notification Center, Overview, Multi-monitor behavior

All phases implemented and verified via `scripts/verify.sh`.