#!/usr/bin/env bash
# Private session bus test: never takes the existing desktop notification name.
set -euo pipefail
dir="$(cd -- "$(dirname -- "$0")" && pwd)"
for cmd in dbus-run-session busctl notify-send quickshell; do
    command -v "$cmd" >/dev/null || { echo "Missing $cmd" >&2; exit 1; }
done
if [[ " $* " != " --private-bus " ]]; then
    exec dbus-run-session -- bash "$dir/notification-test.sh" --private-bus
fi
# Refuse accidental direct invocation against a bus already serving notifications.
owner() { busctl --user call org.freedesktop.DBus /org/freedesktop/DBus org.freedesktop.DBus NameHasOwner s org.freedesktop.Notifications; }
[[ "$(owner)" == "b false" ]] || { echo "Notification owner exists; refusing test" >&2; exit 1; }
OZIRO_NOTIFICATIONS=1 quickshell -p "$dir" &
pid=$!
trap 'kill "$pid" 2>/dev/null || true; wait "$pid" 2>/dev/null || true' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
ready=0
for ((i=0;i<40;i++)); do
    kill -0 "$pid" 2>/dev/null || { echo "Oziro exited" >&2; exit 1; }
    if [[ "$(owner)" == "b true" ]]; then ready=1; break; fi
    sleep 0.25
done
[[ "$ready" == 1 ]] || { echo "Notification server did not start" >&2; exit 1; }
notify-send -a "Oziro test" "Notification test" "Delivered on the isolated session bus."
notify-send -a "Oziro test" "Second notification" "Open Alerts to see both messages."
echo "Private notification bus active. Press Ctrl+C to stop."
wait "$pid"
