# Oziro V2 — Foundation 0.2 (experimental)
Native Arch / Hyprland and Niri shell, independent of the legacy Rust/React host. Not a production release.

## Test on a real Wayland session
Install the official Arch package quickshell (target API 0.3.2), plus UPower and PipeWire/WirePlumber where needed. Do not run as root. Existing bars may compete for space; temporarily stop them yourself.
```sh
bash native/doctor.sh
quickshell -p "$PWD/native"
```
Ctrl+C stops the foreground instance. No compositor configuration is rewritten. Click OZIRO to search graphical installed apps (terminal-only desktop entries excluded); Controls opens audio, themes, layouts and shell eco mode. Close popups before testing another monitor. Themes and settings are session-only. Glass is translucent color, not real blur.

Optional isolated install: `bash native/install.sh`. It refuses an existing destination and does not install dependencies, change autostart, or replace your current shell.

## Verification
QML targets documented Quickshell 0.3.2 APIs, but still requires actual Arch/Hyprland and Niri runtime verification. No performance numbers or hardware power savings have been established. Report exact logs and test monitor hotplug, popup focus, no audio, AC/battery transitions, all palettes and all layouts. Run `bash native/benchmark.sh PID 60` to sample process PSS/RSS and cumulative CPU ticks. Compare same machine, display setup and workload, with old shell stopped. This measures one process, not total session or battery usage.

## Scope
Implemented in source: per-screen panel, real workspace activation, clock, default audio mute/volume, battery status, on-demand launcher, control center, five provisional palettes, three panel placements, battery-aware reduced shell effects, user-copy installer and measurement helper. No always-on AI, sync or animated wallpaper.
Not yet implemented: dock, full notifications, network, tray, power profile integration, persistence, graphical setup, plugin isolation, widgets, lock screen, update mechanism, CI runtime tests or OS image. See VISION.md.

## Foundation 0.2 changes
Niri backend uses a single event stream socket with reconnect on disconnect and a separate bounded action connection. The panel chooses Niri when NIRI_SOCKET is set; battery selection falls back to a present physical laptop battery. Neither change has yet been tested in a real session. No compositor files are modified.
