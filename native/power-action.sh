#!/usr/bin/env bash
# Read-only capability probe or explicit, confirmed power action. Never force or elevate.
set -euo pipefail
fail() { printf "%s\n" "$*" >&2; exit 1; }
[[ $# -eq 1 ]] || fail "Expected --check or one action"
[[ $(id -u) -ne 0 ]] || fail "Do not run as root"
cap() {
  local result
  result="$(/usr/bin/busctl --timeout=5s --system --allow-interactive-authorization=no call org.freedesktop.login1 /org/freedesktop/login1 org.freedesktop.login1.Manager "$1" 2>/dev/null)" || { echo unavailable; return; }
  case "$result" in 's "yes"') echo yes;; 's "no"') echo no;; 's "challenge"') echo challenge;; 's "na"') echo na;; *) echo unavailable;; esac
}
context_ok() {
  [[ "${OZIRO_NESTED_PREVIEW:-}" != 1 && "${OZIRO_LOGIN_SESSION:-}" == 1 && -n "${XDG_SESSION_ID:-}" ]] || return 1
  [[ "$(timeout 5s loginctl show-session "$XDG_SESSION_ID" -p Active --value 2>/dev/null)" == yes ]] || return 1
  [[ "$(timeout 5s loginctl show-session "$XDG_SESSION_ID" -p User --value 2>/dev/null)" == "$(id -u)" ]]
}
logout_ok() {
  [[ -n "${NIRI_SOCKET:-}" && -S "$NIRI_SOCKET" ]] && timeout 5s /usr/bin/niri msg version >/dev/null 2>&1
}
if [[ "$1" == --check ]]; then
  if context_ok; then
    echo "Session: independent and active"
    if logout_ok; then echo "Logout: yes"; else echo "Logout: unavailable"; fi
    printf "Restart: %s\n" "$(cap CanReboot)"
    printf "Shutdown: %s\n" "$(cap CanPowerOff)"
  else
    echo "Session: preview or inactive (power actions disabled)"
    echo "Logout: no"; echo "Restart: no"; echo "Shutdown: no"
  fi
  exit 0
fi
context_ok || fail "Power actions require the active independent Oziro login"
case "$1" in
  logout) logout_ok || fail "Niri session IPC unavailable"; exec /usr/bin/niri msg action quit --skip-confirmation;;
  poweroff|reboot)
    method=PowerOff; [[ "$1" == reboot ]] && method=Reboot
    result="$(cap "Can$method")"; [[ "$result" == yes ]] || fail "logind permission: $result"
    exec /usr/bin/busctl --timeout=5s --system --allow-interactive-authorization=no call org.freedesktop.login1 /org/freedesktop/login1 org.freedesktop.login1.Manager "$method" b false;;
  *) fail "Unsupported action";;
esac
