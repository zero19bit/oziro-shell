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
    signal openLock()
    property string pending: ""
    property string report: ""
    readonly property bool allowed: prefs.loginSession && !prefs.nestedPreview
    anchors { top: win.prefs.layoutMode !== "bottom"; bottom: win.prefs.layoutMode === "bottom"; right: true }
    margins { top: win.prefs.popupMargin; bottom: win.prefs.popupMargin; right: 12 }
    implicitWidth: Math.min(460, screen ? Math.max(1,screen.width-24) : 460)
    implicitHeight: Math.min(440, screen ? Math.max(1,screen.height-win.prefs.popupMargin-36) : 440)
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    color: "transparent"
    Process {
        id: action
        stdout: SplitParser { onRead: data => { if (win.report.length<2000) win.report += data + "\n"; } }
        stderr: SplitParser { onRead: data => { if (win.report.length<2000) win.report += data + "\n"; } }
        onExited: (code,status) => {
            if (code === 0) win.report = "Request accepted by system.";
            else win.report = "Action failed or authorization denied. " + win.report;
            win.pending = "";
        }
    }
    Rectangle {
        anchors.fill: parent; radius: 20; color: win.prefs.popupColor; border.color: win.prefs.outline
        ColumnLayout {
            anchors.fill: parent; anchors.margins: 16; spacing: 12
            RowLayout {
                Text { Layout.fillWidth: true; text: "Power"; color: win.prefs.foreground; font.pixelSize: 24; font.bold: true }
                Chip { prefs: win.prefs; label: "Close"; enabled: !action.running; onActivated: win.dismiss() }
            }
            Text { Layout.fillWidth: true; wrapMode: Text.WordWrap; text: win.allowed ? "Choose an action. Save your work before leaving." : "Shutdown, restart and logout are available only in the independent Oziro login."; color: win.prefs.muted }
            GridLayout {
                Layout.fillWidth: true; columns: 2; columnSpacing: 8; rowSpacing: 8
                QuickToggle { Layout.fillWidth: true; prefs: win.prefs; label: "Lock"; detail: "Secure session"; enabled: !win.prefs.nestedPreview && !action.running; onActivated: win.openLock() }
                QuickToggle { Layout.fillWidth: true; prefs: win.prefs; label: "Log out"; detail: "Return to login"; enabled: win.allowed && !action.running; selected: win.pending==="logout"; onActivated: { win.pending="logout"; win.report=""; } }
                QuickToggle { Layout.fillWidth: true; prefs: win.prefs; label: "Restart"; detail: "Reboot computer"; enabled: win.allowed && !action.running; selected: win.pending==="reboot"; onActivated: { win.pending="reboot"; win.report=""; } }
                QuickToggle { Layout.fillWidth: true; prefs: win.prefs; label: "Shut down"; detail: "Power off computer"; enabled: win.allowed && !action.running; selected: win.pending==="poweroff"; onActivated: { win.pending="poweroff"; win.report=""; } }
            }
            Text { Layout.fillWidth: true; wrapMode: Text.WordWrap; text: "Sleep is disabled until secure lock-on-suspend is implemented."; color: win.prefs.muted; font.pixelSize: 11 }
            Text { Layout.fillWidth: true; visible: win.pending!==""; wrapMode: Text.WordWrap; text: win.pending==="logout" ? "End this Oziro session?" : win.pending==="reboot" ? "Restart the entire computer?" : "Shut down the entire computer?"; color: win.prefs.foreground; font.bold: true }
            RowLayout {
                visible: win.pending!==""
                Chip { prefs: win.prefs; label: "Cancel"; enabled: !action.running; onActivated: win.pending="" }
                Chip {
                    prefs: win.prefs; label: action.running ? "Requesting…" : "Confirm"; selected: true
                    enabled: win.allowed && win.pending!=="" && !action.running
                    onActivated: {
                        win.report="";
                        action.command=["bash",Quickshell.shellPath("power-action.sh"),win.pending];
                        action.running=true;
                    }
                }
            }
            Text { Layout.fillWidth: true; wrapMode: Text.WordWrap; textFormat: Text.PlainText; text: win.report; color: win.prefs.muted; font.pixelSize: 11 }
            Item { Layout.fillHeight: true }
        }
    }
}
