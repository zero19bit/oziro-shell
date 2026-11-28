# Testing and evidence

## Daily development
From Ryoku:
```bash
cd ~/Projects/oziro-v2
git pull --ff-only
bash native/preflight.sh
bash native/nested-preview.sh 2>&1 | tee oziro-preview.log
```
Preflight is static/environment only, not a full runtime test. Nested preview is not a VM. Close it before starting another. No sudo or logout for routine design.

## 0.9.18 dock acceptance
- Move across at least five items: hovered art largest, nearby items smaller, no overlap that hides adjacent icons.
- Pointer exit restores normal size. Click each item; focus/pins/launch remain correct. Tooltip shows correct app name.
- Verify transparent headroom does not intercept ordinary windows; window exclusion zone stays stable during hover.
- Long app list: horizontal scrolling and fixed hit targets; verify top/bottom layouts, narrow output, two monitors.
- Settings > Desktop & Dock > Dock magnification off: no wave. Eco also suppresses wave. Restore normal energy and verify toggle works; check persisted toggle only in real/non-nested mode.
- Capture errors and screenshot or screen recording. Check PSS and CPU after idle settling.
Pure DockMotion.js selfTest: 11/11 in JS engine for distance symmetry, cutoff, disabled state, scale bound and approximate overlap bound. Not an actual QML test.

## Historical measured evidence
- 0.9.2 user 60-sample PSS: dock off 168.9 MiB / 0.02% CPU; dock on 173.1 / 0.39%; warm 203.3 / 4.64%.
- 0.9.3 user 60-sample settled warm 166.9 MiB / 0.02%; idle 168.5 / 0.02%. See native/TEST-0093.md. Not controlled A/B; versions and settling differed.
- No verified current-HEAD resource or battery savings. Whole-tree, GPU and long-session tests remain.

## Release regression matrix
Test real independent login and return to Ryoku, all theme packs and local image, workspace/focus/pins, notification/tray, sound/network/brightness, lock on all screens, denied power actions, manual logout/restart/shutdown with saved work, hotplug and long-session stability. Secure suspend only after implementation. Record build SHA, platform, steps, expected/actual, logs and result; mark skipped separately.

## 0.9.19
Run `bash native/audit-check.sh` as desktop user for non-destructive preview guard and Bash checks. See [audit](AUDIT-00919.md) for actual pure JS results and limitations.

## 0.9.21 user acceptance
2026-11-28: user-reported 0.9.21 acceptance, 15/15 PASS. Intended runtime baseline: `88d29bb9fa2aac9b4c741763f7d7722eedf1c82b`. Local Git SHA, raw logs, exact display scales and command output were not supplied, so this is user-reported evidence, not independently reproduced or SHA-attested. No current independent SDDM login, destructive power action, suspend, security certification or performance claim follows from this report.
See [15-check record](TEST-00921.md). Earlier reported tooltip/dismissal failures were observed while the local runtime was reportedly still 0.9.18 before DNS recovery; they do not establish a 0.9.20 or 0.9.21 failure.
