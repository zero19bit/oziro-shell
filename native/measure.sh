#!/usr/bin/env bash
# One phase of a repeatable process-only benchmark. No changes to power settings.
set -euo pipefail
pid="${1:-}"
phase="${2:-idle}"
samples="${3:-60}"
[[ "$pid" =~ ^[1-9][0-9]*$ && "$phase" =~ ^[a-zA-Z0-9_-]+$ && "$samples" =~ ^[1-9][0-9]*$ && "$samples" -le 3600 ]] || { echo "Usage: bash measure.sh PID PHASE [SECONDS=60]" >&2; exit 2; }
[[ -r "/proc/$pid/cmdline" ]] || { echo "PID not accessible" >&2; exit 1; }
cmd="$(tr '\0' ' ' < "/proc/$pid/cmdline")"
[[ "$cmd" == *quickshell* ]] || { echo "PID is not Quickshell" >&2; exit 1; }
dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
clock="$(getconf CLK_TCK)"
out="$(mktemp)"
trap 'rm -f -- "$out"' EXIT
bash "$dir/benchmark.sh" "$pid" "$samples" > "$out"
awk -F, -v phase="$phase" -v hz="$clock" '
NR==2 {first=$5; t0=$6; min=$4; max=$4}
NR>1 {sum+=$4; if($4<min)min=$4; if($4>max)max=$4; last=$5; t1=$6; n++}
END {if(n<1 || last<first)exit 1; printf "%s: PSS avg %.1f MiB, min %.1f, max %.1f, samples %d",phase,sum/n/1024,min/1024,max/1024,n; if(n>1 && t1>t0)printf ", CPU approx %.2f%% of one core, elapsed %.1fs",(last-first)/hz/(t1-t0)*100,t1-t0; print ""}
' "$out"
