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
    signal openControls()
    property bool checkPassed: false
    property bool attempted: false
    property string report: ""
    function check() {
        if (probe.running) return;
        checkPassed = false;
        attempted = false;
        report = "";
        probe.running = true;
    }
    anchors { top: win.prefs.layoutMode !== "bottom"; bottom: win.prefs.layoutMode === "bottom"; right: true }
    margins { top: win.prefs.popupMargin; bottom: win.prefs.popupMargin; right: 12 }
    implicitWidth: Math.min(480, screen ? Math.max(1,screen.width-24) : 480)
    implicitHeight: Math.min(520, screen ? Math.max(1,screen.height-win.prefs.popupMargin-36) : 520)
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    color: "transparent"
    Process {
        id: probe
        command: ["bash",Quickshell.shellPath("lock-session.sh"),"--check"]
        stdout: SplitParser { onRead: data => { if (win.report.length<4000) win.report += data + "\n"; } }
        stderr: SplitParser { onRead: data => { if (win.report.length<4000) win.report += data + "\n"; } }
        onExited: (code,status) => { win.checkPassed = code===0; }
    }
    Rectangle {
        anchors.fill: parent; radius: 20; color: win.prefs.popupColor; border.color: win.prefs.outline
        ColumnLayout {
            anchors.fill: parent; anchors.margins: 16; spacing: 12
            RowLayout {
                Text { Layout.fillWidth: true; text: "Session Lock"; color: win.prefs.foreground; font.pixelSize: 20; font.bold: true }
                Chip { prefs: win.prefs; label: "Back"; onActivated: win.openControls() }
                Chip { prefs: win.prefs; label: "Close"; onActivated: win.dismiss() }
            }
            SectionLabel { prefs: win.prefs; label: "EXPERIMENTAL · HYPRLOCK" }
            Rectangle {
                Layout.fillWidth: true; Layout.preferredHeight: 112; radius: 12; color: "#191f2b"; border.color: win.prefs.outline
                Column {
                    anchors.centerIn: parent; spacing: 8
                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: "O Z I R O"; color: "#93d9e9"; font.bold: true }
                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: win.prefs.widgetClock; color: "#edf2fa"; font.pixelSize: 36; font.bold: true }
                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: "Lock screen preview"; color: "#a8b4c4"; font.pixelSize: 11 }
                }
            }
            Text { Layout.fillWidth: true; wrapMode: Text.WordWrap; color: win.prefs.foreground; text: "Save your work and know your system password before testing. This uses Hyprlock, not a simulated lock. Ryoku idle and lock settings remain unchanged." }
            Chip { prefs: win.prefs; label: probe.running ? "Checking…" : "Check prerequisites"; enabled: !probe.running; onActivated: win.check() }
            Text { Layout.fillWidth: true; wrapMode: Text.WordWrap; textFormat: Text.PlainText; text: win.report || "No checks run."; color: win.prefs.muted; font.pixelSize: 11 }
            Chip {
                prefs: win.prefs; label: "Lock session now"; enabled: win.checkPassed && !win.attempted && !probe.running
                onActivated: {
                    win.attempted = true;
                    Quickshell.execDetached(["bash",Quickshell.shellPath("lock-session.sh"),"--lock"]);
                    win.report = "Lock requested. If the desktop stays visible, the session is not confirmed locked.";
                }
            }
            Item { Layout.fillHeight: true }
            Text { Layout.fillWidth: true; wrapMode: Text.WordWrap; text: "Manual test only. No automatic lock, password collection or PAM changes. Prerequisite checks do not verify successful authentication."; color: win.prefs.muted; font.pixelSize: 11 }
        }
    }
}
