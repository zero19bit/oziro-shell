# Oziro Architecture

## Principles

1. Keep compositor-specific behavior behind an adapter.
2. Keep Linux service access out of React components.
3. Treat all frontend input as untrusted.
4. Do not claim system state unless a real adapter supplied it.
5. Prefer event-driven updates over frequent polling.
6. Keep the initial process count low; split processes only for a concrete isolation or reliability reason.
7. Keep visual effects optional and respect reduced-motion preferences.

## High-level structure

```text
React UI (Surface, components, hooks)
  |
  | typed DesktopAdapter interface
  v
Frontend bridge boundary (WebKit script message handler `oziro`)
  |
  | versioned request/response protocol
  v
Rust Core
  |
  +-- oziro-protocol (shared types, envelopes, defaults)
  +-- oziro-services (apps, icons, settings, compositor, system, notifications)
  +-- oziro-shell-host (GTK surfaces, HTTP server, runtime dispatch)
```

## Current implementation boundary

The frontend selects an adapter:
- `PreviewDesktopAdapter`: explicitly reports preview mode and no native connection.
- `NativeDesktopAdapter`: wraps the host-provided `window.webkit.messageHandlers.oziro` API.

The Rust workspace provides:

- `oziro-protocol`: shared protocol concepts and Rust types.
- `oziro-core`: a small executable for foundation diagnostics.
- `oziro-services`: application catalog, compositor adapters, system integrations, notifications, settings, icons.
- `oziro-shell-host`: GTK4 layer-shell surfaces, WebKitGTK web views, local HTTP server, request dispatch.

## Native shell runtime

The intended Linux host is Rust + GTK4 + WebKitGTK 6.0. Wayland layer surfaces are evaluated through GTK4 Layer Shell where supported.

### Surfaces

| Surface | Type | Size | Notes |
| --- | --- | --- | --- |
| panel | layer top | full width, `panel_height + 14` | exclusive zone |
| dock | layer top | content + 24 px | bottom/left/right anchored |
| launcher | popup | 760 × 680 | below panel, left |
| control | popup | 420 × 560 | below panel, right |
| settings | popup | 420 × 560 | below panel, right |
| notifications | popup | 390 × 500 | bottom right |
| overview | overlay | fullscreen | explicit action |

All surfaces load the same bundle via `?surface=`.

### Compositor adapters

- `HyprlandAdapter`: native IPC over Unix sockets.
- `KWinAdapter`: D-Bus only, using verified capabilities.

Compositor operations are normalized behind the `Compositor` trait. Unsupported operations return errors — they are never simulated.

### System services

- Audio: `libpulse-binding` against `pipewire-pulse`.
- Network: NetworkManager D-Bus API.
- Bluetooth: BlueZ `ObjectManager` API.
- Power: UPower D-Bus API.
- Brightness: `/sys/class/backlight`.

Every module degrades to an explicit "unavailable" state instead of inventing values.

### Error model

The bridge returns structured errors with:

- stable machine-readable code
- safe human-readable message
- optional retryability
- no raw shell command execution

A disconnected service is a normal state, not a fatal application crash.

## Security

- All frontend input is validated at the bridge boundary.
- The HTTP server serves only files below the build directory.
- Icon tokens are opaque and restricted to an allowed alphabet.
- No arbitrary shell execution; launching uses `std::process::Command` with strict Exec parsing.
- No full-screen transparent surface ever blocks input.
- All GTK mutations happen on the main thread.