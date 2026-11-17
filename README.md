# Oziro Desktop

Oziro is an independent Linux desktop environment, initially targeting Arch
Linux, Wayland, and Hyprland. KDE Plasma/KWin is also supported by the current
compositor adapter.

**Current milestone:** Phase 5 — Reliability and distribution  
**Current status:** Native shell implementation is in place; session
supervision and Arch packaging scaffolding have been added and need a clean
Arch installation/upgrade smoke test.

Oziro is not a theme or a configuration bundle. Its architecture separates
the graphical shell, system core, compositor adapters, and Linux service
integrations.

## Current implementation

- React + TypeScript frontend workspace
- Native shell host with GTK4 / WebKitGTK / GTK4 Layer Shell
- System service adapters for audio, network, Bluetooth, power, and brightness
- Compositor adapters for Hyprland and KWin
- Application catalog, launcher, favorites, and opaque icon tokens
- Notification integration with external-daemon detection
- Theme engine with optional liquid glass, blur, panel, and dock configuration
- Workspace and window activation where the compositor supports them
- Panel, dock, launcher, control center, settings, notifications, and overview
- Typed frontend/native bridge with request validation
- Preview adapter for development without the native host
- Unit tests and a combined verification script

## Native shell runtime

The native host:

- Creates Wayland layer-shell surfaces for the panel, dock, and popups
- Hosts the React bundle in WebKitGTK
- Integrates compositor adapters over native Hyprland IPC and verified KWin
  D-Bus capabilities
- Exposes system service state through typed WebKit script message handlers
- Serves the frontend only from a canonical local directory on loopback
- Serves opaque icon tokens instead of accepting arbitrary frontend paths
- Degrades to explicit unavailable states when backing services are absent

## Session recovery

The repository now includes a user-level systemd service with bounded
\`Restart=on-failure\` recovery. \`oziro-session-start\` imports the active Wayland
and compositor environment before starting the service.

- KDE Plasma receives an XDG autostart entry.
- Hyprland users can opt in with \`exec-once = oziro-session-start\`.
- Oziro does not rewrite any existing desktop configuration.
- The service runs as the logged-in user, never as root.

See [Arch installation and session recovery](docs/installation/arch.md) and
[ADR 0002](docs/architecture/decisions/0002-session-supervision.md).

## Requirements

- Node.js 20.19+ and npm
- Rust stable toolchain and Cargo 1.85+
- GTK4, WebKitGTK 6.0, GTK4 Layer Shell, libpulse, and D-Bus development
  libraries for native builds
- Arch Linux packages are listed in \`PKGBUILD\`

## Development quick start

~~~bash
npm ci
npm run build
scripts/run-native.sh
~~~

Run the full verification suite:

~~~bash
bash scripts/verify.sh
~~~

The verification script runs frontend typecheck/lint/tests/build, Rust
formatting/Clippy/tests/checks, and packaging metadata checks.

## Arch Linux package

A PKGBUILD is provided:

~~~bash
sudo pacman -S --needed base-devel git
git clone https://github.com/zero19bit/oziro-shell.git
cd oziro-shell
makepkg -si
~~~

See [docs/installation/arch.md](docs/installation/arch.md) for session
startup, recovery diagnostics, and uninstall instructions.

## Limitations and release gates

- System operations depend on their backing services (for example PipeWire,
  NetworkManager, BlueZ, and UPower).
- Unsupported compositor operations remain explicitly unsupported.
- Window close/minimize operations are not simulated when the compositor
  adapter does not support them.
- Notification history may be owned by an external desktop notification
  daemon and is not necessarily readable by Oziro.
- Panel/dock geometry remains compositor- and monitor-dependent.
- The Arch package has not yet passed a clean-machine install/upgrade smoke
  test. Do not treat the packaging scaffolding as a stable release yet.

A roadmap checkbox is complete only after implementation and verification,
not merely because code exists.
