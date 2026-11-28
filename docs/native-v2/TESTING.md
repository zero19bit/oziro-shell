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

## Experimental live development update (0.9.24 tooling)
From the running Oziro session, save work, close menus and finish any active lock/power/network action. As desktop user run `git pull --ff-only`, `bash native/preflight.sh`, `bash native/audit-check.sh`, `bash native/live-update.sh --check`; then explicitly run `sudo bash native/live-update.sh --apply`. No logout/reinstall is intended for supported payload changes. Quickshell and Niri file watchers should reload; the command does not certify runtime success. Files are staged and individually atomically replaced (not a whole-payload transaction), shell.qml last. Root-owned backup path is printed; restore with `sudo bash native/live-update.sh --rollback BACKUP`. A crash or power loss during publication may require recovery from a TTY. Login launcher/SDDM changes require offline upgrade; no forced process restart. Only known Oziro files are touched, no user preferences. Backups are retained outside installation. Future files must be added to installer and live-update allowlists. Experimental, real-session verification pending.

2026-11-28: user terminal output confirms live update file publication, Niri validation, 24/24 Wi-Fi helper self-tests, preview mutation denial, UI version update and open-window preservation. Direct installed helper list succeeded (three visible networks; identifiers omitted). Wi-Fi panel failed to open; logs provided DockIcon sourceSize.height and tooltip visible binding loops, but no specific WifiCenter loader error. Patch: assign a single QSize from fixed artwork geometry, remove tooltip dependency on its own screen for visibility, defer initial Wi-Fi request, rename adapter state, add menu lifecycle diagnostics. Runtime fix not yet confirmed; exact Wi-Fi failure remains unknown. No backend mutation tested.

## 0.9.24 panel hotfix and live update evidence
2026-11-28: user reports Wi-Fi Manager working after applying patch `73fe01e34b3dbc4eb5d118fb4e8868217392dc6d` via the in-session development workflow. This resolves the reported panel-opening blocker at user-report level. Earlier terminal evidence: live update published five files; Niri validation, Preflight and Audit passed, Wi-Fi helper self-tests 24/24, preview mutation guard passed, and direct read-only NetworkManager list returned three networks. User separately confirmed updated About version and preserved open windows without logout. No raw post-patch log or installed SHA supplied. Actual scan, authentication, wrong password, saved/volatile profiles, disconnect, multi-output and absence of binding warnings after patch remain unverified; do not infer full Wi-Fi acceptance from the brief report.
See [test record](TEST-00924.md).

## 0.9.25 acceptance (pending)
- Bluetooth: open panel; adapter and power, explicit discovery/stop/close cleanup, list, already paired connect/disconnect, simple pairing/cancel, confirmed forget using disposable device, battery where available, no changes in preview. Authenticated pairing unsupported without external agent. No automatic trust.
- Notifications: from Oziro terminal `notify-send -a Oziro 'Oziro test' 'Toast and history'`; verify visible toast, expiration, history, DND, dismissal, two monitors (first output only), reload without replay. `busctl --user status org.freedesktop.Notifications` should show Oziro on private bus. Other bus apps not covered; no host name takeover. Check QML logs and live update.

## 0.9.25 hotfix.1 — adapter initialization and explicit reload
User terminal evidence: files matched 0.9.25, private notification name initially unowned; touching installed shell.qml and Dock.qml triggered Configuration Loaded and NameHasOwner changed to true. notify-send returned without reported error; actual toast visibility/history still unconfirmed. Bluetooth panel logged null adapter discovering access. Guard all scan-state bindings, use default adapter or first available adapter, log only adapter presence/count. Add user-scoped oziroDev IPC revision/reload methods; touch after publication as bootstrap/best effort. Run `quickshell -p /usr/local/lib/oziro-login-preview ipc call oziroDev reload` as desktop user, then `quickshell -p /usr/local/lib/oziro-login-preview ipc call oziroDev revision` (expected `0.9.25-hotfix.1`). No sudo IPC, no compositor restart, no notification takeover of shared bus. First bootstrap may require touching installed shell/Dock again. Adapter enumeration, Bluetooth connection and visible notifications require target verification. No new persistent processes.

## 0.9.25 thermal capability preview (runtime pending)
User reported previous issues OK after DNS recovery; no detailed Bluetooth/notification acceptance matrix or post-hotfix log supplied. Fan Manager added ahead of shortcuts: read-only hwmon RPM/temperature and controller capability probe, optional three-second refresh only while open, existing system power profiles through SystemControls (not direct fan RPM). Manual numerical control is deliberately not implemented until the actual model, driver, supported provider, safe range and automatic thermal fallback are verified. No root/EC/PWM writes, persistent service or automatic fan control changes. Probe: `python -I native/fan-status.py --probe`; self-test: `python -I native/fan-status.py --self-test`. ASUS support varies by model; see https://asus-linux.org/faq/asusctl/custom-fan-curves/. Test real sensors, profile changes and reopen/close; manual acceptance remains pending.

## Fan preview.2 — soft reload correction
User evidence: IPC revision remained `0.9.25-hotfix.1`; delayed reload raised `Insufficient arguments` because Quickshell 0.3.2 requires `reload(hard: bool)`. Correct to `Quickshell.reload(false)` (documented at https://quickshell.org/docs/v0.3.2/types/Quickshell/Quickshell/). Bootstrap using touch of installed shell.qml and Dock.qml if current IPC still points to old generation. Verify runtime revision `0.9.25-fan-preview.2`. Add fan menu lifecycle diagnostics and read-only ASUS curve point display; no fan mutations added. User probe reports ASUS FA507NVR, CPU and GPU RPM sensors, eight points per curve, quiet/balanced/performance, asusctl installed, non-writable attributes for ordinary user. Fixed RPM support not established. Need installed asusctl version and fan-curve help plus asusd state before implementing write provider. No actual target reload or panel acceptance yet.

## 0.9.25-command.1 — Command Center preview
Replaces the small fan popup with a single lazily loaded FloatingWindow; entry points remain Control Center, Energy and Settings. Native dashboard, Overview/Cooling/Hardware/Capabilities navigation, actual hwmon readings, system power-profile controls, ASUS curve normalization and graph, in-memory numeric duty preview and discard. Curves use raw 0–255 PWM (converted to percent for UI), real reported temperature coordinates; no fixed RPM, no hardware curve apply, no GPU switching, battery cap, RGB or game profiles. Missing GPU sensor stays unavailable; no extra GPU interrogation. Profile changes use existing provider and remain explicit. Polling only while window is visible; no new persistent services. Confirmed model FA507NVR from earlier user output, but asusctl version/help and asusd readiness still needed to select/validate safe provider. Preview edits do not write to disk or hardware; discard on close/reload or firmware profile change. New window uses existing FanCenter.qml path, no changes to installation manifests. Test opening from all entry points, close and reopen, resize, both monitor setups, profile changes, data refresh and graph edit/discard; runtime not yet verified. References: https://quickshell.org/docs/v0.3.2/types/Quickshell/FloatingWindow/ and https://asus-linux.org/faq/asusctl/custom-fan-curves/.
