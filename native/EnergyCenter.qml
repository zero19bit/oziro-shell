import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
    id: win
    required property var prefs
    signal dismiss()
    property string report: ""
    function refresh() {
        if (probe.running) return;
        report = "";
        probe.running = true;
    }
    anchors { top: win.prefs.layoutMode !== "bottom"; bottom: win.prefs.layoutMode === "bottom"; right: true }
    margins { top: win.prefs.popupMargin; bottom: win.prefs.popupMargin; right: 12 }
    implicitWidth: Math.min(500, screen ? Math.max(1,screen.width-24) : 500)
    implicitHeight: Math.min(650, screen ? Math.max(1,screen.height-160) : 650)
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    color: "transparent"
    Process {
        id: probe
        command: ["bash", Quickshell.shellPath("energy-status.sh")]
        stdout: SplitParser { onRead: data => { if (win.report.length < 6000) win.report += data.slice(0,500) + "\n"; } }
        onExited: (code,status) => { if (code !== 0) win.report += "Probe failed (" + code + ")\n"; }
    }
    Component.onCompleted: refresh()
    Rectangle {
        anchors.fill: parent
        radius: 20; color: win.prefs.surfaceColor; border.color: win.prefs.outline
        ColumnLayout {
            anchors.fill: parent; anchors.margins: 16; spacing: 12
            RowLayout {
                Text { Layout.fillWidth: true; text: "OZIRO / Energy"; color: win.prefs.foreground; font.bold: true; font.pixelSize: 20 }
                Chip { prefs: win.prefs; label: "Close"; onActivated: win.dismiss() }
            }
            ScrollView {
                id: scroll
                Layout.fillWidth: true; Layout.fillHeight: true; contentWidth: availableWidth
                ColumnLayout {
                    width: scroll.availableWidth; spacing: 12
                    Text { text: win.prefs.batteryPercent >= 0 ? win.prefs.batteryPercent + "% · " + (win.prefs.onBattery ? "On battery" : "AC power") : "Battery unavailable"; color: win.prefs.foreground; font.pixelSize: 24; font.bold: true }
                    Rectangle {
                        Layout.fillWidth: true; height: 8; radius: 4; color: win.prefs.outline
                        Rectangle { width: parent.width * Math.max(0,win.prefs.batteryPercent)/100; height: parent.height; radius: 4; color: win.prefs.accent }
                    }
                    Text { text: "SHELL POLICY"; color: win.prefs.accent; font.bold: true }
                    Flow {
                        Layout.fillWidth: true; spacing: 6
                        Repeater {
                            model: ["adaptive","balanced","eco"]
                            Chip {
                                required property string modelData
                                prefs: win.prefs; label: modelData; selected: win.prefs.energyMode === modelData
                                onActivated: win.prefs.energyMode = modelData
                            }
                        }
                    }
                    Text { Layout.fillWidth: true; wrapMode: Text.WordWrap; color: win.prefs.muted; text: "Adaptive reduces effects on battery when enabled. Balanced keeps standard effects. Eco reduces effects on AC and battery. Manual override takes priority." }
                    Text { Layout.fillWidth: true; wrapMode: Text.WordWrap; color: win.prefs.foreground; text: (win.prefs.eco ? "Eco active · " : "Standard active · ") + win.prefs.energyReason }
                    Flow {
                        Layout.fillWidth: true; spacing: 6
                        Chip { prefs: win.prefs; label: "Force reduced effects"; selected: win.prefs.reduceEffects; onActivated: win.prefs.reduceEffects = !win.prefs.reduceEffects }
                        Chip { prefs: win.prefs; label: "Auto on battery"; enabled: win.prefs.energyMode === "adaptive"; selected: win.prefs.autoEco; onActivated: win.prefs.autoEco = !win.prefs.autoEco }
                        Chip { prefs: win.prefs; label: "Pause dock on battery in Eco"; selected: win.prefs.suspendDockOnBattery; onActivated: win.prefs.suspendDockOnBattery = !win.prefs.suspendDockOnBattery }
                    }
                    Text { Layout.fillWidth: true; wrapMode: Text.WordWrap; color: win.prefs.muted; text: win.prefs.dockSuspended ? "Dock temporarily unloaded. Pins preserved. Returns when policy permits." : "Dock pause is optional and never changes saved pins or dock preference." }
                    RowLayout {
                        Layout.fillWidth: true
                        Text { Layout.fillWidth: true; text: "SYSTEM POWER PROVIDERS"; color: win.prefs.accent; font.bold: true }
                        Chip { prefs: win.prefs; label: probe.running ? "Reading…" : "Refresh"; enabled: !probe.running; onActivated: win.refresh() }
                    }
                    Text { Layout.fillWidth: true; wrapMode: Text.WordWrap; textFormat: Text.PlainText; color: win.prefs.foreground; text: win.report || "Reading services…" }
                    Text { Layout.fillWidth: true; wrapMode: Text.WordWrap; color: win.prefs.muted; font.pixelSize: 11; text: "Read-only snapshot. No service is installed, started or stopped. System profile changes remain explicit in Control Center. Shell policies do not change CPU governors, GPU limits or battery charge thresholds." }
                    Text { Layout.fillWidth: true; wrapMode: Text.WordWrap; color: win.prefs.muted; font.pixelSize: 11; text: win.prefs.settingsStatus }
                }
            }
        }
    }
}
