# Release gates — 1.0 candidate preparation
- User screenshot 0.9.1: shell and Manage page visible; My battery installed; registry 16/16; Settings saved. Dashboard readings, toggling, removal, invalid input and restart persistence are not all independently verified.
- Preflight: no missing files, Bash syntax clean, doctor passes, inspect startup and popup logs. Run on Niri and Hyprland; current Hyprland runtime not confirmed.
- Performance: 0.9.3 main process settled warm 166.9 MiB, idle 168.5 MiB, CPU 0.02% in each 60-sample run. Current short-run targets met (TEST-0093.md). Controlled A/B, helper PSS/CPU, long-run stability and battery A/B remain open. Recheck after visual changes. No energy saving claim yet.
- Reliability: long session, repeated popup openings, suspend/resume, AC transitions, monitor hotplug, audio/network unavailable.
- Independence: isolated standalone session, notification ownership, system tray, lock screen, safe exit/recovery and installer/uninstall; no replacement of Ryoku until tested.
- Design: first panel/dock visual pass in 0.9.4; validate all five themes, contrast, narrow displays, keyboard focus and visual regression. Popup visual pass in 0.9.5; validate slider controls, scrolling, light/dark themes and performance. Further polish remains open.
- Release only after documented acceptance. 0.9.5 is stabilization, not 1.0 RC or a distribution.

- Wallpaper 0.9.8: user confirms Compatibility visibility. Image loading, persistence, both-monitor visual behavior, and resource costs remain open. 0.9.9 tray: verify registration/coexistence and app-provided menu/activation with a real StatusNotifier item; no legacy XEmbed support.

- 0.9.9 screenshot confirms four StatusNotifier items, not menu actions. 0.9.10 manual Hyprlock integration: verify prerequisites, actual lock on all monitors, successful normal password unlock, and coexistence with Ryoku. No automated idle/suspend or production security claim. Preserve system PAM and existing lock mechanisms.

- 0.9.10 user confirms all four manual lock checks on two monitors. Automatic lock, suspend, crash/recovery and broader security tests remain open. 0.9.11 nested development preview: confirm separate window, panel, dock, wallpaper, workspace/launcher, exit and intact host session/settings. Not a real display-manager session.

- 0.9.11 screenshot confirms nested panel, dock, application and widgets; cleanup and settings isolation not independently tested. 0.9.12 read-only host readiness and draft config precede any new login session registration. Confirm active DM, terminal fallback, session lifecycle, no Ryoku service collisions, and rollback before live login.
