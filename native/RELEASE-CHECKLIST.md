# Release gates — 1.0 candidate preparation
- User screenshot 0.9.1: shell and Manage page visible; My battery installed; registry 16/16; Settings saved. Dashboard readings, toggling, removal, invalid input and restart persistence are not all independently verified.
- Preflight: no missing files, Bash syntax clean, doctor passes, inspect startup and popup logs. Run on Niri and Hyprland; current Hyprland runtime not confirmed.
- Performance: remeasure idle PSS/CPU 60 seconds with dock off/on; include helper PSS; compare identical workloads. Battery A/B repeat on fixed brightness. No energy saving claim yet.
- Reliability: long session, repeated popup openings, suspend/resume, AC transitions, monitor hotplug, audio/network unavailable.
- Independence: isolated standalone session, notification ownership, system tray, lock screen, safe exit/recovery and installer/uninstall; no replacement of Ryoku until tested.
- Design: consistent visual hierarchy, icons, spacing, responsive scaling and keyboard accessibility.
- Release only after documented acceptance. 0.9.2 is stabilization, not 1.0 RC or a distribution.
