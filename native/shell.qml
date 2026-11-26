import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower

ShellRoot {
    id: shell
    // Shared session preferences. Persistence is a separate milestone.
    property string theme: "glass"
    property string layoutMode: "floating"
    property bool reduceEffects: false
    property bool autoEco: true
    readonly property bool eco: reduceEffects || (autoEco && UPower.onBattery)
    readonly property color surfaceColor: theme === "light" ? "#f3f5f9" : theme === "material" ? "#25243a" : theme === "cyber" ? "#141127" : theme === "glass" && !eco ? "#e61a202b" : "#1a202b"
    readonly property color foreground: theme === "light" ? "#202939" : "#edf2fa"
    readonly property color accent: theme === "light" ? "#285b9b" : theme === "material" ? "#bcb0ff" : theme === "cyber" ? "#7df9ff" : "#93d9e9"
    readonly property color selectedText: theme === "light" ? "#ffffff" : "#111827"
    readonly property color muted: theme === "light" ? "#536173" : "#a8b4c4"
    readonly property color outline: theme === "light" ? "#cbd5e1" : "#364253"
    SystemClock { id: clock; precision: SystemClock.Minutes }
    PwObjectTracker { objects: Pipewire.defaultAudioSink ? [Pipewire.defaultAudioSink] : [] }
    Variants {
        model: Quickshell.screens
        Scope {
            id: output
            required property var modelData
            property string popup: ""
            function toggle(name) { popup = popup === name ? "" : name }
            TopBar {
                screen: output.modelData
                prefs: shell
                clockText: Qt.formatDateTime(clock.date, "ddd, MMM d  ·  HH:mm")
                onOpenLauncher: output.toggle("launcher")
                onOpenControls: output.toggle("controls")
            }
            Loader {
                active: output.popup === "launcher"
                sourceComponent: Launcher {
                    screen: output.modelData
                    prefs: shell
                    onDismiss: output.popup = ""
                }
            }
            Loader {
                active: output.popup === "controls"
                sourceComponent: ControlCenter {
                    screen: output.modelData
                    prefs: shell
                    onDismiss: output.popup = ""
                }
            }
        }
    }
}
