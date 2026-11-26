# Native architecture

Active runtime is native QML/Quickshell. Niri is the primary Wayland compositor; Hyprland adapter is secondary and not currently validated. Linux remains responsible for kernel, authentication, hardware and system services.

```text
SDDM / existing desktop / nested Niri
  -> Niri + Quickshell ShellRoot
     -> Preferences (versioned local JSON)
     -> NiriBackend (IPC / stable window model)
     -> EnergyEngine (UPower, event-driven + bounded reconcile)
     -> per-output TopBar / Dock / WallpaperSurface
     -> on-demand Loader: Settings, Launcher, Controls, Power, Widgets, Tray
     -> opt-in NotificationBackend / Toast
  -> PipeWire, NetworkManager, brightness, powerprofiles, logind, Hyprlock/PAM
```

## Boundaries
- UI delegates use typed properties/signals; business policy in pure JS or narrow backend helpers.
- Niri IPC drives workspace/window state. Stable IDs avoid delegate reconstruction on focus changes.
- Power helper validates session and action; logind applies authorization. Lock delegates to Hyprlock; Oziro never receives credentials.
- Preferences preserve separate preview/source/login behavior. Nested preview does not load/write persisted preferences. Login preferences separate from ordinary source preferences. Atomic writes; reject invalid formats.
- Wallpaper uses bundled SVG or validated local image paths; no remote URL. Widgets accept bounded declarative manifests only.
- Dock wave uses fixed slot positions, one pointer tracker and bounded transform. Input region limited to shelf; normal exclusion zone unchanged by lift.

## Execution modes
1. Nested preview: windowed Niri, private D-Bus, temporary config, destructive power and hardware changes disabled; not a security sandbox.
2. Source shell: coexists with current desktop; host services remain active.
3. Experimental SDDM login: direct Niri, own config, private bus, root-owned allowlisted copy; existing Ryoku wrapper still delegates and may import environment. No complete session-manager integration yet.
