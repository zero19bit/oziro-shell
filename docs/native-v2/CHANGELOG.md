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
