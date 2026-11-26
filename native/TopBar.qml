import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Pipewire

PanelWindow {
    id: bar
    required property string clockText
    readonly property var monitor: screen ? Hyprland.monitorFor(screen) : null
    readonly property var sink: Pipewire.defaultAudioSink
    anchors { top: true; left: true; right: true }
    margins { top: 8; left: 12; right: 12 }
    implicitHeight: 46
    color: "transparent"

    Rectangle {
        anchors.fill: parent
        radius: 15
        color: "#ee141923"
        border.color: "#34404f"
        border.width: 1
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: 10

            Text {
                text: "O Z I R O"
                color: "#b6e4ff"
                font.pixelSize: 13
                font.bold: true
            }
            Rectangle { Layout.preferredWidth: 1; Layout.preferredHeight: 20; color: "#34404f" }
            RowLayout {
                spacing: 4
                Repeater {
                    model: Hyprland.workspaces
                    delegate: Chip {
                        required property var modelData
                        visible: bar.monitor !== null && modelData.monitor === bar.monitor
                        label: modelData.name
                        selected: modelData.active
                        onActivated: modelData.activate()
                    }
                }
                Text {
                    visible: bar.monitor === null
                    text: "Hyprland unavailable"
                    color: "#a8b4c3"
                    font.pixelSize: 12
                }
            }
            Item { Layout.fillWidth: true }
            Text {
                text: bar.clockText
                color: "#eef3fa"
                font.pixelSize: 13
                font.weight: Font.Medium
            }
            Item { Layout.fillWidth: true }
            Chip {
                enabled: Pipewire.ready && bar.sink !== null && bar.sink.audio !== null
                label: !enabled ? "Audio unavailable" : bar.sink.audio.muted ? "Muted" : "Vol " + Math.round(bar.sink.audio.volume * 100) + "%"
                selected: enabled && !bar.sink.audio.muted
                onActivated: {
                    if (enabled) bar.sink.audio.muted = !bar.sink.audio.muted
                }
            }
            Text {
                text: bar.screen ? bar.screen.name : ""
                color: "#a8b4c3"
                font.pixelSize: 11
                elide: Text.ElideRight
                Layout.maximumWidth: 100
            }
        }
    }
}
