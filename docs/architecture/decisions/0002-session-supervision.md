# ADR 0002: User-level systemd supervision

- Status: Accepted
- Date: 2026-11-18

## Context

Oziro is a Wayland shell process that must run as the logged-in desktop user.
A process crash should not require the user to restart the whole desktop
session. The shell also needs the active Wayland and compositor environment,
which is not safe to assume is present when the user systemd manager first
starts.

## Decision

Use a user-level systemd service with bounded `Restart=on-failure` recovery.
Start it through `oziro-session-start`, which imports the active session
environment before asking the user manager to start the service.

The unit is deliberately not enabled from `default.target`; this avoids
starting a Wayland shell before a graphical session exists. KDE receives an
XDG autostart entry. Hyprland users opt in with one `exec-once` line. Oziro
never edits either desktop's configuration automatically.

The installed frontend directory is supplied through
`OZIRO_FRONTEND_DIR`, while development builds retain the repository-relative
frontend path.

## Consequences

- A crashed host is restarted without restarting the desktop session.
- Restart attempts are rate-limited to avoid a crash loop.
- Oziro remains an ordinary user process and never needs root privileges.
- Session startup remains explicit and reversible.
- Arch package installation and upgrade behavior still needs a clean-machine
  smoke test before release.
