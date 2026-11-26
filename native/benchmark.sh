#!/usr/bin/env bash
# Sample the single Oziro shell process, not the entire desktop or its battery draw.
set -euo pipefail
pid="${1:-}"
samples="${2:-10}"
[[ "$pid" =~ ^[1-9][0-9]*$ && "$samples" =~ ^[1-9][0-9]*$ && "$samples" -le 3600 ]] || { echo "Usage: bash benchmark.sh PID [samples=10]" >&2; exit 2; }
[[ -r "/proc/$pid/smaps_rollup" ]] || { echo "Cannot read target process memory" >&2; exit 1; }
echo "timestamp,pid,rss_kib,pss_kib,cpu_ticks,monotonic_seconds"
start_id=""
for ((i=0; i<samples; i++)); do
  [[ -r "/proc/$pid/smaps_rollup" && -r "/proc/$pid/stat" ]] || { echo "Process exited" >&2; exit 1; }
  mem="$(awk '/^Rss:/{r=$2} /^Pss:/{p=$2} END{if(r==""||p=="")exit 1; print r "," p}' "/proc/$pid/smaps_rollup")"
  stat="$(cat "/proc/$pid/stat")"
  rest="${stat##*) }"
  read -r ticks identity < <(awk '{print $12+$13, $20}' <<< "$rest")
  if [[ -z "$start_id" ]]; then start_id="$identity"; fi
  [[ "$identity" == "$start_id" ]] || { echo "PID reused" >&2; exit 1; }
  read -r uptime _ < /proc/uptime
  printf '%s,%s,%s,%s,%s\n' "$(date -Is)" "$pid" "$mem" "$ticks" "$uptime"
  if (( i+1 < samples )); then sleep 1; fi
done
