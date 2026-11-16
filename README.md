# Oziro Desktop

Oziro is an independent Linux desktop environment, initially targeting Arch Linux, Wayland, and Hyprland.

**Current milestone:** Phase 0 — Engineering Foundation  
**Current status:** Foundation scaffold; native desktop integration is not connected yet.

Oziro is not a theme or a configuration bundle. Its long-term architecture separates the graphical shell, system core, compositor adapters, and Linux service integrations.

## Current foundation

- React + TypeScript frontend workspace
- Rust workspace with a small executable and shared protocol types
- Explicit frontend adapter boundary
- Preview adapter that never pretends to report real system state
- Architecture, roadmap, security, and contribution documentation
- Basic automated tests, linting, and formatting configuration

## Requirements

- Node.js 20.19+ (Node 26 is suitable)
- npm
- Rust stable toolchain and Cargo
- Git

GTK4, WebKitGTK, GTK4 Layer Shell, D-Bus, and Hyprland integrations are intentionally not required to build this first foundation.

## Quick start

```bash
npm install
npm run dev
```

In another terminal:

```bash
cargo run -p oziro-core -- info
cargo test --workspace
```

Run frontend checks:

```bash
npm run typecheck
npm run lint
npm run test
npm run build
```

Run the combined verification script:

```bash
bash scripts/verify.sh
```

## Current limitations

- The UI runs as a browser-based preview, not as a Wayland desktop surface.
- The Rust executable is a foundation CLI, not yet a resident daemon.
- No hardware, network, audio, power, Bluetooth, or compositor state is read or changed.
- The protocol is typed and documented; a production transport is a later milestone.
- No system configuration is modified by this scaffold.

See [ARCHITECTURE.md](ARCHITECTURE.md), [ROADMAP.md](ROADMAP.md), and [SECURITY.md](SECURITY.md).
