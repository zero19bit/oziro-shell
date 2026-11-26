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
    readonly property string settingsStatus: settings.status
    readonly property bool panelOnly: Quickshell.env("OZIRO_PANEL_ONLY") === "1"
    readonly property bool eco: reduceEffects || (autoEco && UPower.onBattery)
    readonly property color surfaceColor: theme === "light" ? "#f3f5f9" : theme === "material" ? "#25243a" : theme === "cyber" ? "#141127" : theme === "glass" && !eco ? "#e61a202b" : "#1a202b"
    readonly property color foreground: theme === "light" ? "#202939" : "#edf2fa"
    readonly property color accent: theme === "light" ? "#285b9b" : theme === "material" ? "#bcb0ff" : theme === "cyber" ? "#7df9ff" : "#93d9e9"
    readonly property color selectedText: theme === "light" ? "#ffffff" : "#111827"
    readonly property color muted: theme === "light" ? "#536173" : "#a8b4c4"
    readonly property color outline: theme === "light" ? "#cbd5e1" : "#364253"
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
                popupLoader.setSource(Qt.resolvedUrl(name === "launcher" ? "Launcher.qml" : "ControlCenter.qml"),
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
                clockText: Qt.formatDateTime(clock.date, "ddd, MMM d  ·  HH:mm")
                onOpenLauncher: output.toggle("launcher")
                onOpenControls: output.toggle("controls")
            }
            Loader { id: popupLoader }
            Connections {
                target: popupLoader.item
                function onDismiss() { Qt.callLater(output.closePopup); }
            }
            }
        }
    }
}
