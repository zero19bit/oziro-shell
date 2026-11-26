import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Pipewire

PanelWindow {
    id: bar
    required property var prefs
    required property var niriBackend
    required property string clockText
    signal openLauncher()
    signal openControls()
    signal openNotifications()
    signal openWidgets()
    signal openPower()
    readonly property var monitor: !niriBackend.enabled && screen ? Hyprland.monitorFor(screen) : null
    readonly property var sink: Pipewire.defaultAudioSink
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
    implicitHeight: bar.prefs.panelHeight
    color: "transparent"
    Rectangle {
        anchors.fill: parent
        radius: bar.prefs.layoutMode === "floating" ? 15 : 0
        color: bar.prefs.surfaceColor
        border.color: bar.prefs.outline
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            anchors.topMargin: 6
            anchors.bottomMargin: 6
            spacing: 5
            PanelChip { prefs: bar.prefs; label: "OZIRO"; kind: "brand"; enabled: !bar.prefs.panelOnly; selected: true; onActivated: bar.openLauncher() }
            Rectangle { width: 1; height: 20; color: bar.prefs.outline; visible: bar.width >= 480 }
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
                    spacing: 3
                    Repeater {
                        model: bar.niriBackend.enabled ? 0 : Hyprland.workspaces
                        PanelChip {
                            required property var modelData
                            prefs: bar.prefs
                            visible: bar.monitor !== null && modelData.monitor === bar.monitor
                            label: modelData.name
                            kind: "workspace"
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
                            kind: "workspace"
                            selected: modelData.is_active
                            enabled: bar.niriBackend.ready && bar.niriBackend.targetId === null
                            onActivated: bar.niriBackend.activate(modelData.id)
                        }
                    }
                    Text {
                        visible: bar.niriBackend.enabled ? !bar.niriBackend.ready : bar.monitor === null
                        text: bar.niriBackend.enabled ? "Niri reconnecting" : "No Hyprland"
                        color: bar.prefs.muted
                        font.pixelSize: 11
                        textFormat: Text.PlainText
                    }
                }
            }
            Item { Layout.fillWidth: true }
            Text {
                text: bar.clockText
                textFormat: Text.PlainText
                color: bar.prefs.foreground
                font.pixelSize: 13
                font.weight: Font.DemiBold
                visible: bar.width >= 650
            }
            Item { Layout.fillWidth: true }
            RowLayout {
                visible: bar.prefs.batteryPercent >= 0 && bar.width >= 480
                spacing: 5
                Rectangle {
                    width: 20; height: 11; radius: 3
                    color: "transparent"; border.width: 1; border.color: bar.prefs.muted
                    Rectangle {
                        x: 2; y: 2; height: 7
                        width: 16 * Math.max(0,Math.min(100,bar.prefs.batteryPercent))/100
                        radius: 1
                        color: bar.prefs.batteryPercent <= 15 ? "#ef6464" : bar.prefs.accent
                    }
                    Rectangle { x: parent.width; anchors.verticalCenter: parent.verticalCenter; width: 2; height: 5; radius: 1; color: bar.prefs.muted }
                }
                Text {
                    text: (bar.prefs.powerSource === "ac" ? "AC " : bar.prefs.powerSource === "unknown" ? "? " : "") + bar.prefs.batteryPercent + "%"
                    color: bar.prefs.foreground
                    font.pixelSize: 12
                    font.weight: Font.Medium
                }
            }
            PanelChip {
                prefs: bar.prefs
                enabled: !bar.prefs.nestedPreview && Pipewire.ready && bar.sink !== null && bar.sink.audio !== null
                label: !Pipewire.ready || bar.sink === null || bar.sink.audio === null ? "No audio" : bar.sink.audio.muted ? "Muted" : "Vol " + Math.round(bar.sink.audio.volume * 100) + "%"
                onActivated: { if (enabled) bar.sink.audio.muted = !bar.sink.audio.muted }
            }
            PanelChip {
                prefs: bar.prefs
                enabled: !bar.prefs.panelOnly
                label: bar.prefs.notificationBackend ? "Alerts " + bar.prefs.notificationCount : "Alerts"
                onActivated: bar.openNotifications()
            }
            PanelChip { prefs: bar.prefs; enabled: !bar.prefs.panelOnly; visible: bar.width >= 800; label: "Widgets"; onActivated: bar.openWidgets() }
            Rectangle { width: 1; height: 20; color: bar.prefs.outline; visible: bar.width >= 480 }
            PanelChip { prefs: bar.prefs; enabled: !bar.prefs.panelOnly; label: bar.prefs.eco ? "Eco · Controls" : "Controls"; onActivated: bar.openControls() }
            PanelChip { prefs: bar.prefs; enabled: !bar.prefs.panelOnly; label: "Power"; onActivated: bar.openPower() }
        }
    }
}
