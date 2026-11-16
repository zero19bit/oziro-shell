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
React UI
  |
  | typed DesktopAdapter interface
  v
Frontend bridge boundary
  |
  | versioned request/response protocol
  v
Rust Core
  |
  +-- Configuration
  +-- Capability registry
  +-- Compositor API
  |     +-- Hyprland adapter (future)
  |     +-- Other compositor adapters (future)
  |
  +-- Linux service adapters (future)
        +-- D-Bus services
        +-- Audio / Network / Power / Bluetooth
```

## Current implementation boundary

The frontend selects an adapter:
- `PreviewDesktopAdapter`: explicitly reports preview mode and no native connection.
- `NativeDesktopAdapter`: wraps the future host-provided `window.oziroBridge` API.

The Rust workspace currently provides:
- `oziro-protocol`: shared protocol concepts and Rust types.
- `oziro-core`: a small executable for foundation diagnostics.

There is no production IPC transport yet. The transport will be selected after the native host proof-of-concept, rather than prematurely coupling the UI to a particular IPC mechanism.

## Native shell direction

The intended Linux host is Rust + GTK4 + WebKitGTK 6.0. Wayland layer surfaces will be evaluated through GTK4 Layer Shell where supported. This dependency is not part of the current browser preview build.

Hyprland communication belongs in a dedicated adapter. The rest of Oziro must not depend on Hyprland socket paths, event names, or command syntax.

## Error model

The future bridge must return structured errors with:
- stable machine-readable code
- safe human-readable message
- optional retryability
- no raw shell command execution

A disconnected service is a normal state, not a fatal application crash.
