# Oziro OS — product charter
Target: Arch x86_64 / Hyprland first; eventual distribution only after shell reliability and hardware tests. Hybrid original visual identity, switchable Glass/Material/Minimal/Cyber/light designs, configurable layouts. Favor coherent input, accessibility, instant interactions, predictable sleep/resume and power use over effects.

## Efficiency contract
- One native Qt/QML shell; no embedded browser or local HTTP server in the new path.
- Event-driven native services; minute clock; expensive surfaces destroyed when closed.
- Default no background AI, cloud sync, animated wallpaper or arbitrary extensions. Each requires explicit enablement and bounded resource use.
- Eco reduces shell animation/translucency on battery; do not silently modify kernel, governors, TLP, power-profiles-daemon or GPU settings.
- Initial engineering goals (not measurements): shell PSS <= 100 MiB idle on reference laptop; CPU <= 0.5% of one core averaged over 5 minutes; no recurring idle subprocesses. Revisit after measurement. Compare full-session energy in watt-hours under matched hardware/workload/display brightness. No Mac battery parity claim.

## Release gates
1. Foundation: reproducible Arch startup, per-screen surfaces, launcher, audio, battery, themes, safe user installation.
2. Desktop: dock/task switcher, tray, notifications, network/Bluetooth, settings persistence, actual power profile control with service availability and consent, multi-monitor hotplug, recovery.
3. Platform: signed package/release, safe update/rollback, graphical setup, PAM + compositor session-lock or audited existing locker, accessibility and keyboard testing.
4. Optional services: widget registry with declared permissions, isolated extension processes (QML plugin code is not a sandbox), opt-in AI with no idle model, static-by-default wallpapers, encrypted sync using OS keyring and explicit account consent.
5. OS: installer image, hardware matrix (Intel/AMD/NVIDIA), suspend/resume, audio/Wi-Fi, battery tests, security updates, recovery and licensing review. Do not ship until these are verified.

Secrets: use OS keyring for future provider tokens, never QML settings, command arguments or logs. Use PAM/Polkit for local authorization, no homegrown password store. Never run UI as root.
