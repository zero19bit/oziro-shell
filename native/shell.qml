//@ pragma StateDir $BASE/oziro-shell/v2
import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower

ShellRoot {
    id: shell
    Preferences { id: settings }
    property alias theme: settings.theme
    property alias layoutMode: settings.layoutMode
    property alias reduceEffects: settings.reduceEffects
    property alias autoEco: settings.autoEco
    property alias dockEnabled: settings.dockEnabled
    property alias pinnedApps: settings.pinnedApps
    property alias customAccent: settings.customAccent
    property alias panelHeight: settings.panelHeight
    property alias dockIconSize: settings.dockIconSize
    property alias clock24Hour: settings.clock24Hour
    function resetAppearance() { settings.resetAppearance(); }
    function setAccent(value) {
        if (value === "" || /^#[0-9a-fA-F]{6}$/.test(value)) customAccent = value.toLowerCase();
    }
    readonly property int popupMargin: panelHeight + 14
    function linearChannel(c) { return c <= 0.04045 ? c / 12.92 : Math.pow((c + 0.055) / 1.055, 2.4); }
    function togglePin(id) {
        if (typeof id !== "string" || !id.length || id.length > 256) return;
        if (pinnedApps.includes(id)) pinnedApps = pinnedApps.filter(value => value !== id);
        else if (pinnedApps.length < 12) pinnedApps = pinnedApps.concat([id]);
    }
    readonly property string settingsStatus: settings.status
    readonly property bool panelOnly: Quickshell.env("OZIRO_PANEL_ONLY") === "1"
    readonly property bool eco: reduceEffects || (autoEco && UPower.onBattery)
    readonly property color surfaceColor: theme === "light" ? "#f3f5f9" : theme === "material" ? "#25243a" : theme === "cyber" ? "#141127" : theme === "glass" && !eco ? "#e61a202b" : "#1a202b"
    readonly property color foreground: theme === "light" ? "#202939" : "#edf2fa"
    readonly property color accent: customAccent !== "" ? customAccent : theme === "light" ? "#285b9b" : theme === "material" ? "#bcb0ff" : theme === "cyber" ? "#7df9ff" : "#93d9e9"
    readonly property real accentLuminance: 0.2126 * linearChannel(accent.r) + 0.7152 * linearChannel(accent.g) + 0.0722 * linearChannel(accent.b)
    readonly property color selectedText: accentLuminance > 0.179 ? "#000000" : "#ffffff"
    readonly property color muted: theme === "light" ? "#536173" : "#a8b4c4"
    readonly property color outline: theme === "light" ? "#cbd5e1" : "#364253"
    readonly property bool notificationRequested: Quickshell.env("OZIRO_NOTIFICATIONS") === "1" && !panelOnly
    property bool quietNotifications: false
    readonly property var notificationBackend: notificationLoader.item
    readonly property int notificationCount: notificationBackend ? notificationBackend.count : 0
    Loader {
        id: notificationLoader
        active: shell.notificationRequested
        source: active ? Qt.resolvedUrl("NotificationBackend.qml") : ""
    }
    NiriBackend { id: niri }
    SystemClock { id: clock; precision: SystemClock.Minutes }
    PwObjectTracker { objects: Pipewire.defaultAudioSink ? [Pipewire.defaultAudioSink] : [] }
    Variants {
        model: Quickshell.screens
        Scope {
            id: output
            required property var modelData
            property string popup: ""
            function toggle(name) {
                if (shell.panelOnly) return;
                if (popup === name) { closePopup(); return; }
                popup = name;
                popupLoader.setSource(Qt.resolvedUrl(name === "launcher" ? "Launcher.qml" : name === "notifications" ? "NotificationCenter.qml" : name === "settings" ? "ThemeStudio.qml" : "ControlCenter.qml"),
                                      {screen: output.modelData, prefs: shell});
            }
            function closePopup() {
                popup = "";
                popupLoader.source = "";
            }
            TopBar {
                screen: output.modelData
                prefs: shell
                niriBackend: niri
                clockText: Qt.formatDateTime(clock.date, shell.clock24Hour ? "ddd, MMM d  ·  HH:mm" : "ddd, MMM d  ·  h:mm AP")
                onOpenLauncher: output.toggle("launcher")
                onOpenControls: output.toggle("controls")
                onOpenNotifications: output.toggle("notifications")
            }
            Loader { id: popupLoader }
            Loader {
                active: shell.notificationBackend !== null && !shell.quietNotifications
                    && Quickshell.screens[0] === output.modelData
                source: active ? Qt.resolvedUrl("NotificationToast.qml") : ""
                onLoaded: {
                    item.screen = output.modelData;
                    item.prefs = shell;
                    item.backend = shell.notificationBackend;
                }
            }
            Loader {
                id: dockLoader
                active: shell.dockEnabled && !shell.panelOnly
                sourceComponent: Component {
                    Dock {
                        screen: output.modelData
                        prefs: shell
                        niriBackend: niri
                        onOpenLauncher: output.toggle("launcher")
                    }
                }
            }
            Connections {
                target: popupLoader.item
                ignoreUnknownSignals: true
                function onDismiss() { Qt.callLater(output.closePopup); }
                function onOpenSettings() { Qt.callLater(() => output.toggle("settings")); }
            }
        }
    }
}
