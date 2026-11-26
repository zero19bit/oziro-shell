#!/usr/bin/env bash
# Explicit manual lock only. Never modifies PAM or idle settings.
set -euo pipefail
dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
fail() { printf "FAIL: %s\n" "$*" >&2; exit 1; }
[[ "${OZIRO_NESTED_PREVIEW:-}" != 1 ]] || fail "Lock disabled in nested preview"
[[ $# -eq 1 ]] || fail "Use --check or --lock"
case "$1" in --check|--lock) ;; *) fail "Unknown action";; esac
[[ $(id -u) -ne 0 ]] || fail "Run as the desktop user, not root"
[[ -n "${WAYLAND_DISPLAY:-}" && -n "${XDG_RUNTIME_DIR:-}" ]] || fail "Wayland environment missing"
if [[ "$WAYLAND_DISPLAY" == /* ]]; then socket="$WAYLAND_DISPLAY"; else socket="$XDG_RUNTIME_DIR/$WAYLAND_DISPLAY"; fi
[[ -S "$socket" ]] || fail "Wayland socket not found"
[[ -x /usr/bin/hyprlock ]] || fail "Hyprlock is not installed at /usr/bin/hyprlock"
[[ -s /etc/pam.d/hyprlock && -r /etc/pam.d/hyprlock ]] || fail "Hyprlock PAM configuration missing or unreadable"
[[ -s "$dir/oziro-lock.conf" && -r "$dir/oziro-lock.conf" ]] || fail "Oziro lock configuration missing"
command -v pgrep >/dev/null || fail "pgrep unavailable"
if pgrep -u "$(id -u)" -x hyprlock >/dev/null; then fail "Hyprlock already running"; fi
if [[ "$1" == --check ]]; then
  printf "PASS: Hyprlock, PAM file, local config and Wayland socket present\n"
  printf "NOTE: No lock attempted; authentication and compositor support are unverified\n"
  exit 0
fi
exec /usr/bin/hyprlock --config "$dir/oziro-lock.conf" --grace 0
