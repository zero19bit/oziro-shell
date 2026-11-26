import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower

PanelWindow {
    id: win
    required property var prefs
    signal dismiss()
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property bool audioReady: Pipewire.ready && sink !== null && sink.audio !== null
    anchors { top: win.prefs.layoutMode !== "bottom"; bottom: win.prefs.layoutMode === "bottom"; right: true }
    margins { top: 62; bottom: 62; right: 12 }
    implicitWidth: Math.min(420, screen ? screen.width - 24 : 420)
    implicitHeight: Math.min(430, screen ? screen.height - 140 : 430)
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    color: "transparent"
    Rectangle {
        anchors.fill: parent
        color: win.prefs.surfaceColor
        border.color: win.prefs.outline
        radius: 20
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 18
            spacing: 10
            RowLayout {
                Text { text: "Control Center"; color: win.prefs.foreground; font.pixelSize: 20; font.bold: true; Layout.fillWidth: true }
                Chip { prefs: win.prefs; label: "Close"; onActivated: win.dismiss() }
            }
            ScrollView {
                Layout.fillHeight: true
                Layout.fillWidth: true
                contentWidth: availableWidth
                ColumnLayout {
                    width: parent.width
                    spacing: 10
                    Text { text: win.audioReady ? "Audio output" : "Audio unavailable"; color: win.prefs.muted }
                    RowLayout {
                        Layout.fillWidth: true
                        Slider {
                            Layout.fillWidth: true
                            enabled: win.audioReady
                            from: 0; to: 1
                            value: win.audioReady ? Math.min(1, win.sink.audio.volume) : 0
                            onMoved: { if (win.audioReady) win.sink.audio.volume = value }
                        }
                        Chip {
                            prefs: win.prefs
                            enabled: win.audioReady
                            label: enabled && win.sink.audio.muted ? "Unmute" : "Mute"
                            onActivated: { if (enabled) win.sink.audio.muted = !win.sink.audio.muted }
                        }
                    }
                    Text { text: "Energy / shell effects"; color: win.prefs.accent; font.bold: true }
                    RowLayout {
                        Chip { prefs: win.prefs; label: "Reduce effects"; selected: win.prefs.reduceEffects; onActivated: win.prefs.reduceEffects = !win.prefs.reduceEffects }
                        Chip { prefs: win.prefs; label: "Auto on battery"; selected: win.prefs.autoEco; onActivated: win.prefs.autoEco = !win.prefs.autoEco }
                    }
                    Text { text: win.prefs.eco ? "Eco rendering active" : "Standard rendering active"; color: win.prefs.muted }
                    Text { text: "Appearance"; color: win.prefs.accent; font.bold: true }
                    Flow {
                        Layout.fillWidth: true
                        spacing: 6
                        Repeater {
                            model: ["glass","material","minimal","cyber","light"]
                            Chip { required property string modelData; prefs: win.prefs; label: modelData; selected: win.prefs.theme === modelData; onActivated: win.prefs.theme = modelData }
                        }
                    }
                    Text { text: "Panel layout"; color: win.prefs.accent; font.bold: true }
                    Flow {
                        Layout.fillWidth: true
                        spacing: 6
                        Repeater {
                            model: ["floating","top","bottom"]
                            Chip { required property string modelData; prefs: win.prefs; label: modelData; selected: win.prefs.layoutMode === modelData; onActivated: win.prefs.layoutMode = modelData }
                        }
                    }
                    Text { Layout.fillWidth: true; text: win.prefs.settingsStatus; color: win.prefs.muted; font.pixelSize: 12 }
                    Text { Layout.fillWidth: true; wrapMode: Text.WordWrap; text: "Eco changes shell effects, not CPU or hardware power limits."; color: win.prefs.muted; font.pixelSize: 11 }
                }
            }
        }
    }
}
