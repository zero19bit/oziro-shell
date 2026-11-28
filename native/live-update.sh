#!/usr/bin/env bash
# Experimental live update. No logout or service restart.
set -euo pipefail
umask 077
export PATH=/usr/bin:/bin
dir="$(cd -- "$(dirname -- "$0")" && pwd -P)"
parent=/usr/local/lib
dest="$parent/oziro-login-preview"
entry=/usr/share/wayland-sessions/oziro-preview.desktop
files=(Chip.qml MenuRow.qml StatusButton.qml OziroTooltip.qml ShellPopup.qml PanelChip.qml AccentSlider.qml SectionLabel.qml QuickToggle.qml Preferences.qml NiriBackend.qml WindowModel.js Dock.qml DockIcon.qml DockMotion.js dock-apps.svg dock-settings.svg TopBar.qml Launcher.qml ControlCenter.qml WifiCenter.qml wifi-manager.py BluetoothCenter.qml ThemeStudio.qml WallpaperPolicy.js ThemeIdentity.js oziro-mark.svg wallpaper-midnight.svg wallpaper-graphite.svg wallpaper-aurora.svg wallpaper-porcelain.svg WallpaperCenter.qml WallpaperSurface.qml EnergyEngine.qml EnergyPolicy.js EnergyCenter.qml WidgetRegistry.js WidgetCenter.qml TrayCenter.qml SettingsCenter.qml PowerCenter.qml power-action.sh LockCenter.qml oziro-lock.conf lock-session.sh energy-status.sh power-sample.sh SystemControls.qml system-controls.sh NotificationBackend.qml NotificationCenter.qml NotificationToast.qml session-candidate.kdl shell.qml)
fail() { echo "FAIL: $*" >&2; exit 1; }
regular() { [[ -f "$1" && ! -L "$1" && -s "$1" ]]; }
owned() { regular "$1" && [[ $(stat -c %u "$1") == 0 ]] && (( (8#$(stat -c %a "$1") & 022) == 0 )); }
safe_dir() { [[ -d "$1" && ! -L "$1" && $(stat -c %u "$1") == 0 ]] && (( (8#$(stat -c %a "$1") & 022) == 0 )); }
known() {
    local f
    for f in "${files[@]}"; do [[ "$1" == "$f" ]] && return 0; done
    return 1
}
inspect_install() {
    local p name
    safe_dir "$parent" && safe_dir "$dest" || fail "Unsafe or missing installation"
    owned "$dest/.oziro-preview-install" && [[ $(cat "$dest/.oziro-preview-install") == oziro-login-preview-v1 ]] || fail "Install marker mismatch"
    owned "$entry" && owned "$dest/oziro-preview.desktop" && cmp -s "$entry" "$dest/oziro-preview.desktop" || fail "Session entry mismatch"
    owned "$dest/login-session.sh" && owned "$dest/shell.qml" && owned "$dest/session-candidate.kdl" || fail "Incomplete installation"
    shopt -s dotglob nullglob
    for p in "$dest"/*; do
        name=$(basename -- "$p")
        owned "$p" || fail "Unexpected file: $name"
        case "$name" in .oziro-preview-install|login-session.sh|oziro-preview.desktop) ;; *) known "$name" || fail "Unknown installed file: $name";; esac
    done
}
check_source() {
    local f
    for f in "${files[@]}" login-session.sh oziro-preview.desktop; do
        regular "$dir/$f" || fail "Missing source: $f"
        if [[ "$f" == *.sh ]]; then bash -n "$dir/$f" || fail "Shell syntax: $f"; fi
    done
    cmp -s "$dir/login-session.sh" "$dest/login-session.sh" || fail "Login launcher changed; offline upgrade required"
    cmp -s "$dir/oziro-preview.desktop" "$dest/oziro-preview.desktop" || fail "Session entry changed; offline upgrade required"
}
[[ $# -ge 1 ]] || fail "Use --check, --apply or --rollback BACKUP"
action=$1
case "$action" in
    --check|--apply) [[ $# == 1 ]] || fail "Unexpected arguments";;
    --rollback) [[ $# == 2 ]] || fail "Specify backup path";;
    *) fail "Unknown action";;
esac
inspect_install
if [[ "$action" == --check ]]; then
    [[ $(id -u) != 0 ]] || fail "Run check as desktop user"
    check_source
    /usr/bin/niri validate --config "$dir/session-candidate.kdl" || fail "Invalid Niri config"
    echo "PASS: source, installation, unchanged launcher and Niri config"
    exit 0
fi
[[ $(id -u) == 0 ]] || fail "Use sudo for apply or rollback"
lock="$parent/.oziro-live-update.lock"
if [[ -e "$lock" || -L "$lock" ]]; then
    [[ -f "$lock" && ! -L "$lock" && $(stat -c %u "$lock") == 0 ]] || fail "Unsafe lock"
fi
exec 9>"$lock"
flock -n 9 || fail "Another update is running"
inspect_install
backup_source=
if [[ "$action" == --apply ]]; then
    check_source
    [[ -n "${SUDO_USER:-}" && "$SUDO_USER" != root ]] || fail "Run via sudo from desktop user"
    /usr/bin/runuser -u "$SUDO_USER" -- /usr/bin/niri validate --config "$dir/session-candidate.kdl" || fail "Invalid Niri config"
else
    backup_source=$2
    [[ "$backup_source" =~ ^/usr/local/lib/\.oziro-live-backup\.[A-Za-z0-9]+$ ]] || fail "Invalid backup path"
    safe_dir "$backup_source" && owned "$backup_source/.oziro-live-backup" || fail "Invalid backup"
    [[ $(cat "$backup_source/.oziro-live-backup") == oziro-live-v1 ]] || fail "Backup marker mismatch"
    owned "$backup_source/shell.qml" && owned "$backup_source/session-candidate.kdl" || fail "Incomplete backup"
    for p in "$backup_source"/*; do
        name=$(basename -- "$p")
        owned "$p" || fail "Unsafe backup file"
        [[ "$name" == .oziro-live-backup ]] || known "$name" || fail "Unknown backup file"
    done
fi
backup="$(mktemp -d "$parent/.oziro-live-backup.XXXXXXXX")"
stage="$(mktemp -d "$parent/.oziro-live-stage.XXXXXXXX")"
trap 'rm -rf -- "$stage"' EXIT
for f in "${files[@]}"; do
    if [[ -f "$dest/$f" ]]; then install -o root -g root -m 644 -- "$dest/$f" "$backup/$f"; fi
    if [[ "$action" == --apply ]]; then
        install -o root -g root -m 644 -- "$dir/$f" "$stage/$f"
    elif [[ -f "$backup_source/$f" ]]; then
        install -o root -g root -m 644 -- "$backup_source/$f" "$stage/$f"
    fi
done
printf 'oziro-live-v1\n' > "$backup/.oziro-live-backup"
echo "Backup: $backup"
for f in "$stage"/*.sh; do bash -n "$f" || fail "Staged Bash syntax: $f"; done
restore_on_error() {
    local rc=$? f
    trap - ERR
    echo "Update failed. Attempting file rollback from $backup" >&2
    for f in "${files[@]}"; do
        if [[ -f "$backup/$f" ]]; then
            install -o root -g root -m 644 -- "$backup/$f" "$stage/restore" && mv -fT -- "$stage/restore" "$dest/$f" || echo "Restore failed: $f" >&2
        elif [[ -f "$dest/$f" ]]; then
            rm -- "$dest/$f" || echo "Restore failed: $f" >&2
        fi
    done
    exit "$rc"
}
trap restore_on_error ERR
changed=0
for f in "${files[@]}"; do
    if [[ -f "$stage/$f" ]]; then
        if [[ "$f" == shell.qml ]] || ! cmp -s "$stage/$f" "$dest/$f"; then
            mv -fT -- "$stage/$f" "$dest/$f"
            changed=$((changed+1))
        fi
    elif [[ "$action" == --rollback && -f "$dest/$f" ]]; then
        rm -- "$dest/$f"
        changed=$((changed+1))
    fi
done
trap - ERR
echo "Published $changed files. File watchers should reload."
# Re-notify directory/file watchers after atomic publication. This is best effort;
# the explicit unprivileged IPC reload is the reliable runtime verification path.
touch -- "$dest/shell.qml" "$dest/Dock.qml"
echo "From the Oziro desktop user (not sudo): quickshell -p $dest ipc call oziroDev reload"
echo "Check runtime: quickshell -p $dest ipc call oziroDev revision"
echo "No logout, compositor restart, SDDM modification or preference deletion performed."
echo "Runtime reload is not confirmed; inspect desktop and logs."
echo "Rollback: sudo bash native/live-update.sh --rollback $backup"
