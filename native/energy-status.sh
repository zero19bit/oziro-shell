#!/usr/bin/env bash
# Read-only service detection. Never starts or stops services.
set -u
export LC_ALL=C
for unit in power-profiles-daemon.service tuned-ppd.service tuned.service tlp.service auto-cpufreq.service system76-power.service; do
  state="$(timeout -k 1s 3s systemctl is-active "$unit" 2>/dev/null)" || true
  case "$state" in active|activating|reloading|inactive|failed|deactivating) ;; *) state=unknown;; esac
  printf '%s: %s\n' "$unit" "$state"
done
if command -v powerprofilesctl >/dev/null 2>&1; then
  profile="$(timeout -k 1s 4s powerprofilesctl get 2>/dev/null)" || profile=unavailable
  case "$profile" in power-saver|balanced|performance) ;; *) profile=unavailable;; esac
  printf 'System profile: %s\n' "$profile"
else
  printf 'System profile: powerprofilesctl missing\n'
fi
