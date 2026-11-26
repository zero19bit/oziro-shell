#!/usr/bin/env bash
set -u
failed=0
check() {
  if command -v "$1" >/dev/null 2>&1; then printf 'OK: %s\n' "$1"; else printf 'MISSING: %s\n' "$1"; failed=1; fi
}
check quickshell
if [[ "${XDG_SESSION_TYPE:-}" == wayland && -n "${WAYLAND_DISPLAY:-}" ]]; then
  echo 'OK: Wayland session'
else
  echo 'MISSING: active Wayland session'; failed=1
fi
if [[ -n "${NIRI_SOCKET:-}" && -S "$NIRI_SOCKET" ]]; then
  check niri
  if command -v niri >/dev/null 2>&1 && timeout 5 niri msg --json workspaces >/dev/null 2>&1; then
    echo 'OK: Niri command socket responds'
  else
    echo 'FAILED: Niri command probe'; failed=1
  fi
elif [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" && -n "${XDG_RUNTIME_DIR:-}" && -S "${XDG_RUNTIME_DIR}/hypr/${HYPRLAND_INSTANCE_SIGNATURE}/.socket.sock" ]]; then
  if command -v hyprctl >/dev/null 2>&1 && timeout 5 hyprctl -j monitors >/dev/null 2>&1; then
    echo 'OK: Hyprland command socket responds'
  else
    echo 'FAILED: Hyprland command probe'; failed=1
  fi
else
  echo 'MISSING: active Niri or Hyprland IPC socket'; failed=1
fi
if command -v wpctl >/dev/null 2>&1 && wpctl status >/dev/null 2>&1; then
  echo 'OK: WirePlumber responds'
else
  echo 'OPTIONAL: audio service unavailable or wpctl missing'
fi
for tool in nmcli bluetoothctl brightnessctl powerprofilesctl; do
  if command -v "$tool" >/dev/null 2>&1; then echo "OK: optional $tool"; else echo "OPTIONAL: $tool missing"; fi
done
exit "$failed"
