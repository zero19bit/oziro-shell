# Development policy

## Workflow
- Active branch: oziro-v2-native-prototype. Keep main untouched until an explicitly reviewed merge. Small scoped commits, meaningful messages, docs and test record with each milestone.
- Implement and inspect diff; run available static/unit checks; request actual runtime evidence from the user when no Wayland runtime is available. Never invent results or describe committed code as tested.
- Use nested preview for normal UI iteration. Real login/install/reboot only when needed, with explicit user initiation and recovery instructions.
- Preserve a known-good Ryoku entry. No automatic system-wide changes, service disabling, PAM edits or replacement of user configuration. Privileged installation must be opt-in, scoped, reviewable and removable.
- Avoid deleting/replacing user preferences and data; support rollback. Installation upgrades require safe versioned payload strategy (current remove/check/install is experimental).

## Security and privacy
- Lock via real Wayland session-lock implementation and PAM; never collect passwords in shell UI, log credentials or simulate lock with overlay.
- Power actions require explicit confirmation, current session verification and normal logind authorization; no force, sudo bypass or insecure suspend.
- Do not ship API keys, passwords, tokens, private paths or user-identifying logs. Public issue/test reports must be sanitized.
- No telemetry by default. Network-dependent features explicit opt-in. Treat downloaded assets and widget manifests as untrusted; no arbitrary JS/shell commands or privilege escalation.
- Document dependency versions, third-party licenses and asset provenance before release.

## Release policy
Pre-release versions remain experimental. Distinguish implemented, unit-tested, user-confirmed, and release-verified. No 1.0 until security, lifecycle, regression, recovery and performance gates are satisfied. No claimed support for untested compositors or savings without measured evidence.

## Experimental live development update (0.9.24 tooling)
From the running Oziro session, save work, close menus and finish any active lock/power/network action. As desktop user run `git pull --ff-only`, `bash native/preflight.sh`, `bash native/audit-check.sh`, `bash native/live-update.sh --check`; then explicitly run `sudo bash native/live-update.sh --apply`. No logout/reinstall is intended for supported payload changes. Quickshell and Niri file watchers should reload; the command does not certify runtime success. Files are staged and individually atomically replaced (not a whole-payload transaction), shell.qml last. Root-owned backup path is printed; restore with `sudo bash native/live-update.sh --rollback BACKUP`. A crash or power loss during publication may require recovery from a TTY. Login launcher/SDDM changes require offline upgrade; no forced process restart. Only known Oziro files are touched, no user preferences. Backups are retained outside installation. Future files must be added to installer and live-update allowlists. Experimental, real-session verification pending.
