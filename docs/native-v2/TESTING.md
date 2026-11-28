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

## 0.9.22 acceptance (pending)
- Balanced: move repeatedly across dock, open/close menus, switch windows, cross outputs, leave/re-enter dock, test AC/battery changes. Eco must explain paused motion; selecting Balanced restores motion without restart.
- Test tap/physical click, two-finger scroll on overflow, vertical wheel fallback, click vs drag, tooltip and fixed input mask, both dock orientations and two monitors.
- Validate both KDL configs with target Niri. In independent login test tap, two-finger right click, scrolling and Print/Ctrl+Print/Alt+Print/Super+Shift+S; nested host may intercept keys or supply preprocessed input. Confirm clipboard/file output and no host config writes.
- Check Wi-Fi/Bluetooth symbols and switch status in all theme packs; no connection UI claimed. Check settings text and layout. Real runtime pending.

## 0.9.22 independent session evidence
2026-11-28: user reports independent Oziro 0.9.22 session acceptance: 16 PASS, 0 FAIL, 3 NOT TESTED (19 total). Intended runtime baseline b81a6c825d218d05f24d24ccb15dd33654f1385f; installed SHA and raw logs not independently supplied. Dock and touchpad checks all passed in the reported session; intermittent-wave long-duration regression remains open. Super+Shift+S passed; Print, Ctrl+Print and Alt+Print not tested. Logout/return to Ryoku and two monitors reported PASS. No security, screenshot storage/clipboard, long-run or performance certification implied.
See [test record](TEST-00922.md).

## 0.9.23 acceptance criteria
- Cold login at least three times with existing pinned apps; no pin edits or restart to recover icons. Check built-in, pinned, running and intentionally missing icon behavior. Generic bundled fallback is acceptable only when no actual icon resolves.
- Open apps after startup and pin/unpin; ensure real icons replace fallback when index becomes available, correct launch/focus, wave, tooltip, two monitors and no QML errors. Record whether bundled Applications/Settings icons were also affected.
- Test Super+Shift+3 and Super+Shift+4, retain Super+Shift+S, check saved image/clipboard and focused output/window. Niri config validation on target required.

2026-11-28: user-reported 0.9.23 native regression acceptance: 11 PASS, 0 FAIL, 0 NOT TESTED. Intended runtime baseline `b5f096ffbd841c04fb4f9f7da038e6fbc92e5f90`. Correct dock icons at login and without pin edits, three login/logout cycles, new app icons, pin/unpin, wave, tooltip, all three no-Print screenshot shortcuts and two monitors reported PASS. Installed SHA and raw logs not independently supplied; no independent reproduction, long-duration reliability, screenshot storage/clipboard or security certification implied.
See [test record](TEST-00923.md).

## 0.9.24 Wi-Fi acceptance (pending)
- From Control Center or Settings > Devices > Wi-Fi networks: cached list, scan, signal and security, active connection, saved and unsupported states; missing adapter/helper and radio off. Preview must reject all mutations.
- On disposable trusted hotspot: wrong password, cancel before connect, successful temporary WPA2/WPA3/open join, saved profile reuse, remember option and reconnect, disconnect confirmation. Verify normal NM authorization, no secret in argv/logs/Oziro state. Test switching away from a network only when safe; no claimed internet reachability from Wi-Fi activation.
- Confirm keyboard navigation, Escape, both outputs, long list, no QML errors, no lingering helper. Audit includes pure helper tests and preview denial. Actual runtime pending.
