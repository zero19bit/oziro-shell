# Feature status — 0.9.22

Status labels: **Confirmed** = user reported or screenshot supports the stated behavior; **Partial** = implemented, some evidence or important gaps; **Implemented** = code exists, runtime unverified; **Planned** = not delivered. Historical evidence is not a guarantee for current HEAD.

| Area | State | Evidence / gaps |
|---|---|---|
| Niri IPC, panel and workspace model | Confirmed historically | Niri 26.04, Quickshell 0.3.2 on development Arch; current regressions need test |
| Launcher and dock pin/focus | Confirmed historically | 0.4 user tests; current UI changed |
| Power source and adaptive policy | Partial | 0.8.1 user confirmed AC transitions; actual energy savings unverified |
| Network/Bluetooth toggles, audio, brightness | Partial | 0.5 user 13/14; system profile change unconfirmed; no join/pairing UI |
| Notifications | Partial | 0.6 private bus 10/10; independent-session ownership not integrated |
| Themes, wallpaper and brand | Confirmed visual direction | 0.9.17 user explicitly likes appearance; each theme, persisted custom image and multi-output regressions pending |
| Widgets | Partial | 0.9.1 actual QML registry 16/16; 0.9.2 dashboard observed; full CRUD/persistence not all verified |
| System Tray | Partial | 0.9.9 screenshot 4 entries; activation/menu and ownership not verified |
| Manual lock | Confirmed historically | 0.9.10 user confirms both monitors locked, password required and unlock succeeds; idle/suspend/recovery pending |
| Nested preview | Confirmed | 0.9.11 screenshot; 0.9.17 user visual approval; temporary preview, not security sandbox |
| SDDM Oziro experimental login | Confirmed historically | 0.9.13 user reports test successful; no complete services or distribution |
| Power menu | Partial | 0.9.15 user reports works; exact action coverage not recorded; suspend disabled |
| Settings window | Partial | 0.9.21 user reports open/close PASS; full links and persistence regression pending |
| Wave dock | Confirmed (user report) | 0.9.18 11/11 pure JS math; 0.9.21 wave and tooltip reported PASS; overflow, scale and performance pending |
| Full display/input/default apps settings | Planned | no pretend controls |
| Portals, Polkit, secure idle/suspend, session lifecycle | Planned/partial | highest release blockers |
| AI, SDK, app/update manager, ISO | Planned | later milestones |

Known platform: development host uses Niri, not Hyprland. Hyprland compatibility is not a current verified target. Main branch remains unchanged; active branch is oziro-v2-native-prototype.

0.9.19 targeted hardening implemented; see [audit](AUDIT-00919.md). Runtime pending.

## Current acceptance
2026-11-28: user-reported 0.9.21 acceptance, 15/15 PASS. Intended runtime baseline: `88d29bb9fa2aac9b4c741763f7d7722eedf1c82b`. Local Git SHA, raw logs, exact display scales and command output were not supplied, so this is user-reported evidence, not independently reproduced or SHA-attested. No current independent SDDM login, destructive power action, suspend, security certification or performance claim follows from this report.

Layer Shell outside-click/Escape, Control Center, passive tooltips, focus/non-interference, overlay cleanup and two-monitor behavior reported PASS. See [test record](TEST-00921.md). Earlier reported tooltip/dismissal failures were observed while the local runtime was reportedly still 0.9.18 before DNS recovery; they do not establish a 0.9.20 or 0.9.21 failure.

## 0.9.22 implementation (runtime pending)
0.9.22: input and control usability pass. Dock hover uses explicit viewport coordinates and non-blocking handlers; taps use DragThreshold rather than a competing MouseArea; overflow accepts horizontal touchpad scrolling and vertical wheel fallback with bounded offsets. Wave remains intentionally paused by Eco; Settings exposes the reason and a Balanced action. Oziro-owned Niri configs enable tap, natural scroll and disable-while-typing; add native screenshot bindings. Wi-Fi/Bluetooth tiles get drawn symbols and switch-style state. No change to Ryoku, PAM, host services or secrets. Native Wi-Fi selection/authentication, Bluetooth discovery/pairing and editable shortcuts remain pending. Runtime unverified.
