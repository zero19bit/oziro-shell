import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth

ShellPopup {
    id: win
    signal openControls()
    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool canChange: !prefs.nestedPreview && Quickshell.env("OZIRO_LOGIN_SESSION") === "1"
    readonly property bool powered: adapter !== null && adapter.enabled
    readonly property var devices: adapter ? adapter.devices.values.slice().sort((a,b) =>
        Number(b.connected)-Number(a.connected) || Number(b.paired)-Number(a.paired) || String(a.name).localeCompare(String(b.name))) : []
    property var scanAdapter: null
    property var selectedDevice: null
    property string message: ""
    property string pendingAction: ""
    property var pendingDevice: null
    property bool pairObserved: false
    readonly property bool working: pendingDevice !== null
    menuWidth: 410
    menuHeight: 540
    dismissBlocked: working
    function stopScan() {
        scanTimer.stop();
        const a=scanAdapter;
        scanAdapter=null;
        if (a && canChange && a.discovering) a.discovering=false;
    }
    function startScan() {
        if (!canChange || !powered || working || adapter.discovering) return;
        scanAdapter=adapter;
        adapter.discovering=true;
        scanTimer.restart();
        message="Searching nearby devices…";
    }
    function perform(action) {
        const d=selectedDevice;
        if (!canChange || !powered || working || !d || !devices.includes(d) || d.blocked) return;
        if ((action==="pair" && d.paired) || (action==="connect" && (!d.paired || d.connected)) ||
            (action==="disconnect" && !d.connected) || (action==="forget" && (!d.paired || d.connected))) return;
        stopScan();
        pendingAction=action;
        pendingDevice=d;
        pairObserved=false;
        message=action==="pair" ? "Pairing…" : action==="connect" ? "Connecting…" : action==="disconnect" ? "Disconnecting…" : "Removing pairing…";
        operationTimer.restart();
        if (action==="pair") d.pair();
        else if (action==="connect") d.connect();
        else if (action==="disconnect") d.disconnect();
        else if (action==="forget") d.forget();
        Qt.callLater(() => win.reconcile());
    }
    function finish(note) {
        operationTimer.stop();
        pendingDevice=null; pendingAction=""; pairObserved=false;
        selectedDevice=null; message=note;
    }
    function reconcile() {
        const d=pendingDevice;
        if (!d) return;
        if (!devices.includes(d)) { finish(pendingAction==="forget" ? "Device removed." : "Device no longer available."); return; }
        if (pendingAction==="pair") {
            if (d.paired) finish("Paired. Select the device to connect.");
            else if (d.pairing) pairObserved=true;
            else if (pairObserved) finish("Pairing ended. PIN or passkey pairing may require an external agent.");
        } else if (pendingAction==="connect" && d.connected) finish("Connected.");
        else if (pendingAction==="disconnect" && !d.connected) finish("Disconnected.");
        else if (pendingAction==="forget" && !d.paired) finish("Device removed.");
    }
    onDevicesChanged: {
        if (selectedDevice && !devices.includes(selectedDevice)) selectedDevice=null;
        reconcile();
    }
    onPoweredChanged: {
        if (!powered) { stopScan(); if (working) finish("Bluetooth turned off."); }
    }
    onAdapterChanged: { if (scanAdapter && scanAdapter !== adapter) stopScan(); }
    Timer { id: scanTimer; interval: 12000; repeat: false; onTriggered: { win.stopScan(); win.message="Scan complete."; } }
    Timer {
        id: operationTimer; interval: 35000; repeat: false
        onTriggered: {
            const d=win.pendingDevice;
            if (win.pendingAction==="pair" && d && d.pairing && win.canChange) d.cancelPair();
            win.finish("Operation timed out. Check device state and try again.");
        }
    }
    Connections {
        target: win.pendingDevice
        ignoreUnknownSignals: true
        function onPairedChanged() { win.reconcile(); }
        function onPairingChanged() { win.reconcile(); }
        function onConnectedChanged() { win.reconcile(); }
        function onStateChanged() { win.reconcile(); }
    }
    Component.onDestruction: {
        stopScan();
        if (canChange && pendingAction==="pair" && pendingDevice && pendingDevice.pairing) pendingDevice.cancelPair();
    }
    Rectangle {
        x: win.bodyX; y: win.bodyY; width: win.bodyWidth; height: win.bodyHeight
        radius: 18; color: win.prefs.popupColor; border.color: win.prefs.outline
        focus: true
        Keys.onEscapePressed: { if (!win.working) { if (win.selectedDevice) win.selectedDevice=null; else win.dismiss(); } }
        ColumnLayout {
            anchors.fill: parent; anchors.margins: 14; spacing: 10
            RowLayout {
                Chip { prefs: win.prefs; label: "‹"; Accessible.name: "Back to Control Center"; enabled: !win.working; onActivated: win.openControls() }
                Text { Layout.fillWidth: true; text: "Bluetooth"; color: win.prefs.foreground; font.pixelSize: 22; font.bold: true }
                Switch {
                    Accessible.name: "Bluetooth power"
                    checked: win.powered
                    enabled: win.canChange && !!win.adapter && !win.working
                    onToggled: { win.stopScan(); if (win.adapter && win.canChange) win.adapter.enabled=checked; }
                }
                Chip { prefs: win.prefs; label: "×"; Accessible.name: "Close Bluetooth"; enabled: !win.working; onActivated: win.dismiss() }
            }
            Text { Layout.fillWidth: true; wrapMode: Text.WordWrap; text: !win.canChange ? "Read-only outside independent Oziro login." : !win.adapter ? "Bluetooth adapter unavailable." : !win.powered ? "Bluetooth is off." : win.message || "Select a device."; color: win.prefs.muted; font.pixelSize: 12 }
            RowLayout {
                visible: win.powered && !win.selectedDevice
                SectionLabel { Layout.fillWidth: true; prefs: win.prefs; label: "DEVICES" }
                Chip {
                    prefs: win.prefs; label: win.scanAdapter ? "■" : "↻"
                    Accessible.name: win.scanAdapter ? "Stop scan" : "Scan nearby devices"
                    enabled: win.canChange && !win.working && (!!win.scanAdapter || !win.adapter.discovering)
                    onActivated: { if (win.scanAdapter) { win.stopScan(); win.message="Scan stopped."; } else win.startScan(); }
                }
            }
            ListView {
                id: deviceList
                Layout.fillWidth: true; Layout.fillHeight: true
                visible: !win.selectedDevice; clip: true; spacing: 4
                model: win.powered ? win.devices : []
                ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
                delegate: AbstractButton {
                    id: row
                    required property var modelData
                    width: ListView.view.width; height: 56
                    enabled: win.canChange && !win.working && !modelData.blocked
                    Accessible.name: modelData.name + (modelData.connected ? ", connected" : modelData.paired ? ", paired" : ", nearby")
                    onClicked: { forgetConfirm.visible=false; win.selectedDevice=modelData; win.message=""; }
                    background: Rectangle { radius: 10; color: row.hovered || row.activeFocus ? win.prefs.hoverColor : win.prefs.cardColor; border.color: row.modelData.connected || row.activeFocus ? win.prefs.accent : win.prefs.outline }
                    contentItem: RowLayout {
                        spacing: 10
                        Image {
                            Layout.preferredWidth: 24; Layout.preferredHeight: 24
                            source: Quickshell.iconPath(row.modelData.icon || "bluetooth",true)
                            visible: status===Image.Ready
                            sourceSize: Qt.size(32,32)
                        }
                        ColumnLayout {
                            Layout.fillWidth: true; spacing: 2
                            Text { Layout.fillWidth: true; text: row.modelData.name || "Unnamed device"; textFormat: Text.PlainText; color: win.prefs.foreground; elide: Text.ElideRight }
                            Text { Layout.fillWidth: true; text: row.modelData.connected ? "Connected" : row.modelData.pairing ? "Pairing…" : row.modelData.blocked ? "Blocked" : row.modelData.paired ? "Paired" : "Nearby"; color: win.prefs.muted; font.pixelSize: 11 }
                        }
                        Text { visible: row.modelData.batteryAvailable; text: Math.round(row.modelData.battery*100)+"%"; color: win.prefs.muted; font.pixelSize: 11 }
                        Text { text: row.modelData.connected ? "✓" : "›"; color: row.modelData.connected ? win.prefs.accent : win.prefs.muted; font.pixelSize: 20 }
                    }
                }
            }
            Text { Layout.fillWidth: true; visible: win.powered && !win.selectedDevice && win.devices.length===0; text: "No devices yet. Put your device into pairing mode and scan."; color: win.prefs.muted; wrapMode: Text.WordWrap }
            ColumnLayout {
                Layout.fillWidth: true; Layout.fillHeight: true; visible: !!win.selectedDevice; spacing: 12
                Text { Layout.fillWidth: true; text: win.selectedDevice ? win.selectedDevice.name : ""; textFormat: Text.PlainText; color: win.prefs.foreground; font.pixelSize: 19; elide: Text.ElideRight }
                Text { Layout.fillWidth: true; text: win.selectedDevice && win.selectedDevice.connected ? "Disconnecting stops the active Bluetooth connection." : win.selectedDevice && win.selectedDevice.paired ? "Connect or remove the saved pairing." : "Pair only a device you recognize. PIN/passkey pairing may require an external agent."; wrapMode: Text.WordWrap; color: win.prefs.muted }
                RowLayout {
                    Chip {
                        prefs: win.prefs; label: win.working ? "Cancel pairing" : "Back"
                        enabled: !win.working || win.pendingAction==="pair"
                        onActivated: { if (win.working && win.pendingDevice && win.canChange) { win.pendingDevice.cancelPair(); win.finish("Pairing cancellation requested."); } else win.selectedDevice=null; }
                    }
                    Item { Layout.fillWidth: true }
                    Chip {
                        prefs: win.prefs; selected: true; enabled: !win.working && !!win.selectedDevice && win.canChange && win.powered
                        label: win.working ? "Working…" : win.selectedDevice && win.selectedDevice.connected ? "Disconnect" : win.selectedDevice && win.selectedDevice.paired ? "Connect" : "Pair"
                        onActivated: { const d=win.selectedDevice; if (d) win.perform(d.connected?"disconnect":d.paired?"connect":"pair"); }
                    }
                }
                MenuRow {
                    Layout.fillWidth: true; prefs: win.prefs; label: "Forget saved device"; trailing: "›"
                    visible: !!win.selectedDevice && win.selectedDevice.paired && !win.selectedDevice.connected
                    enabled: !win.working && win.canChange
                    onActivated: forgetConfirm.visible=true
                }
                RowLayout {
                    id: forgetConfirm; visible: false
                    Text { Layout.fillWidth: true; text: "Remove pairing?"; color: win.prefs.foreground; wrapMode: Text.WordWrap }
                    Chip { prefs: win.prefs; label: "Cancel"; onActivated: forgetConfirm.visible=false }
                    Chip { prefs: win.prefs; label: "Forget"; enabled: !win.working; onActivated: { forgetConfirm.visible=false; win.perform("forget"); } }
                }
                Item { Layout.fillHeight: true }
            }
            Text { Layout.fillWidth: true; text: "BlueZ · no automatic trust or discoverability changes"; color: win.prefs.muted; font.pixelSize: 10; wrapMode: Text.WordWrap }
        }
    }
}
