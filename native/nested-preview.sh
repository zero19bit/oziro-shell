#!/usr/bin/env bash
# Launch a separate development compositor window; not a security sandbox.
set -euo pipefail
dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
[[ $(id -u) -ne 0 ]] || { echo "Do not run as root"; exit 1; }
[[ -n "${WAYLAND_DISPLAY:-}" && -n "${XDG_RUNTIME_DIR:-}" ]] || { echo "Run inside your existing Wayland desktop"; exit 1; }
if [[ "$WAYLAND_DISPLAY" == /* ]]; then socket="$WAYLAND_DISPLAY"; else socket="$XDG_RUNTIME_DIR/$WAYLAND_DISPLAY"; fi
[[ -S "$socket" ]] || { echo "Host Wayland socket missing"; exit 1; }
for c in niri quickshell dbus-run-session; do command -v "$c" >/dev/null || { echo "Missing: $c"; exit 1; }; done
niri validate --config "$dir/nested-preview.kdl"
echo "Starting windowed Oziro preview. Close the outer Niri window to exit."
echo "No Ryoku configuration is modified. Preview preferences are temporary."
export OZIRO_NESTED_PREVIEW=1 OZIRO_NOTIFICATIONS=0 OZIRO_PANEL_ONLY=0 OZIRO_DISABLE_WALLPAPER=0
export NIRI_DISABLE_SYSTEM_MANAGER_NOTIFY=1 QT_QPA_PLATFORM=wayland
# Keep host Wayland display for winit, but remove host IPC target.
exec env -u NIRI_SOCKET -u HYPRLAND_INSTANCE_SIGNATURE -u NOTIFY_SOCKET dbus-run-session -- niri --config "$dir/nested-preview.kdl" -- quickshell -p "$dir"
