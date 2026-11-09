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
- Current development session: KDE Plasma
- Initial target compositor: Hyprland

Hyprland is not currently running in the development session.

## 3. Technology Stack

Preferred technologies:

- React
- TypeScript
- Rust
- D-Bus
- Hyprland IPC

The final frontend runtime and shell architecture
are not yet finalized.

Technology choices must be documented before major implementation.

## 4. Planned Components

- Oziro Shell
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

These are planned components, not completed features.

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
- Hyprland is the initial compositor target.
- The compositor integration should be isolated.
- The frontend must not directly control hardware.
- Rust will provide the system integration layer.
- Existing desktop configurations must remain untouched.

Unresolved decisions:

- Frontend runtime
- IPC architecture
- Shell process model
- Theme engine implementation
- Component communication contracts

## 8. Completed Work

- [x] Arch Linux environment inspected
- [x] Git available
- [x] Node.js and npm available
- [x] Rust and Cargo available
- [x] Project directory created
- [x] Git repository initialized
- [x] Initial documentation files created

## 9. Known Limitations

- Hyprland is not currently running.
- No Oziro components have been implemented.
- No compositor integration has been tested.
- No frontend or Rust application exists yet.

## 10. Current Development Phase

Phase 0: Project Foundation

Current task:
Finalize architecture and repository structure.

## 11. Roadmap

Phase 0:
- Architecture design
- Repository structure
- Development conventions
- Technical feasibility review

Phase 1:
- Minimal Oziro Shell
- Basic desktop surface
- Dock
- Application launcher

Phase 2:
- Hyprland integration
- Workspace and window management
- Notifications

Phase 3:
- Oziro Settings
- Control Center
- System services

Phase 4:
- Theme engine
- Liquid Glass
- Animation system
- Accessibility

Phase 5:
- Performance optimization
- Reliability testing
- Installation and packaging
- Oziro OS ISO

## 12. Next Tasks

1. Review the overall architecture.
2. Select the frontend runtime.
3. Define IPC contracts.
4. Design the monorepo structure.
5. Establish the MVP scope.

## 13. Project Rules

Never mark a feature complete without testing.

Never confuse a prototype with production functionality.

Update this document after every major milestone.
