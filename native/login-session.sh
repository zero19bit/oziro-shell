#!/usr/bin/env bash
# Experimental real login; never launch from an existing graphical desktop.
set -euo pipefail
dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
fail() { printf "Oziro session: %s\n" "$*" >&2; exit 2; }
[[ $(id -u) -ne 0 ]] || fail "Do not run as root"
[[ -n "${XDG_RUNTIME_DIR:-}" && -d "$XDG_RUNTIME_DIR" ]] || fail "Missing runtime directory"
[[ -n "${XDG_SESSION_ID:-}" ]] || fail "No logind session ID"
[[ "$(loginctl show-session "$XDG_SESSION_ID" -p Active --value 2>/dev/null)" == yes ]] || fail "Session is not foreground"
[[ "$(loginctl show-session "$XDG_SESSION_ID" -p Type --value 2>/dev/null)" == wayland ]] || fail "Expected a Wayland login"
# Fail closed rather than stopping another desktop or its lock/idle services.
systemctl --user show-environment >/dev/null 2>&1 || fail "User service manager unavailable"
for unit in niri.service ryoku-session.target ryoku-shell.service ryoku-idle.service; do
  state="$(systemctl --user show "$unit" -p ActiveState --value 2>/dev/null)" || fail "Cannot check $unit"
  case "$state" in inactive|failed) ;; *) fail "$unit state: $state; return to the existing session";; esac
done
for path in /usr/bin/niri /usr/bin/quickshell /usr/bin/kitty /usr/bin/dbus-run-session; do [[ -x "$path" ]] || fail "Missing $path"; done
/usr/bin/niri validate --config "$dir/session-candidate.kdl" || fail "Invalid compositor config"
# Do not export the new display to the shared systemd user manager.
export OZIRO_LOGIN_SESSION=1 OZIRO_NESTED_PREVIEW=0 OZIRO_NOTIFICATIONS=0 OZIRO_PANEL_ONLY=0 OZIRO_DISABLE_WALLPAPER=0
export XDG_CURRENT_DESKTOP=Oziro XDG_SESSION_DESKTOP=Oziro QT_QPA_PLATFORM=wayland NIRI_DISABLE_SYSTEM_MANAGER_NOTIFY=1
echo "Oziro experimental login starting (no idle/suspend integration)" >&2
exec /usr/bin/env -u WAYLAND_DISPLAY -u WAYLAND_SOCKET -u DISPLAY -u NIRI_SOCKET -u HYPRLAND_INSTANCE_SIGNATURE -u NOTIFY_SOCKET -u RYOKU_POLKIT_AGENT -u QML_IMPORT_PATH -u QML2_IMPORT_PATH -u QT_QPA_PLATFORMTHEME -u DBUS_SESSION_BUS_ADDRESS /usr/bin/dbus-run-session -- /usr/bin/niri --config "$dir/session-candidate.kdl" -- /usr/bin/quickshell -p "$dir"
