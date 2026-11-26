import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower

PanelWindow {
    id: bar
    required property var prefs
    required property string clockText
    signal openLauncher()
    signal openControls()
    readonly property var monitor: screen ? Hyprland.monitorFor(screen) : null
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var battery: UPower.displayDevice
    readonly property bool batteryReady: battery !== null && battery.ready && battery.isLaptopBattery
    anchors { top: bar.prefs.layoutMode !== "bottom"; bottom: bar.prefs.layoutMode === "bottom"; left: true; right: true }
    margins { top: bar.prefs.layoutMode === "floating" ? 8 : 0; left: bar.prefs.layoutMode === "floating" ? 12 : 0; right: left }
    implicitHeight: 48
    color: "transparent"
    Rectangle {
        anchors.fill: parent
        radius: bar.prefs.layoutMode === "floating" ? 15 : 0
        color: bar.prefs.surfaceColor
        border.color: bar.prefs.outline
        RowLayout {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 8
            Chip { prefs: bar.prefs; label: "OZIRO"; selected: true; onActivated: bar.openLauncher() }
            Flickable {
                Layout.fillWidth: true
                Layout.maximumWidth: Math.max(40, bar.width * 0.38)
                Layout.fillHeight: true
                contentWidth: workspaceRow.implicitWidth
                contentHeight: height
                clip: true
                Row {
                    id: workspaceRow
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 4
                    Repeater {
                        model: Hyprland.workspaces
                        Chip {
                            required property var modelData
                            prefs: bar.prefs
                            visible: bar.monitor !== null && modelData.monitor === bar.monitor
                            label: modelData.name
                            selected: modelData.active
                            onActivated: modelData.activate()
                        }
                    }
                    Text { visible: bar.monitor === null; text: "No Hyprland"; color: bar.prefs.muted }
                }
            }
            Item { Layout.fillWidth: true }
            Text { text: bar.clockText; color: bar.prefs.foreground; font.pixelSize: 13; visible: bar.width >= 650 }
            Item { Layout.fillWidth: true }
            Text {
                visible: bar.batteryReady && bar.width >= 480
                text: bar.batteryReady ? (UPower.onBattery ? "" : "AC ") + Math.round(bar.battery.percentage * 100) + "%" : ""
                color: bar.prefs.foreground
                font.pixelSize: 12
            }
            Chip {
                prefs: bar.prefs
                enabled: Pipewire.ready && bar.sink !== null && bar.sink.audio !== null
                label: !enabled ? "No audio" : bar.sink.audio.muted ? "Muted" : "Vol " + Math.round(bar.sink.audio.volume * 100) + "%"
                onActivated: { if (enabled) bar.sink.audio.muted = !bar.sink.audio.muted }
            }
            Chip { prefs: bar.prefs; label: bar.prefs.eco ? "Eco · Controls" : "Controls"; onActivated: bar.openControls() }
        }
    }
}
