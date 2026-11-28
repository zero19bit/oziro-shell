#!/usr/bin/env bash
# Non-destructive regression checks; run as desktop user, never root.
set -euo pipefail
dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
[[ $(id -u) -ne 0 ]] || { echo "Do not run as root"; exit 1; }
for f in "$dir"/*.sh; do bash -n "$f"; done
echo "PASS: all native Bash syntax"
expect_denied() {
  if env OZIRO_NESTED_PREVIEW=1 OZIRO_LOGIN_SESSION=0 bash "$dir/$1" "${@:2}" >/dev/null 2>&1; then
    echo "FAIL: preview action was not denied: $1 $2"; exit 1
  fi
  echo "PASS: denied $1 $2"
}
# Preview context explicitly denies these requests before reaching any hardware command.
expect_denied system-controls.sh wifi off
expect_denied system-controls.sh bluetooth off
expect_denied system-controls.sh brightness 50
expect_denied system-controls.sh profile balanced
expect_denied lock-session.sh --check
# Only read-only capability query for power; never call destructive operations in this test.
out="$(env OZIRO_NESTED_PREVIEW=1 OZIRO_LOGIN_SESSION=0 bash "$dir/power-action.sh" --check)"
grep -qx "Logout: no" <<<"$out"
grep -qx "Restart: no" <<<"$out"
grep -qx "Shutdown: no" <<<"$out"
echo "PASS: preview power capability denial"
if command -v python >/dev/null 2>&1; then
  python -I "$dir/wifi-manager.py" --self-test
  python -I "$dir/fan-status.py" --self-test
  for action in scan join disconnect; do
    if printf '{"action":"%s"}\n' "$action" | env OZIRO_NESTED_PREVIEW=1 python -I "$dir/wifi-manager.py" >/dev/null; then
      echo "FAIL: Wi-Fi preview mutation not denied"; exit 1
    fi
  done
  echo "PASS: Wi-Fi preview mutation guard"
else
  echo "SKIP: Python Wi-Fi helper tests"
fi
echo "Static/preview guard checks only; not a security certification or Wayland test."
