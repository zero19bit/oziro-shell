#!/usr/bin/env bash
# Explicit allowlisted controls; no sudo, eval, or credentials.
set -u
export LC_ALL=C
run() { timeout -k 1s 4s "$@" </dev/null; }
emit() { printf '%s=%s\n' "$1" "$2"; }
snapshot() {
  local wifi bluetooth light profile profiles
  wifi="$(run nmcli radio wifi 2>/dev/null)" || wifi=unavailable
  case "$wifi" in enabled|disabled) ;; *) wifi=unavailable;; esac
  emit wifi "$wifi"
  bluetooth="$(run bluetoothctl show 2>/dev/null)" || bluetooth=
  case "$bluetooth" in
    *'Powered: yes'*) emit bluetooth enabled;;
    *'Powered: no'*) emit bluetooth disabled;;
    *) emit bluetooth unavailable;;
  esac
  light="$(run brightnessctl -c backlight -m info 2>/dev/null)" || light=
  light="$(printf '%s\n' "$light" | awk -F, 'NR==1 && $4 ~ /^[0-9]+%$/ { sub(/%$/,"",$4); print $4 }')"
  if [[ "$light" =~ ^[0-9]{1,3}$ ]] && (( 10#$light <= 100 )); then emit brightness "$light"; else emit brightness unavailable; fi
  profile="$(run powerprofilesctl get 2>/dev/null)" || profile=unavailable
  case "$profile" in power-saver|balanced|performance) ;; *) profile=unavailable;; esac
  emit profile "$profile"
  if [[ "$profile" != unavailable ]]; then
    profiles="$(run powerprofilesctl list 2>/dev/null)" || profiles=
    printf '%s\n' "$profiles" | sed -nE 's/^[[:space:]*]*(power-saver|balanced|performance):[[:space:]]*$/available=\1/p'
  fi
}
action=status; value=
if (( $# > 2 )); then exit 2; fi
if (( $# >= 1 )); then action="$1"; fi
if (( $# >= 2 )); then value="$2"; fi
if [[ "$action" != status ]]; then
  [[ "${OZIRO_NESTED_PREVIEW:-}" != 1 ]] || { emit result failed; exit 3; }
  [[ $(id -u) -ne 0 ]] || { emit result failed; exit 3; }
fi
rc=0
case "$action" in
  status) [[ -z "$value" ]] || exit 2;;
  wifi) case "$value" in on|off) run nmcli radio wifi "$value" >/dev/null 2>&1 || rc=1;; *) exit 2;; esac;;
  bluetooth) case "$value" in on|off) run bluetoothctl power "$value" >/dev/null 2>&1 || rc=1;; *) exit 2;; esac;;
  brightness)
    [[ "$value" =~ ^[0-9]{1,3}$ ]] || exit 2
    (( 10#$value >= 5 && 10#$value <= 100 )) || exit 2
    run brightnessctl -c backlight set "$((10#$value))%" >/dev/null 2>&1 || rc=1;;
  profile)
    case "$value" in power-saver|balanced|performance) run powerprofilesctl set "$value" >/dev/null 2>&1 || rc=1;; *) exit 2;; esac;;
  *) exit 2;;
esac
snapshot
if ((rc)); then emit result failed; else emit result ok; fi
exit "$rc"
