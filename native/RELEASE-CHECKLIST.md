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

- 0.9.13: host evidence confirms SDDM wrapper delegates chosen command, Niri service has Ryoku bootstrap drop-in and key Ryoku services are target-bound. Experimental direct-Niri package prepared; installer check, actual login, terminal fallback, exit, original session return, service collisions, and removal still pending. No automatic locking/idle, portal/polkit or security-completeness claim.

- User reports 0.9.13 login and original tests successful. 0.9.14 addresses power menu and settings hub; validate UI, explicit confirmations, logout, normal authorization and cancellation. Suspend/idle, full display/input settings, cohesive visual identity, portal/polkit and complete independent desktop services remain open.

- 0.9.14 user reports Settings works; only Lock works in Power, test context not confirmed. 0.9.15 compact system menu and neutral glass styling; verify source disabled state and installed login capability probe, cancellation, logout, restart and shutdown separately. Challenge/denied is not bypassed. Visual acceptance pending.

- 0.9.15 user confirms power works; precise action coverage not specified. User rejects visual change as insufficient. 0.9.16 new top-bar layout, icon dock and actual Settings window: verify QML load, window close/reopen, all links, settings persistence, panel/dock sizing, multimonitor and visual acceptance. No performance claim.

- 0.9.17 user requests stronger top bar, logos, coordinated themes and wallpapers. Verify nested startup, artwork decoding, theme previews and switching, local image regression, menu access and both monitor widths. No actual visual acceptance or memory measurement yet.

- 0.9.17 user explicitly likes visual direction; individual theme/monitor regression cases remain open. 0.9.18 DockMotion pure math 11/11 in JS engine (not QML runtime). Verify hover/click, neighbor wave, tooltip, reset on exit, overflow scrolling, fixed exclusion zone, click-through headroom, top/bottom placement, Eco/disabled behavior, persisted toggle and PSS/CPU. Handbook added; no release claim.

- 0.9.19 targeted review and fixes; pure JS 78/78. Run audit-check and runtime regression; full security/dependency review and idle/suspend remain open.
