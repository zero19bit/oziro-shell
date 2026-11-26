#!/usr/bin/env bash
# Read-only release preflight. No services or desktop settings are modified.
set -u
export LC_ALL=C
dir="$(cd -- "$(dirname -- "$0")" && pwd -P)" || exit 1
fail=0
echo '=== Oziro release preflight ==='
if command -v git >/dev/null 2>&1; then
  git -C "$dir" rev-parse --short HEAD 2>/dev/null || true
fi
if command -v quickshell >/dev/null 2>&1; then
  timeout 5 quickshell --version 2>&1 || echo 'NOTE: version query unavailable'
fi
echo '=== Source inventory and shell syntax ==='
for f in shell.qml Chip.qml PanelChip.qml AccentSlider.qml SectionLabel.qml QuickToggle.qml Preferences.qml NiriBackend.qml WindowModel.js Dock.qml DockIcon.qml TopBar.qml Launcher.qml ControlCenter.qml ThemeStudio.qml WallpaperPolicy.js WallpaperCenter.qml WallpaperSurface.qml EnergyEngine.qml EnergyPolicy.js EnergyCenter.qml WidgetRegistry.js WidgetCenter.qml energy-status.sh power-sample.sh SystemControls.qml system-controls.sh NotificationBackend.qml NotificationCenter.qml NotificationToast.qml notification-test.sh doctor.sh benchmark.sh measure.sh preflight.sh; do
  if [[ ! -s "$dir/$f" ]]; then echo "FAIL: missing $f"; fail=1; fi
done
for f in "$dir"/*.sh; do
  if bash -n "$f"; then echo "PASS: $(basename "$f") syntax"; else fail=1; fi
done
# Narrow regression guard for the known QML imported-script parsing failure.
if grep -nE '\{[[:space:]]*\.\.\.' "$dir"/*.js; then
  echo 'FAIL: object spread in imported script'; fail=1
else
  echo 'PASS: no same-line object spread in imported scripts'
fi
echo '=== Live environment ==='
if timeout 20 bash "$dir/doctor.sh"; then echo 'PASS: doctor'; else echo 'FAIL: doctor'; fail=1; fi
if command -v busctl >/dev/null 2>&1; then
  timeout 5 busctl --system get-property org.freedesktop.UPower /org/freedesktop/UPower org.freedesktop.UPower OnBattery || echo 'NOTE: UPower state unavailable'
fi
echo '=== Oziro process memory snapshot ==='
matches=()
for proc in /proc/[0-9]*; do
  [[ -r "$proc/cmdline" ]] || continue
  args=()
  mapfile -d '' -t args < "$proc/cmdline" 2>/dev/null || continue
  (( ${#args[@]} >= 3 )) || continue
  exe="$(readlink "$proc/exe" 2>/dev/null)" || continue
  [[ "$(basename -- "$exe")" == quickshell || "$(basename -- "$exe")" == qs ]] || continue
  for ((i=1;i+1<${#args[@]};i++)); do
      if [[ "${args[i]}" == -p || "${args[i]}" == --path ]]; then
        candidate="${args[i+1]}"
        if [[ "$candidate" == "$dir" || "$candidate" == "$dir/shell.qml" ]]; then
          matches+=("${proc##*/}"); break
        fi
      fi
  done
done
if (( ${#matches[@]} == 1 )); then
  pid="${matches[0]}"
  echo "Oziro PID: $pid"
  # Snapshot process tree from a single ps listing, excluding unrelated Ryoku processes.
  members="$(ps -eo pid=,ppid= | awk -v root="$pid" '{p[$1]=$2} END {seen[root]=1; do {changed=0;for(i in p)if(seen[p[i]]&&!seen[i]){seen[i]=1;changed=1}}while(changed);for(i in seen)if(seen[i])print i}')"
  total=0; missing=0
  for member in $members; do
    value="$(awk '/^Pss:/{print $2; found=1} END{if(!found)exit 1}' "/proc/$member/smaps_rollup" 2>/dev/null)" || { missing=1; continue; }
    [[ "$value" =~ ^[0-9]+$ ]] || { missing=1; continue; }
    total=$((total+value))
    printf 'PID %s PSS: %s KiB\n' "$member" "$value"
  done
  awk -v total="$total" 'BEGIN{printf "Process-tree PSS snapshot: %.1f MiB\n",total/1024}'
  if ((missing)); then echo 'NOTE: partial snapshot (a process exited or memory was inaccessible)'; fi
  printf 'Idle benchmark command: bash native/measure.sh %s idle 60\n' "$pid"
else
  echo 'NOTE: start exactly one Oziro instance using quickshell -p "$PWD/native" from repo root for automatic PID detection.'
fi
echo '=== Result ==='
if ((fail)); then echo 'PREFLIGHT: FAIL'; else echo 'PREFLIGHT: PASS (static/environment checks only)'; fi
exit "$fail"
