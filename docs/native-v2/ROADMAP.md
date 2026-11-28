# Prioritized roadmap

## 0.9.21 acceptance — user-reported 15/15
See [test record](TEST-00921.md). Remaining visual/performance regression cases below are not release blockers for beginning independent-session validation.

## Remaining visual and interaction regression
- Validate 0.9.18 dock wave, hit targets, click-through, clipping, tooltips, reduce motion, both orientations, large app lists and memory regression.
- Refine Control Center and Settings window with the approved Oziro identity; keyboard navigation, contrast, narrow screens and real icons.
- Keep design iteration in nested Ryoku preview; avoid repeated logout/install.
- Improve live network/Bluetooth and audio status; do not display fake connected state.

## Now — independent session stabilization and desktop completeness
- Reliable session lifecycle, recovery terminal, clean logout and installer/upgrade/rollback.
- Safe automatic lock and lock-before-suspend with verified compositor protocol/PAM, inhibitors and resume testing; no sleep action until ready.
- Notification ownership, tray coexistence, portal and Polkit integration with least privilege.
- Actual display scale/resolution/arrangement, keyboard, mouse, default applications and network connection/pairing UI. Validate and roll back display changes.
- First-run Welcome and desktop context menu; integrate existing file manager and terminal before considering replacements.

## 1.0 candidate gate
- All critical workflows pass in a real independent session; no data loss or host modifications.
- Multi-monitor/hotplug, long-running session, missing services, keyboard navigation, all themes, battery AC transitions and recovery.
- Repeat controlled PSS/CPU measurements and establish whole-session baseline. Document known limitations.
- Review install/upgrade/uninstall and security; test on clean Arch installation or VM and actual hardware. See native release checklist.

## After desktop 1.0
- Declarative widget SDK with resource and permission boundaries; no arbitrary script manifests.
- Optional AI integrations with user consent, privacy, no secrets in repository, no destructive actions without confirmation.
- App/update manager and distribution packaging, boot/login branding, ISO installer, hardware and update/recovery testing. Distribution release is separate from desktop release.

Order is proposed, not a delivery-date promise. Security and data integrity outrank cosmetic additions.

## Immediate priority — user-reported daily UX gaps
1. Stabilize Dock pointer/touchpad behavior and screenshot defaults (0.9.22/0.9.23 user acceptance recorded; long-duration regression remains open).
2. Native NetworkManager connection UI with secure secret agent; BlueZ discovery/pairing/connection with consent and cancellation.
3. Editable, conflict-checked Oziro-only shortcuts with validated configuration and rollback; input settings and gesture regression.
4. Replace text-heavy control layouts with icons, switches, sliders and meaningful grouping, preserving approved themes. Resume independent-session stabilization after regression.

## Next priority after 0.9.22 user acceptance
Wi-Fi and Bluetooth connection workflows, then editable shortcuts and icon-led interface. Keep long-duration Dock regression and remaining screenshot shortcuts open.

0.9.23 hotfix: cold-login icon recovery and no-Print screenshot keys reported PASS. Next implementation priority is native connectivity UI, with explicit permissions, secret handling and cancellation.

2026-11-28: user-reported 0.9.23 native regression acceptance: 11 PASS, 0 FAIL, 0 NOT TESTED. Intended runtime baseline `b5f096ffbd841c04fb4f9f7da038e6fbc92e5f90`. Correct dock icons at login and without pin edits, three login/logout cycles, new app icons, pin/unpin, wave, tooltip, all three no-Print screenshot shortcuts and two monitors reported PASS. Installed SHA and raw logs not independently supplied; no independent reproduction, long-duration reliability, screenshot storage/clipboard or security certification implied.
See [test record](TEST-00923.md).

0.9.24 Wi-Fi Manager implemented, pending target verification. Next: Bluetooth discovery/pairing, then shortcut manager and broader control redesign.

## 0.9.24 panel hotfix and live update evidence
2026-11-28: user reports Wi-Fi Manager working after applying patch `73fe01e34b3dbc4eb5d118fb4e8868217392dc6d` via the in-session development workflow. This resolves the reported panel-opening blocker at user-report level. Earlier terminal evidence: live update published five files; Niri validation, Preflight and Audit passed, Wi-Fi helper self-tests 24/24, preview mutation guard passed, and direct read-only NetworkManager list returned three networks. User separately confirmed updated About version and preserved open windows without logout. No raw post-patch log or installed SHA supplied. Actual scan, authentication, wrong password, saved/volatile profiles, disconnect, multi-output and absence of binding warnings after patch remain unverified; do not infer full Wi-Fi acceptance from the brief report.
See [test record](TEST-00924.md).

0.9.25 Bluetooth and notification activation implementation pending target test. Authenticated pairing agent remains open. Next editable shortcuts after connectivity regression.
