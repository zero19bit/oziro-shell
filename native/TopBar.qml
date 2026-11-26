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
    signal openSettings()
    readonly property var monitor: !niriBackend.enabled && screen ? Hyprland.monitorFor(screen) : null
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property bool audioReady: Pipewire.ready && sink !== null && sink.audio !== null
    readonly property var niriWorkspaces: niriBackend.enabled && screen
        ? niriBackend.workspaces.filter(w => w.output === screen.name).sort((a,b) => a.idx-b.idx) : []
    readonly property var focusedWindow: niriBackend.enabled && screen
        ? niriBackend.windows.find(w => w.is_focused && niriWorkspaces.some(ws => ws.id === w.workspace_id)) : null
    anchors { top: bar.prefs.layoutMode !== "bottom"; bottom: bar.prefs.layoutMode === "bottom"; left: true; right: true }
    margins { top: bar.prefs.layoutMode === "floating" ? 6 : 0; left: bar.prefs.layoutMode === "floating" ? 10 : 0; right: bar.prefs.layoutMode === "floating" ? 10 : 0 }
    implicitHeight: bar.prefs.panelHeight
    color: "transparent"
    Rectangle {
        anchors.fill: parent
        radius: bar.prefs.layoutMode === "floating" ? 9 : 0
        color: bar.prefs.surfaceColor
        border.width: bar.prefs.layoutMode === "floating" ? 1 : 0
        border.color: bar.prefs.outline
        Rectangle { anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom; height: 1; color: bar.prefs.outline; visible: bar.prefs.layoutMode !== "floating" }
        RowLayout {
            anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 10; anchors.topMargin: 2; anchors.bottomMargin: 2; spacing: 3
            StatusButton { prefs: bar.prefs; glyph: "brand"; label: "Oziro menu"; enabled: !bar.prefs.panelOnly; onActivated: bar.openPower() }
            StatusButton { prefs: bar.prefs; glyph: "apps"; label: "Applications"; enabled: !bar.prefs.panelOnly; onActivated: bar.openLauncher() }
            
            Text {
                visible: bar.width >= 700
                Layout.maximumWidth: 180; elide: Text.ElideRight
                text: bar.focusedWindow ? (bar.focusedWindow.title || bar.focusedWindow.app_id || "Desktop") : "Desktop"
                textFormat: Text.PlainText; color: bar.prefs.muted; font.pixelSize: 12
            }
            Item { Layout.fillWidth: true }
            Flickable {
                Layout.preferredWidth: Math.min(workspaceRow.implicitWidth, Math.max(30,bar.width*0.22))
                Layout.fillHeight: true; contentWidth: workspaceRow.implicitWidth; contentHeight: height; clip: true
                Row {
                    id: workspaceRow; anchors.verticalCenter: parent.verticalCenter; spacing: 1
                    Repeater {
                        model: bar.niriBackend.enabled ? 0 : Hyprland.workspaces
                        PanelChip {
                            required property var modelData
                            prefs: bar.prefs; visible: bar.monitor !== null && modelData.monitor === bar.monitor
                            label: modelData.name; kind: "workspace"; selected: modelData.active; onActivated: modelData.activate()
                        }
                    }
                    Repeater {
                        model: bar.niriWorkspaces
                        PanelChip {
                            required property var modelData
                            prefs: bar.prefs; label: modelData.name || String(modelData.idx); kind: "workspace"
                            selected: modelData.is_active; enabled: bar.niriBackend.ready && bar.niriBackend.targetId === null
                            onActivated: bar.niriBackend.activate(modelData.id)
                        }
                    }
                }
            }
            Item { Layout.fillWidth: true }
            
            StatusButton { prefs: bar.prefs; glyph: "network"; label: "Network settings"; visible: bar.width >= 620; enabled: !bar.prefs.panelOnly; onActivated: bar.openControls() }
            StatusButton { prefs: bar.prefs; glyph: "bell"; label: "Notifications (" + bar.prefs.notificationCount + ")"; visible: bar.width >= 540; enabled: !bar.prefs.panelOnly; onActivated: bar.openNotifications() }
            StatusButton {
                prefs: bar.prefs; glyph: bar.audioReady && !bar.sink.audio.muted ? "sound" : "mute"
                label: bar.audioReady ? "Sound " + Math.round(bar.sink.audio.volume*100) + "%" : "Sound unavailable"
                visible: bar.width >= 460; enabled: !bar.prefs.panelOnly; onActivated: bar.openControls()
            }
            RowLayout {
                visible: bar.prefs.batteryPercent >= 0 && bar.width >= 480; spacing: 5
                Rectangle {
                    width: 22; height: 11; radius: 3; color: "transparent"; border.color: bar.prefs.foreground
                    Rectangle { x: 2; y: 2; height: 7; width: 18*Math.max(0,Math.min(100,bar.prefs.batteryPercent))/100; radius: 1; color: bar.prefs.batteryPercent<=15 ? "#e76c6c" : bar.prefs.foreground }
                    Rectangle { x: parent.width; anchors.verticalCenter: parent.verticalCenter; width: 2; height: 5; radius: 1; color: bar.prefs.foreground }
                }
                Text { text: bar.prefs.batteryPercent+"%"; color: bar.prefs.foreground; font.pixelSize: 12; visible: bar.width>=650 }
            }
            StatusButton { prefs: bar.prefs; glyph: "controls"; label: "Control Center"; enabled: !bar.prefs.panelOnly; onActivated: bar.openControls() }
            PanelChip { prefs: bar.prefs; label: bar.clockText; visible: bar.width >= 520; enabled: !bar.prefs.panelOnly; onActivated: bar.openWidgets() }
        }
    }
}
