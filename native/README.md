# Oziro V2 — Foundation 0.3 (experimental)
Native Arch / Hyprland and Niri shell, independent of the legacy Rust/React host. Not a production release.

## Test on a real Wayland session
Install the official Arch package quickshell (target API 0.3.2), plus UPower and PipeWire/WirePlumber where needed. Do not run as root. Existing bars may compete for space; temporarily stop them yourself.
```sh
bash native/doctor.sh
quickshell -p "$PWD/native"
```
Ctrl+C stops the foreground instance. No compositor configuration is rewritten. Click OZIRO to search graphical installed apps (terminal-only desktop entries excluded); Controls opens audio, themes, layouts and shell eco mode. Close popups before testing another monitor. Theme, layout and shell effects are saved in the Oziro state directory; no Ryoku settings are changed. Glass is translucent color, not real blur.

Optional isolated install: `bash native/install.sh`. It refuses an existing destination and does not install dependencies, change autostart, or replace your current shell.

## Verification
QML targets documented Quickshell 0.3.2 APIs, but still requires actual Arch/Hyprland and Niri runtime verification. See TEST-001.md and TEST-002.md for user-reported results; no 0.3 memory or hardware power savings have been established. Report exact logs and test monitor hotplug, popup focus, no audio, AC/battery transitions, all palettes and all layouts. Run `bash native/benchmark.sh PID 60` to sample process PSS/RSS and cumulative CPU ticks. Compare same machine, display setup and workload, with old shell stopped. This measures one process, not total session or battery usage.

## Scope
Implemented in source: per-screen panel, real workspace activation, clock, default audio mute/volume, battery status, on-demand launcher, control center, five provisional palettes, three panel placements, battery-aware reduced shell effects, user-copy installer and measurement helper. No always-on AI, sync or animated wallpaper.
Not yet implemented: dock, full notifications, network, tray, power profile integration, graphical setup, plugin isolation, widgets, lock screen, update mechanism, CI runtime tests or OS image. See VISION.md.

## Foundation 0.2 changes
Niri backend uses a single event stream socket with reconnect on disconnect and a separate bounded action connection. The panel chooses Niri when NIRI_SOCKET is set; battery selection falls back to a present physical laptop battery. Both changes passed the user-reported Niri test (see TEST-002.md). No compositor files are modified.

## Foundation 0.3
Cold panel uses QtQuick-only controls and loads popup QML by URL when requested. Both popups share one loader per output, and icon caching is disabled in the launcher as an experiment. This may trade some reopen latency for lower retained memory; benchmark before claiming a gain. OZIRO_PANEL_ONLY=1 disables popup entry points for isolation. Preferences use atomic JSON writes in the shell's XDG state directory. Only one Oziro instance should write these settings. The new installer includes the previously omitted Niri backend. Run `bash native/measure.sh PID cold 60`, then open/close both popups and run `bash native/measure.sh PID warm 60`. Compare with matching 0.2 tests. CPU is an approximate tick-based average; GPU/whole-system power is not measured.
