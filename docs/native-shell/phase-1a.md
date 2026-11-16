# Phase 1A — Native GTK4 + WebKitGTK Host

## Scope

This milestone adds a real Rust/GTK4 application window and embeds the existing React production build in WebKitGTK 6.0.

It is intentionally a normal application window. It does not yet create a Wayland layer surface.

## Dependencies

- GTK4 development files
- WebKitGTK 6.0 development files
- Rust and Cargo

The current Arch environment audit already found GTK4 and WebKitGTK 6.0 installed. GTK4 Layer Shell is not installed, so this milestone deliberately does not depend on it.

Rust bindings are pinned to:
- `gtk4 = 0.11.5`
- `webkit6 = 0.6.1`

The GTK4 `v4_10` feature is enabled explicitly because WebKitGTK 6 bindings use GTK accessibility interfaces gated by that GTK feature in some crate builds.

## Run

From the repository root:

```bash
scripts/run-native.sh
```

The script:
1. Checks that `gtk4` and `webkitgtk-6.0` are visible through pkg-config.
2. Builds the React frontend.
3. Starts the native GTK application.

The host loads only the local generated file `frontend/shell-ui/dist/index.html`. It does not load arbitrary remote URLs.

## Honest capability status

Implemented by this milestone:
- Native GTK4 application window
- Embedded WebKitGTK 6.0 WebView
- Loading the local React production bundle
- Clear fallback page if the bundle is missing

Not implemented yet:
- WebKit-to-Rust request/reply bridge
- D-Bus integration
- Hyprland IPC
- Layer Shell anchoring
- Dock or panel as compositor-managed surfaces
- Session startup or system service installation

The UI will continue to report that live system integration is not connected. This is intentional.

## Why Layer Shell is deferred

The GTK4 Layer Shell Rust crate requires the native `gtk4-layer-shell` C library at build and runtime. It is not present in the audited system. We do not install system packages or alter the user's environment without permission.

The next sub-milestone will add the Layer Shell dependency after the native library is installed and verified.
