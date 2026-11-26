#!/usr/bin/env bash
# Installs an isolated user copy; never touches compositor configs or autostart.
set -euo pipefail
[[ $(id -u) -ne 0 ]] || { echo "Do not run as root." >&2; exit 1; }
src="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
data="${XDG_DATA_HOME:-$HOME/.local/share}"
[[ "$data" == /* ]] || { echo "XDG_DATA_HOME must be absolute" >&2; exit 1; }
dest="$data/oziro-shell/v2"
if [[ -e "$dest" || -L "$dest" ]]; then
  echo "Refusing to overwrite $dest. Use the source tree for testing or move the existing copy first." >&2
  exit 1
fi
command -v quickshell >/dev/null || { echo "Install quickshell from Arch Extra first." >&2; exit 1; }
umask 077
mkdir -p -- "$(dirname -- "$dest")"
mkdir -- "$dest"
for f in shell.qml Chip.qml PanelChip.qml AccentSlider.qml SectionLabel.qml QuickToggle.qml Preferences.qml NiriBackend.qml WindowModel.js Dock.qml DockIcon.qml TopBar.qml Launcher.qml ControlCenter.qml ThemeStudio.qml EnergyEngine.qml EnergyPolicy.js EnergyCenter.qml WidgetRegistry.js WidgetCenter.qml energy-status.sh power-sample.sh SystemControls.qml system-controls.sh NotificationBackend.qml NotificationCenter.qml NotificationToast.qml notification-test.sh doctor.sh benchmark.sh measure.sh preflight.sh; do
  install -m 600 -- "$src/$f" "$dest/$f"
done
printf 'Installed experimental user copy: %s\nRun: quickshell -p %q\n' "$dest" "$dest"
