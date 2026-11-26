import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower

PanelWindow {
    id: bar
    required property var prefs
    required property var niriBackend
    required property string clockText
    signal openLauncher()
    signal openControls()
    readonly property var monitor: !niriBackend.enabled && screen ? Hyprland.monitorFor(screen) : null
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var battery: {
        const aggregate = UPower.displayDevice;
        if (aggregate && aggregate.ready && aggregate.isLaptopBattery && aggregate.isPresent)
            return aggregate;
        for (const device of UPower.devices.values)
            if (device.ready && device.isLaptopBattery && device.isPresent) return device;
        return null;
    }
    readonly property bool batteryReady: battery !== null
    readonly property var niriWorkspaces: niriBackend.enabled && screen
        ? niriBackend.workspaces.filter(w => w.output === screen.name).sort((a,b) => a.idx-b.idx)
        : []
    anchors { top: bar.prefs.layoutMode !== "bottom"; bottom: bar.prefs.layoutMode === "bottom"; left: true; right: true }
    readonly property int sideMargin: prefs.layoutMode === "floating" ? 12 : 0
    margins {
        top: bar.prefs.layoutMode === "floating" ? 8 : 0
        left: bar.sideMargin
        right: bar.sideMargin
    }
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
            PanelChip { prefs: bar.prefs; label: "OZIRO"; enabled: !bar.prefs.panelOnly; selected: true; onActivated: bar.openLauncher() }
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
                        model: bar.niriBackend.enabled ? 0 : Hyprland.workspaces
                        PanelChip {
                            required property var modelData
                            prefs: bar.prefs
                            visible: bar.monitor !== null && modelData.monitor === bar.monitor
                            label: modelData.name
                            selected: modelData.active
                            onActivated: modelData.activate()
                        }
                    }
                    Repeater {
                        model: bar.niriWorkspaces
                        PanelChip {
                            required property var modelData
                            prefs: bar.prefs
                            label: modelData.name || String(modelData.idx)
                            selected: modelData.is_active
                            enabled: bar.niriBackend.ready && bar.niriBackend.targetId === null
                            onActivated: bar.niriBackend.activate(modelData.id)
                        }
                    }
                    Text {
                        visible: bar.niriBackend.enabled ? !bar.niriBackend.ready : bar.monitor === null
                        text: bar.niriBackend.enabled ? "Niri reconnecting" : "No Hyprland"
                        color: bar.prefs.muted
                    }
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
            PanelChip {
                prefs: bar.prefs
                enabled: Pipewire.ready && bar.sink !== null && bar.sink.audio !== null
                label: !enabled ? "No audio" : bar.sink.audio.muted ? "Muted" : "Vol " + Math.round(bar.sink.audio.volume * 100) + "%"
                onActivated: { if (enabled) bar.sink.audio.muted = !bar.sink.audio.muted }
            }
            PanelChip { prefs: bar.prefs; enabled: !bar.prefs.panelOnly; label: bar.prefs.eco ? "Eco · Controls" : "Controls"; onActivated: bar.openControls() }
        }
    }
}
