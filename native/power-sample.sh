#!/usr/bin/env bash
# Whole-machine battery discharge estimate using energy_now. Read-only.
set -euo pipefail
export LC_ALL=C
duration=300
if (( $# == 1 )); then duration="$1"; elif (( $# > 1 )); then exit 2; fi
[[ "$duration" =~ ^[0-9]{2,4}$ ]] && (( 10#$duration >= 60 && 10#$duration <= 1800 )) || { echo "Usage: bash power-sample.sh [60..1800 seconds]" >&2; exit 2; }
duration=$((10#$duration))
batteries=()
for path in /sys/class/power_supply/*; do
  [[ -r "$path/type" && -r "$path/status" ]] || continue
  [[ $(cat "$path/type") == Battery ]] || continue
  if [[ -r "$path/scope" ]] && [[ $(cat "$path/scope") == Device ]]; then continue; fi
  if [[ -r "$path/present" ]] && [[ $(cat "$path/present") != 1 ]]; then continue; fi
  batteries+=("$path")
done
(( #batteries[@]} == 1 )) || { echo "Exactly one system battery required; no estimate produced" >&2; exit 1; }
battery="${batteries[0]}"
read_energy() {
  [[ $(cat "$battery/status") == Discharging ]] || { echo "Battery not discharging; sample invalid" >&2; return 1; }
  local value
  value="$(cat "$battery/energy_now" 2>/dev/null)" || { echo "energy_now unsupported" >&2; return 1; }
  [[ "$value" =~ ^[0-9]+$ ]] || return 1
  printf '%s\n' "$value"
}
read_time() { awk '{print $1}' /proc/uptime; }
start="$(read_energy)"; t0="$(read_time)"
printf 'Sampling %s for %s seconds. Keep workload and brightness unchanged.\n' "$(basename "$battery")" "$duration"
for ((elapsed=0;elapsed<duration;elapsed+=step)); do
  step=$(( duration-elapsed < 5 ? duration-elapsed : 5 ))
  sleep "$step"
  end="$(read_energy)"
done
t1="$(read_time)"
awk -v start="$start" -v end="$end" -v t0="$t0" -v t1="$t1" '
BEGIN {
  seconds=t1-t0; used=start-end;
  if(seconds<=0 || used<=0) {print "Energy decrease not measurable; repeat a longer run" > "/dev/stderr"; exit 1}
  printf "Elapsed: %.1f s; battery energy used: %.3f Wh; estimated whole-system average: %.2f W\n", seconds, used/1000000, (used/1000000)*3600/seconds
}'
