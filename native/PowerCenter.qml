import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
    id: win
    required property var prefs
    signal dismiss()
    signal openLock()
    signal openSettings()
    property string pending: ""
    property string report: ""
    property string sessionStatus: "Checking session…"
    property string logoutStatus: "unknown"
    property string restartStatus: "unknown"
    property string shutdownStatus: "unknown"
    readonly property bool allowed: prefs.loginSession && !prefs.nestedPreview
    function inspect() {
        if (probe.running || action.running) return;
        win.logoutStatus="unknown"; win.restartStatus="unknown"; win.shutdownStatus="unknown";
        win.sessionStatus="Checking session…";
        probe.running=true;
    }
    function parse(line) {
        if (line.indexOf("Session: ")===0) sessionStatus=line.slice(9);
        else if (line.indexOf("Logout: ")===0) logoutStatus=line.slice(8);
        else if (line.indexOf("Restart: ")===0) restartStatus=line.slice(9);
        else if (line.indexOf("Shutdown: ")===0) shutdownStatus=line.slice(10);
    }
    function choose(name) { pending=name; report=""; }
    function permitted(name) { return allowed && !probe.running && (name==="logout" ? logoutStatus==="yes" : name==="reboot" ? restartStatus==="yes" : name==="poweroff" && shutdownStatus==="yes"); }
    function hint(status) { return status==="yes" ? "" : status==="challenge" ? "Authentication needed" : status==="unknown" ? "…" : "Unavailable"; }
    anchors { top: win.prefs.layoutMode !== "bottom"; bottom: win.prefs.layoutMode === "bottom"; left: true }
    margins { top: win.prefs.popupMargin; bottom: win.prefs.popupMargin; left: 10 }
    implicitWidth: Math.min(350, screen ? Math.max(1,screen.width-20) : 350)
    implicitHeight: Math.min(pending!=="" || report!=="" ? 440 : 330, screen ? Math.max(1,screen.height-win.prefs.popupMargin-20) : 440)
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    color: "transparent"
    Process {
        id: probe
        command: ["bash",Quickshell.shellPath("power-action.sh"),"--check"]
        stdout: SplitParser { onRead: data => win.parse(data) }
        stderr: SplitParser { onRead: data => { if (win.report.length<1500) win.report+=data+"\n"; } }
        onExited: (code,status) => { if(code!==0) win.sessionStatus="Could not check session"; }
    }
    Process {
        id: action
        stdout: SplitParser { onRead: data => { if (win.report.length<1500) win.report+=data+"\n"; } }
        stderr: SplitParser { onRead: data => { if (win.report.length<1500) win.report+=data+"\n"; } }
        onExited: (code,status) => {
            win.report=code===0 ? "Request accepted." : "Action not completed. "+win.report;
            win.pending="";
        }
    }
    Component.onCompleted: inspect()
    Rectangle {
        anchors.fill: parent; radius: 10; color: win.prefs.popupColor; border.color: win.prefs.outline
        ColumnLayout {
            anchors.fill: parent; anchors.margins: 10; spacing: 3
            RowLayout {
                Text { Layout.fillWidth: true; text: "Oziro"; color: win.prefs.foreground; font.pixelSize: 16; font.weight: Font.DemiBold }
                Chip { prefs: win.prefs; label: "Close"; enabled: !action.running; onActivated: win.dismiss() }
            }
            MenuRow { Layout.fillWidth: true; prefs: win.prefs; label: "System Settings…"; enabled: !action.running; onActivated: win.openSettings() }
            Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: win.prefs.outline }
            MenuRow { Layout.fillWidth: true; prefs: win.prefs; label: "Lock Screen"; enabled: !win.prefs.nestedPreview && !action.running; onActivated: win.openLock() }
            MenuRow { Layout.fillWidth: true; prefs: win.prefs; label: "Log Out…"; trailing: win.hint(win.logoutStatus); selected: win.pending==="logout"; enabled: win.permitted("logout") && !action.running; onActivated: win.choose("logout") }
            MenuRow { Layout.fillWidth: true; prefs: win.prefs; label: "Restart…"; trailing: win.hint(win.restartStatus); selected: win.pending==="reboot"; enabled: win.permitted("reboot") && !action.running; onActivated: win.choose("reboot") }
            MenuRow { Layout.fillWidth: true; prefs: win.prefs; label: "Shut Down…"; trailing: win.hint(win.shutdownStatus); selected: win.pending==="poweroff"; enabled: win.permitted("poweroff") && !action.running; onActivated: win.choose("poweroff") }
            Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: win.prefs.outline }
            Text { Layout.fillWidth: true; wrapMode: Text.WordWrap; text: win.sessionStatus; color: win.prefs.muted; font.pixelSize: 11; textFormat: Text.PlainText }
            MenuRow { Layout.fillWidth: true; prefs: win.prefs; label: "Check availability"; enabled: !probe.running && !action.running; onActivated: win.inspect() }
            Text { Layout.fillWidth: true; visible: win.pending!==""; wrapMode: Text.WordWrap; text: (win.pending==="logout" ? "Log out of Oziro?" : win.pending==="reboot" ? "Restart the computer?" : "Shut down the computer?") + " Save your work first."; color: win.prefs.foreground; font.pixelSize: 13 }
            RowLayout {
                visible: win.pending!==""
                Item { Layout.fillWidth: true }
                Chip { prefs: win.prefs; label: "Cancel"; enabled: !action.running; onActivated: win.pending="" }
                Chip { prefs: win.prefs; label: action.running ? "Working…" : "Confirm"; selected: true; enabled: win.permitted(win.pending) && !action.running; onActivated: { win.report=""; action.command=["bash",Quickshell.shellPath("power-action.sh"),win.pending]; action.running=true; } }
            }
            Text { Layout.fillWidth: true; visible: win.report!==""; wrapMode: Text.WordWrap; textFormat: Text.PlainText; text: win.report; color: win.prefs.muted; font.pixelSize: 11 }
            Item { Layout.fillHeight: true }
        }
    }
}
