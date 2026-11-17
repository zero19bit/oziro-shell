# Oziro Desktop

Oziro is an independent Linux desktop environment, initially targeting Arch Linux, Wayland, and Hyprland.

**Current milestone:** Phase 2 — Compositor Adapter  
**Current status:** Native shell integration completed; overview trigger added.

Oziro is not a theme or a configuration bundle. Its long-term architecture separates the graphical shell, system core, compositor adapters, and Linux service integrations.

## Current implementation

- React + TypeScript frontend workspace (version 0.2.0)
- Native shell host with GTK4 / WebKitGTK / GTK4 Layer Shell
- System service adapters (audio, network, Bluetooth, power, brightness)
- Compositor adapters (Hyprland, KWin with verified D-Bus capabilities)
- Icon and application catalog
- Notification integration with external-daemon detection
- Theme engine with liquid glass, blur, panel/dock configuration
- Workspace and window management (workspace switching, window activation)
- Pop-up surfaces (launcher, control center, settings, notifications, overview)
- Comprehensive tests and verification scripts
- Environment detection (Hyprland / KWin session)
- Honest unsupported state reporting

## Native shell runtime

The native host (`oziro-shell-host`) builds on the existing scaffolding and now:

- Provides a polished liquid glass panel and dock
- Integrates compositor adapters over native IPC (Hyprland) / verified D-Bus (KWin)
- Exposes system service state through WebKit script message handlers
- Hosts the React bundle for each surface (panel, dock, launcher, control center, settings, notifications, overview)
- Enforces request validation and allows only explicitly typed frontend calls
- Serves opaque icon tokens for safe frontend rendering
- Maintains a graceful degradation strategy when services are unavailable

A complete verification script (`scripts/verify.sh`) now runs and validates the entire workflow.

## Notable features

- UI work was delegated to an agent for components and routes.
- Shell integration replaces the old host with the new wiring, `runtime.rs`, `surfaces.rs`, `http.rs`, and transparent CSS.
- Custom `--oz-*` CSS custom properties replace literal values, enabling theme-driven adjustments.
- TopPanel now includes a WindowsGlyph button for opening the overview.
- Overview surface reports honest unsupported state when compositors are unavailable.
- System services politely degrade to an explicit "unavailable" state rather than inventing values.
- The icon registry is process-wide; apps, compositors, and the host all share the same opaque tokens.
- No arbitrary shell execution; all launching is through `std::process::Command` with strict Exec parsing.
- Reject on untrusted input: no traversal in HTTP, no malformed JSON in the bridge.
- All routes are fully typed: Rust domain types mirror the TypeScript protocol.

## Requirements

- Node.js 20.19+ (Node 26 is suitable)
- npm
- Rust stable toolchain and Cargo 1.85+
- Arch Linux development packages for GTK4, WebKitGTK 6.0, GTK4 Layer Shell, and D-Bus

## Quick start

```bash
npm install
npm run build

# Open the native shell with the current running desktop compositor (KWin / Hyprland)
cd ~/Projects/oziro-desktop && scripts/run-native.sh
```

Or run the combined verification suite:

```bash
cd ~/Projects/oziro-desktop && bash scripts/verify.sh
```

## Limitations and unsupported states

- System operations only exist when their backing service is actually present (e.g., PipeWire for audio, NetworkManager for networking).
- Hyprland is not running in the current development session; KWin is the detected compositor.
- Window close/minimize operations are unsupported on KWin (cannot be simulated).
- Notification history is owned by an external daemon (Plasma) and cannot be read.
- Height/position/length for panel/dock are configurable but not system-agnostic; validation is applied at load and on every update.
- No automatic dark/light detection; static user-configurable mode.

## Roadmap

Phase 3: Shell MVP complete (Panel, Dock, Launcher, Settings).
Phase 4: System services complete (Audio, Network, Bluetooth, Power, Brightness).
Phase 5: Notification Center, Overview, Multi-monitor behavior, Session recovery (in progress).

A checkbox is completed only after implementation and verification, not merely because code compiles.

See [ARCHITECTURE.md](ARCHITECTURE.md), [ROADMAP.md](ROADMAP.md), and [SECURITY.md](SECURITY.md).
