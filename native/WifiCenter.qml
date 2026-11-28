import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

ShellPopup {
    id: win
    signal openControls()
    property var networks: []
    property var chosen: null
    property bool adapterAvailable: false
    property bool radioEnabled: false
    property string message: "Reading Wi-Fi…"
    property string pendingRequest: ""
    property string operation: ""
    property bool responseReceived: false
    property bool retryPassword: false
    readonly property bool busy: worker.running
    dismissBlocked: busy && (operation === "join" || operation === "disconnect")
    menuWidth: 410
    menuHeight: 540

    function request(action,row,secret,save,newPassword) {
        if (busy) return;
        if (prefs.nestedPreview && action !== "list") return;
        let data={action:action};
        if (row) {
            data.device=row.device; data.ap=row.ap; data.token=row.token; data.security=row.security;
        }
        if (action==="join") {
            data.password=secret; data.save=save; data.newPassword=newPassword;
        }
        operation=action; responseReceived=false;
        pendingRequest=JSON.stringify(data)+"\n";
        password.clear();
        message=action==="scan" ? "Scanning…" : action==="join" ? "Connecting…" : action==="disconnect" ? "Disconnecting…" : "Reading Wi-Fi…";
        worker.running=true;
    }
    function receive(line) {
        let data;
        try { data=JSON.parse(line); } catch(e) { return; }
        if (data.ready===true) {
            if (pendingRequest.length === 0) return;
            worker.write(pendingRequest);
            pendingRequest="";
            return;
        }
        responseReceived=true;
        if (Array.isArray(data.networks)) {
            networks=data.networks; adapterAvailable=data.available===true; radioEnabled=data.enabled===true;
        }
        message=data.message || (data.ok ? "Select a network" : "Wi-Fi unavailable");
        if (operation==="join" && data.ok) { chosen=null; retryPassword=false; }
    }
    Process {
        id: worker
        command: ["/usr/bin/timeout","-k","2s","45s","/usr/bin/python","-I",Quickshell.shellPath("wifi-manager.py")]
        stdinEnabled: true
        stdout: SplitParser { onRead: line => win.receive(line) }
        stderr: StdioCollector {}
        onExited: (code,status) => {
            win.pendingRequest="";
            const action=win.operation;
            if (!win.responseReceived) win.message="Wi-Fi helper stopped or timed out.";
            if (action==="join" || action==="disconnect") refreshDelay.restart();
        }
    }
    Timer {
        id: refreshDelay; interval: 400; repeat: false
        onTriggered: {
            const old=win.message;
            win.request("list",null,"",false,false);
            // Final operation status remains visible until refreshed data arrives.
            win.message=old;
        }
    }
    Component.onCompleted: Qt.callLater(() => win.request("list",null,"",false,false))

    Rectangle {
        focus: true
        Keys.onEscapePressed: {
            if (win.dismissBlocked) return;
            if (win.chosen) { password.clear(); win.chosen=null; win.retryPassword=false; }
            else win.dismiss();
        }
        x: win.bodyX; y: win.bodyY; width: win.bodyWidth; height: win.bodyHeight
        radius: 18; color: win.prefs.popupColor; border.color: win.prefs.outline
        ColumnLayout {
            anchors.fill: parent; anchors.margins: 14; spacing: 10
            RowLayout {
                Chip { prefs: win.prefs; label: "‹"; Accessible.name: "Back to Control Center"; enabled: !win.dismissBlocked; onActivated: win.openControls() }
                Text { Layout.fillWidth: true; text: "Wi-Fi"; color: win.prefs.foreground; font.pixelSize: 22; font.bold: true }
                Chip { prefs: win.prefs; label: "↻"; Accessible.name: "Refresh nearby networks"; enabled: !win.busy && !win.prefs.nestedPreview && win.radioEnabled; onActivated: win.request("scan",null,"",false,false) }
                Chip { prefs: win.prefs; label: "×"; Accessible.name: "Close Wi-Fi"; enabled: !win.dismissBlocked; onActivated: win.dismiss() }
            }
            Text {
                Layout.fillWidth: true; textFormat: Text.PlainText; wrapMode: Text.WordWrap
                text: win.prefs.nestedPreview ? "Preview · read-only" : !win.adapterAvailable ? "Wi-Fi adapter unavailable" : !win.radioEnabled ? "Wi-Fi is off. Enable it in Control Center." : win.message
                color: win.prefs.muted; font.pixelSize: 12
            }
            Text { Layout.fillWidth: true; visible: !win.adapterAvailable || !win.radioEnabled; text: win.message; color: win.prefs.muted; wrapMode: Text.WordWrap; textFormat: Text.PlainText }
            ListView {
                id: networkList
                Layout.fillWidth: true; Layout.fillHeight: true; clip: true
                visible: !win.chosen
                spacing: 4; model: win.networks
                ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
                delegate: AbstractButton {
                    id: row
                    required property var modelData
                    width: ListView.view.width; height: 55
                    enabled: !win.busy && !win.prefs.nestedPreview && !modelData.ambiguous && (modelData.connected || modelData.security !== "unsupported")
                    Accessible.name: modelData.name + ", " + modelData.strength + "%, " + (modelData.connected ? "connected" : modelData.security)
                    onClicked: { win.chosen=modelData; win.retryPassword=false; remember.checked=false; password.clear(); }
                    background: Rectangle { radius: 9; color: row.hovered || row.activeFocus ? win.prefs.hoverColor : win.prefs.cardColor; border.color: row.modelData.connected || row.activeFocus ? win.prefs.accent : win.prefs.outline }
                    contentItem: RowLayout {
                        spacing: 10
                        Row {
                            spacing: 2
                            Repeater {
                                model: 4
                                Rectangle {
                                    required property int index
                                    anchors.bottom: parent.bottom
                                    width: 4; height: 6+index*4; radius: 2
                                    color: row.modelData.strength >= (index+1)*20 ? win.prefs.accent : win.prefs.outline
                                }
                            }
                        }
                        ColumnLayout {
                            Layout.fillWidth: true; spacing: 2
                            Text { Layout.fillWidth: true; text: row.modelData.name; textFormat: Text.PlainText; color: win.prefs.foreground; elide: Text.ElideRight; font.pixelSize: 14 }
                            Text { Layout.fillWidth: true; text: row.modelData.connected ? "Connected" : row.modelData.ambiguous ? "Multiple profiles" : row.modelData.saved ? "Saved network" : row.modelData.security==="open" ? "Open network" : row.modelData.security==="sae" ? "WPA3" : row.modelData.security==="wpa-psk" ? "WPA2" : "Unsupported security"; color: win.prefs.muted; font.pixelSize: 11; elide: Text.ElideRight }
                        }
                        Text { text: row.modelData.connected ? "✓" : "›"; color: row.modelData.connected ? win.prefs.accent : win.prefs.muted; font.pixelSize: 20 }
                    }
                }
            }
            Text { Layout.fillWidth: true; visible: !win.chosen && !win.busy && win.radioEnabled && win.networks.length===0; text: "No visible networks. Use refresh to scan."; color: win.prefs.muted; wrapMode: Text.WordWrap }
            ColumnLayout {
                Layout.fillWidth: true; Layout.fillHeight: true; visible: win.chosen !== null; spacing: 12
                Text { Layout.fillWidth: true; text: win.chosen ? win.chosen.name : ""; textFormat: Text.PlainText; color: win.prefs.foreground; font.pixelSize: 19; elide: Text.ElideRight }
                Text { Layout.fillWidth: true; wrapMode: Text.WordWrap; text: win.chosen && win.chosen.connected ? "Disconnecting may interrupt active internet connections." : win.chosen && win.chosen.security==="open" ? "Open networks are not encrypted. Connect only if you trust this network." : "Connect to the selected network."; color: win.prefs.muted }
                TextField {
                    id: password
                    Layout.fillWidth: true
                    visible: !!win.chosen && !win.chosen.connected && win.chosen.security!=="open" && (!win.chosen.saved || win.retryPassword)
                    enabled: !win.busy
                    echoMode: TextInput.Password; maximumLength: 64
                    inputMethodHints: Qt.ImhHiddenText | Qt.ImhSensitiveData | Qt.ImhNoPredictiveText
                    placeholderText: "Wi-Fi password"; Accessible.name: "Wi-Fi password"
                    color: win.prefs.foreground
                    background: Rectangle { radius: 7; color: win.prefs.cardColor; border.color: password.activeFocus ? win.prefs.accent : win.prefs.outline }
                    Keys.onEscapePressed: { if (!win.dismissBlocked) { password.clear(); win.chosen=null; win.retryPassword=false; } }
                }
                RowLayout {
                    visible: !!win.chosen && !win.chosen.connected && !win.chosen.saved
                    Text { Layout.fillWidth: true; text: "Remember network"; color: win.prefs.foreground }
                    Switch { id: remember; checked: false; enabled: !win.busy; Accessible.name: "Remember network" }
                }
                Chip {
                    prefs: win.prefs; visible: !!win.chosen && !win.chosen.connected && !!win.chosen.saved && win.chosen.security!=="open" && !win.retryPassword
                    label: "Use a different password temporarily"; enabled: !win.busy
                    onActivated: { win.retryPassword=true; password.forceActiveFocus(); }
                }
                RowLayout {
                    Chip { prefs: win.prefs; label: "Cancel"; enabled: !win.busy; onActivated: { password.clear(); win.chosen=null; win.retryPassword=false; } }
                    Item { Layout.fillWidth: true }
                    Chip {
                        prefs: win.prefs; selected: true
                        label: win.busy ? "Working…" : win.chosen && win.chosen.connected ? "Disconnect" : "Connect"
                        enabled: !win.busy && !!win.chosen && (!password.visible || password.text.length>0)
                        onActivated: {
                            const row=win.chosen;
                            win.request(row.connected?"disconnect":"join",row,password.text,remember.checked,win.retryPassword);
                            if (row.connected) win.chosen=null;
                        }
                    }
                }
                Item { Layout.fillHeight: true }
            }
            Text { Layout.fillWidth: true; text: "NetworkManager · no password stored by Oziro"; color: win.prefs.muted; font.pixelSize: 10; wrapMode: Text.WordWrap }
        }
    }
}
