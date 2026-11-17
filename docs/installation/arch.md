# Installing Oziro on Arch Linux

Oziro is an independent Wayland shell. The package installs the shell host,
the built React frontend, a user-level systemd service, and a session launcher.
It does not replace Plasma, edit Hyprland configuration, or run as root.

## Requirements

- Arch Linux, x86_64
- A Wayland session (initially targeted: KDE Plasma/KWin and Hyprland)
- \`base-devel\` and \`git\` to build the package
- Runtime services such as PipeWire, NetworkManager, BlueZ, and UPower are
  optional; matching controls report unavailable when their service is absent

## Build and install

~~~bash
sudo pacman -S --needed base-devel git
git clone https://github.com/zero19bit/oziro-shell.git
cd oziro-shell
makepkg -si
~~~

The PKGBUILD builds the React bundle and Rust host locally, then installs the
frontend under \`/usr/share/oziro/shell-ui\`.

## Start Oziro

The package provides \`oziro-session-start\`. It imports the active Wayland,
D-Bus, and compositor environment into the user systemd manager, then starts
\`oziro-shell.service\`.

### KDE Plasma

The package installs an XDG autostart entry for KDE. Log out and back in, or
start it manually:

~~~bash
oziro-session-start
~~~

### Hyprland

No Hyprland configuration is changed automatically. Add this line to
\`~/.config/hypr/hyprland.conf\` if you want Oziro to start with the session:

~~~ini
exec-once = oziro-session-start
~~~

Then reload or restart the Hyprland session.

## Session recovery and diagnostics

The user service restarts Oziro after an abnormal process exit, with a
three-second delay and a bounded start rate (five starts per minute). This
prevents an endless rapid crash loop. A deliberate \`systemctl --user stop\`
does not trigger a restart.

~~~bash
systemctl --user status oziro-shell.service
journalctl --user -u oziro-shell.service -f
systemctl --user stop oziro-shell.service
systemctl --user reset-failed oziro-shell.service
~~~

If the service reaches the start limit, inspect the journal before resetting
the failure state. Do not run the shell with \`sudo\`.

## Uninstall

~~~bash
sudo pacman -Rns oziro-shell
~~~

If you added the Hyprland \`exec-once\` line manually, remove that line yourself.
The package does not delete user settings from \`~/.config/oziro\`.

## Packaging status

The PKGBUILD, systemd unit, and CI checks are included in the repository.
A clean-machine Arch install/upgrade smoke test is still required before
calling the package release-ready.
