import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

ShellPopup {
    id: win
    property string report: ""
    property string testResult: ""
    function refresh() {
        win.prefs.refreshPower();
        if (probe.running) return;
        report = "";
        probe.running = true;
    }
    menuWidth: Math.min(500, screen ? Math.max(1,screen.width-24) : 500)
    menuHeight: Math.min(650, screen ? Math.max(1,screen.height-160) : 650)
    Process {
        id: probe
        command: ["bash", Quickshell.shellPath("energy-status.sh")]
        stdout: SplitParser { onRead: data => { if (win.report.length < 6000) win.report += data.slice(0,500) + "\n"; } }
        onExited: (code,status) => { if (code !== 0) win.report += "Probe failed (" + code + ")\n"; }
    }
    Component.onCompleted: refresh()
    Rectangle {
        focus: true
        Keys.onEscapePressed: { if (!win.dismissBlocked) win.dismiss(); }
        x: win.bodyX; y: win.bodyY; width: win.bodyWidth; height: win.bodyHeight
        radius: 20; color: win.prefs.popupColor; border.color: win.prefs.outline
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
                    Text { text: win.prefs.batteryPercent >= 0 ? win.prefs.batteryPercent + "% · " + win.prefs.powerLabel : "Battery unavailable"; color: win.prefs.foreground; font.pixelSize: 24; font.bold: true }
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
                                onActivated: win.prefs.selectEnergyMode(modelData)
                            }
                        }
                    }
                    Text { Layout.fillWidth: true; wrapMode: Text.WordWrap; color: win.prefs.muted; text: "Adaptive: automatic on battery. Balanced: standard effects. Eco: reduced effects everywhere. Selecting a mode clears the previous manual override." }
                    Text { Layout.fillWidth: true; wrapMode: Text.WordWrap; color: win.prefs.foreground; text: (win.prefs.eco ? "Eco active · " : "Standard active · ") + win.prefs.energyReason }
                    Flow {
                        Layout.fillWidth: true; spacing: 6
                        Chip { prefs: win.prefs; label: "Reset energy"; onActivated: win.prefs.resetEnergyPolicy() }
                        Chip { prefs: win.prefs; label: "Pause dock on battery in Eco"; selected: win.prefs.suspendDockOnBattery; onActivated: win.prefs.suspendDockOnBattery = !win.prefs.suspendDockOnBattery }
                    }
                    Text { Layout.fillWidth: true; wrapMode: Text.WordWrap; color: win.prefs.foreground; text: "Dock: " + (!win.prefs.dockEnabled ? "Disabled in settings" : win.prefs.dockSuspended ? "Paused by energy policy" : "Enabled") }
                    Text { Layout.fillWidth: true; wrapMode: Text.WordWrap; color: win.prefs.muted; text: "Power source: " + win.prefs.powerLabel + " · " + (win.prefs.powerChecking ? "Checking…" : win.prefs.powerMonitorRunning ? "Event monitor running" : "Waiting for monitor retry") }
                    RowLayout {
                        Layout.fillWidth: true
                        Chip { prefs: win.prefs; label: "Run policy self-test"; onActivated: {
                            const result = win.prefs.energySelfTest();
                            win.testResult = result.passed + "/" + result.total + " policy cases passed";
                            if (result.failures.length) win.testResult += " · failed: " + result.failures.join(", ");
                        } }
                        Text { Layout.fillWidth: true; wrapMode: Text.WordWrap; color: win.prefs.foreground; text: win.testResult }
                    }
                    Text { Layout.fillWidth: true; wrapMode: Text.WordWrap; color: win.prefs.muted; font.pixelSize: 11; text: "Self-test checks logic, not hardware. Refresh rechecks the real charger state." }
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
