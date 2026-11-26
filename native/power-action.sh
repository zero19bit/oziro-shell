#!/usr/bin/env bash
# User-requested power actions only; no elevation or forced shutdown.
set -euo pipefail
fail() { printf "%s\n" "$*" >&2; exit 1; }
[[ $# -eq 1 ]] || fail "Expected one action"
[[ "${OZIRO_NESTED_PREVIEW:-}" != 1 ]] || fail "Power actions disabled in nested preview"
[[ "${OZIRO_LOGIN_SESSION:-}" == 1 ]] || fail "Power actions require the Oziro login session"
[[ $(id -u) -ne 0 ]] || fail "Do not run as root"
case "$1" in
  logout|poweroff|reboot) ;;
  *) fail "Unsupported action";;
esac
[[ -n "${XDG_SESSION_ID:-}" ]] || fail "No session ID"
[[ "$(loginctl show-session "$XDG_SESSION_ID" -p Active --value)" == yes ]] || fail "Session not active"
[[ "$(loginctl show-session "$XDG_SESSION_ID" -p User --value)" == "$(id -u)" ]] || fail "Session user mismatch"
case "$1" in
  logout)
    [[ -n "${NIRI_SOCKET:-}" && -S "$NIRI_SOCKET" ]] || fail "Niri session socket missing"
    exec /usr/bin/niri msg action quit --skip-confirmation
    ;;
  poweroff) exec /usr/bin/busctl --system --allow-interactive-authorization=no call org.freedesktop.login1 /org/freedesktop/login1 org.freedesktop.login1.Manager PowerOff b false;;
  reboot) exec /usr/bin/busctl --system --allow-interactive-authorization=no call org.freedesktop.login1 /org/freedesktop/login1 org.freedesktop.login1.Manager Reboot b false;;
esac
