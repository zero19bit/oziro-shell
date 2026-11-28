# Native v2 milestone history

This is a compact historical index; detailed implementation and observed tests live in native/README.md and release checklist. Dates are not inferred for older milestones.

| Version | Main change |
|---|---|
| 0.1 | Native Quickshell panel, launcher, controls, themes |
| 0.2 | Event-driven Niri and battery fallback |
| 0.3 | Lazy surfaces, JSON settings, resource measurement |
| 0.4 | Optional dock, pinning and window focus |
| 0.5 | On-demand device controls |
| 0.6 | Notifications and DND, private-bus test |
| 0.7 | Theme Studio, accent, sizes, clock |
| 0.8 / 0.8.1 | Adaptive Energy Engine, verified UPower reconciliation |
| 0.9 / 0.9.1 | Widget Center and QML-compatible declarative registry |
| 0.9.2 / 0.9.3 | Preflight, stable window models, improved settled resource results |
| 0.9.4–0.9.6 | UI refinement, readable surfaces, quick controls |
| 0.9.7 / 0.9.8 | Wallpaper engine and layer compatibility |
| 0.9.9 | On-demand system tray |
| 0.9.10 | Manual Hyprlock integration, user-confirmed lock/unlock |
| 0.9.11 / 0.9.12 | Nested preview and login readiness |
| 0.9.13 | Experimental SDDM login; user confirms successful test |
| 0.9.14 / 0.9.15 | Settings hub and power menu, authorization diagnostics |
| 0.9.16 | Compact bar, graphical dock, real Settings window |
| 0.9.17 | Approved visual direction: mark, coordinated theme packs, local wallpapers |
| 0.9.18 | Wave dock, tooltips, system icons, motion toggle, project handbook |

0.9.18: pure motion math 11/11; real QML/Wayland validation pending. No production release.

0.9.19: targeted hardening of session, installer, hardware/power helpers, settings and IPC. Pure JS 78/78; runtime pending.

0.9.20: shared native PopupWindow with outside-dismiss and Escape fallback; themed passive tooltips; floating Settings excluded. No global input listener. Niri runtime verification pending; first outside click may be consumed by compositor. Power action process kept alive until completion. See Quickshell 0.3.2 PopupWindow API.

0.9.21: Earlier reported tooltip/dismissal failures were observed while the local runtime was reportedly still 0.9.18 before DNS recovery; they do not establish a 0.9.20 or 0.9.21 failure. Replace native grabbed PopupWindow with on-demand transparent Layer Shell menu surface (same content, outside click consumed), passive separately positioned tooltip surface, loader error recovery and one transient menu at a time. Settings remains independent. Initial runtime result was pending. 2026-11-28: user-reported 0.9.21 acceptance, 15/15 PASS. Intended runtime baseline: `88d29bb9fa2aac9b4c741763f7d7722eedf1c82b`. Local Git SHA, raw logs, exact display scales and command output were not supplied, so this is user-reported evidence, not independently reproduced or SHA-attested. No current independent SDDM login, destructive power action, suspend, security certification or performance claim follows from this report. See [test record](TEST-00921.md).

0.9.22: input and control usability pass. Dock hover uses explicit viewport coordinates and non-blocking handlers; taps use DragThreshold rather than a competing MouseArea; overflow accepts horizontal touchpad scrolling and vertical wheel fallback with bounded offsets. Wave remains intentionally paused by Eco; Settings exposes the reason and a Balanced action. Oziro-owned Niri configs enable tap, natural scroll and disable-while-typing; add native screenshot bindings. Wi-Fi/Bluetooth tiles get drawn symbols and switch-style state. No change to Ryoku, PAM, host services or secrets. Native Wi-Fi selection/authentication, Bluetooth discovery/pairing and editable shortcuts remain pending. Runtime unverified.

- 2026-11-28: user reports independent Oziro 0.9.22 session acceptance: 16 PASS, 0 FAIL, 3 NOT TESTED (19 total). Intended runtime baseline b81a6c825d218d05f24d24ccb15dd33654f1385f; installed SHA and raw logs not independently supplied. Dock and touchpad checks all passed in the reported session; intermittent-wave long-duration regression remains open. Super+Shift+S passed; Print, Ctrl+Print and Alt+Print not tested. Logout/return to Ryoku and two monitors reported PASS. No security, screenshot storage/clipboard, long-run or performance certification implied. See [test record](TEST-00922.md).

0.9.23: Dock cold-start icon recovery and keyboard-independent screenshot bindings. Observe DesktopEntries.applications.values for pinned/running entry resolution instead of untracked lookup alone. Check theme icon paths before loading, show a bundled local fallback if absent/loading/error, and preserve fixed hit targets and existing wave behavior. No new polling, theme dependencies, or host configuration changes. Add Super+Shift+3 (focused screen) and Super+Shift+4 (focused window), retain Super+Shift+S and Print bindings. Actual cold-login and new screenshot tests pending; original cause not conclusively established.
