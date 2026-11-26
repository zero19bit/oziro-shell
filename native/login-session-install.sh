#!/usr/bin/env bash
# Review this script before installing. No existing session or service is modified.
set -euo pipefail
dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
dest=/usr/local/lib/oziro-login-preview
entry=/usr/share/wayland-sessions/oziro-preview.desktop
files=(shell.qml Chip.qml MenuRow.qml StatusButton.qml PanelChip.qml AccentSlider.qml SectionLabel.qml QuickToggle.qml Preferences.qml NiriBackend.qml WindowModel.js Dock.qml DockIcon.qml DockMotion.js dock-apps.svg dock-settings.svg TopBar.qml Launcher.qml ControlCenter.qml ThemeStudio.qml WallpaperPolicy.js ThemeIdentity.js oziro-mark.svg wallpaper-midnight.svg wallpaper-graphite.svg wallpaper-aurora.svg wallpaper-porcelain.svg WallpaperCenter.qml WallpaperSurface.qml EnergyEngine.qml EnergyPolicy.js EnergyCenter.qml WidgetRegistry.js WidgetCenter.qml TrayCenter.qml SettingsCenter.qml PowerCenter.qml power-action.sh LockCenter.qml oziro-lock.conf lock-session.sh session-candidate.kdl energy-status.sh power-sample.sh SystemControls.qml system-controls.sh NotificationBackend.qml NotificationCenter.qml NotificationToast.qml login-session.sh oziro-preview.desktop)
fail() { printf "FAIL: %s\n" "$*" >&2; exit 1; }
[[ $# -eq 1 ]] || fail "Use --check, --install or --remove"
case "$1" in --check|--install|--remove) ;; *) fail "Unknown action";; esac
if [[ "$1" == --remove ]]; then
  [[ $(id -u) -eq 0 ]] || fail "Run removal with sudo from the original desktop or TTY, not the Oziro preview"
  [[ -d "$dest" && ! -L "$dest" && -f "$dest/.oziro-preview-install" && ! -L "$dest/.oziro-preview-install" ]] || fail "Owned install marker missing; nothing removed"
  [[ "$(cat "$dest/.oziro-preview-install")" == "oziro-login-preview-v1" ]] || fail "Unexpected install marker"
  # Check everything before deleting anything, including files left by unknown releases.
  [[ $(stat -c %u "$dest") == 0 && $(stat -c %u "$dest/.oziro-preview-install") == 0 ]] || fail "Install ownership mismatch"
  shopt -s dotglob nullglob
  for installed in "$dest"/*; do
    name=${installed##*/}
    [[ -f "$installed" && ! -L "$installed" && $(stat -c %u "$installed") == 0 ]] || fail "Unexpected file type or owner: $name"
    known=0
    if [[ "$name" == .oziro-preview-install ]]; then known=1; else
      for allowed in "${files[@]}"; do [[ "$name" == "$allowed" ]] && { known=1; break; }; done
    fi
    (( known )) || fail "Unexpected installed file: $name; nothing removed"
  done
  if [[ -e "$entry" || -L "$entry" ]]; then
    [[ -f "$entry" && ! -L "$entry" && $(stat -c %u "$entry") == 0 ]] && cmp -s "$entry" "$dest/oziro-preview.desktop" || fail "Session entry changed; refusing removal"
    rm -- "$entry"
  fi
  for name in "${files[@]}"; do rm -f -- "$dest/$name"; done
  rm -- "$dest/.oziro-preview-install"
  rmdir -- "$dest" || fail "Extra files remain; inspect manually"
  echo "Removed only Oziro experimental login files. User preferences retained."
  exit 0
fi
for name in "${files[@]}"; do [[ -f "$dir/$name" && ! -L "$dir/$name" && -s "$dir/$name" ]] || fail "Missing or non-regular file: $name"; done
for name in "${files[@]}"; do if [[ "$name" == *.sh ]]; then bash -n "$dir/$name" || fail "Syntax: $name"; fi; done
for path in /usr/bin/niri /usr/bin/quickshell /usr/bin/kitty /usr/bin/hyprlock /usr/bin/dbus-run-session; do [[ -x "$path" ]] || fail "Missing $path"; done
[[ -d /usr/share/wayland-sessions ]] || fail "Wayland session directory missing"
[[ ! -e "$dest" && ! -L "$dest" && ! -e "$entry" && ! -L "$entry" ]] || fail "Existing Oziro preview install or entry; refusing overwrite"
if [[ "$1" == --check ]]; then
  /usr/bin/niri validate --config "$dir/session-candidate.kdl" || fail "Invalid Niri config"
  echo "PASS: files, Bash syntax, dependencies, Niri config and unused install paths"
  echo "No files installed. Real login remains untested."
  exit 0
fi
[[ $(id -u) -eq 0 ]] || fail "Run --check first, then use sudo for --install"
umask 022
[[ ! -L /usr/local/lib ]] || fail "Unexpected symlink: /usr/local/lib"
if [[ ! -d /usr/local/lib ]]; then mkdir -m 755 /usr/local/lib; fi
mkdir -m 755 -- "$dest"
entry_created=0
cleanup() {
  rc=$?
  if (( rc != 0 )); then
    if (( entry_created )); then rm -f -- "$entry"; fi
    for name in "${files[@]}"; do rm -f -- "$dest/$name"; done
    rm -f -- "$dest/.oziro-preview-install"
    rmdir -- "$dest" || true
  fi
}
trap cleanup EXIT
for name in "${files[@]}"; do
  mode=644; [[ "$name" == login-session.sh ]] && mode=755
  install -o root -g root -m "$mode" -- "$dir/$name" "$dest/$name"
done
printf "oziro-login-preview-v1\n" > "$dest/.oziro-preview-install"
# Publish only after the complete payload exists; no clobber.
if ! (set -o noclobber; : > "$entry"); then fail "Session entry appeared; refusing overwrite"; fi
entry_created=1
install -o root -g root -m 644 -- "$dest/oziro-preview.desktop" "$entry"
echo "Installed Oziro (Experimental). No logout or restart was performed."
echo "Original Niri/Ryoku entry and system services unchanged."
