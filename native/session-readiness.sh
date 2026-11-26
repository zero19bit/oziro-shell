#!/usr/bin/env bash
# Read-only host inventory. Does not start, install, stop or enable anything.
set -u
export LC_ALL=C
dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)" || exit 1
echo "=== Oziro login session readiness ==="
echo "Display manager:"
systemctl show display-manager.service -p Id -p ActiveState -p FragmentPath --no-pager 2>/dev/null || true
echo "Available login session entries:"
for d in /usr/share/wayland-sessions /usr/local/share/wayland-sessions; do
  [[ -d "$d" ]] || continue
  for entry in "$d"/*.desktop; do
    [[ -f "$entry" ]] || continue
    printf "%s\n" "$entry"
    grep -E "^(Name|Exec|TryExec|DesktopNames)=" "$entry" || true
  done
done
echo "Required executable paths:"
fail=0
for cmd in niri quickshell hyprlock; do
  if path="$(command -v "$cmd")"; then printf "OK: %s\n" "$path"; else echo "MISSING: $cmd"; fail=1; fi
done
echo "Optional session tools:"
for cmd in niri-session dbus-run-session xdg-desktop-portal xwayland-satellite foot kitty alacritty ghostty konsole xfce4-terminal; do
  if path="$(command -v "$cmd")"; then printf "OK: %s\n" "$path"; fi
done
echo "Active relevant user units:"
systemctl --user list-units --type=service --state=running --no-legend --no-pager 2>/dev/null | awk '$1 ~ /ryoku|niri|quickshell|portal|pipewire|wireplumber|idle|polkit/ {print $1}' || true
echo "Configured relevant user units:"
systemctl --user list-unit-files --type=service --no-legend --no-pager 2>/dev/null | awk '$1 ~ /ryoku|niri|quickshell|portal|pipewire|wireplumber|idle|polkit/ {print $1,$2}' || true
echo "Candidate Niri config validation:"
if command -v niri >/dev/null && niri validate --config "$dir/session-candidate.kdl"; then echo "PASS: candidate config"; else echo "FAIL: candidate config"; fail=1; fi
if ((fail)); then echo "READINESS: prerequisite issues"; else echo "READINESS: inventory complete (not a login test)"; fi
exit "$fail"
