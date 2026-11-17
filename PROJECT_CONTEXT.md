# Oziro Desktop
Project Context and Development Status

## 1. Vision

Oziro Desktop is a fully custom Linux Desktop Environment with its own visual
identity, interaction model, and system architecture.

It aims to provide:

- Excellent usability
- Practical user freedom and customization
- High performance and responsiveness
- Modern, consistent visual design

Liquid Glass and other visual effects remain optional.

## 2. Initial Platform

- Distribution: Arch Linux
- Architecture: x86_64
- Display protocol: Wayland
- Initial compositor target: Hyprland
- Additional current adapter: KDE Plasma/KWin

## 3. Technology Stack

- React and TypeScript frontend
- Rust native host and system services
- GTK4, WebKitGTK 6.0, and GTK4 Layer Shell
- D-Bus integrations
- Native Hyprland IPC and verified KWin D-Bus capabilities

## 4. Implemented Components

- Oziro Shell Host
- Oziro Dock and Panel
- Oziro Launcher and Overview
- Oziro Notification Center
- Oziro Control Center and Settings
- Oziro Core and shared protocol
- Application catalog and icon registry
- Audio, network, Bluetooth, power, and brightness service adapters
- Theme engine and preview/native frontend adapters
- User-level systemd supervision scaffolding
- Arch PKGBUILD and session launcher scaffolding
- Frontend and Arch-native CI workflow

## 5. Design Principles

- Original Oziro visual identity
- Optional Liquid Glass appearance
- Light and dark themes
- Customizable interface
- Purposeful animations
- Accessibility and reduced-motion support
- Performance-conscious rendering

## 6. Development Environment

The original development environment is Arch Linux with Node.js, npm, Rust,
Cargo, Wayland, and KDE Plasma available.

The repository is the source of truth for current code and build status.

## 7. Architecture Decisions

- Arch Linux is the initial packaging target.
- Wayland is the initial display protocol.
- Compositor-specific behavior stays behind the \`Compositor\` trait.
- The frontend never accesses hardware directly.
- Rust provides system integration.
- Oziro runs as the logged-in user, never as root.
- Existing desktop configurations are not edited automatically.
- A user-level systemd service provides bounded crash recovery.
- Packaged frontend assets are selected through \`OZIRO_FRONTEND_DIR\`.

See \`docs/architecture/decisions/0002-session-supervision.md\`.

## 8. Implementation Status

- [x] Phase 0 — Engineering Foundation
- [x] Phase 1 — Native Runtime Proof of Concept
- [x] Phase 2 — Compositor Adapter
- [x] Phase 3 — Shell MVP
- [x] Phase 4 — System Services
- [x] Phase 5 — Recovery and packaging scaffolding

Release validation is still pending:

- [ ] Clean Arch install, upgrade, uninstall, and rollback
- [ ] Real-session crash recovery on Hyprland and KDE
- [ ] Multi-monitor and session lifecycle smoke tests

Do not mark these release gates complete until they have been run on a real
Arch installation and their results have been recorded.
