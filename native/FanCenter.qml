import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

ShellPopup {
    id: win
    signal openEnergy()
    property var sample: null
    property string sensorStatus: "Reading sensors…"
    readonly property bool canChange: !prefs.nestedPreview && Quickshell.env("OZIRO_LOGIN_SESSION")==="1"
    menuWidth: 460
    menuHeight: 590
    function refresh() {
        if (!sensor.running) sensor.running=true;
    }
    SystemControls { id: sys }
    Process {
        id: sensor
        command: ["/usr/bin/timeout","-k","1s","4s","/usr/bin/python","-I",Quickshell.shellPath("fan-status.py")]
        stdout: SplitParser {
            onRead: line => {
                try {
                    const data=JSON.parse(line);
                    if (Array.isArray(data.fans) && Array.isArray(data.temperatures)) {
                        win.sample=data; win.sensorStatus="Live sensor readings";
                    }
                } catch(e) { win.sensorStatus="Invalid sensor snapshot"; }
            }
        }
        stderr: StdioCollector {}
        onExited: (code,status) => {
            if (code!==0) { win.sample=null; win.sensorStatus="Sensor reader unavailable or timed out"; }
        }
    }
    Timer { interval: 3000; repeat: true; running: true; onTriggered: win.refresh() }
    Component.onCompleted: Qt.callLater(() => win.refresh())
    Rectangle {
        x: win.bodyX; y: win.bodyY; width: win.bodyWidth; height: win.bodyHeight
        radius: 18; color: win.prefs.popupColor; border.color: win.prefs.outline
        focus: true
        Keys.onEscapePressed: { if (!win.dismissBlocked) win.dismiss() }
        ColumnLayout {
            anchors.fill: parent; anchors.margins: 14; spacing: 10
            RowLayout {
                Chip { prefs: win.prefs; label: "‹"; Accessible.name: "Back to Energy"; onActivated: win.openEnergy() }
                Text { Layout.fillWidth: true; text: "Fan Manager"; color: win.prefs.foreground; font.pixelSize: 22; font.bold: true }
                Chip { prefs: win.prefs; label: "×"; Accessible.name: "Close Fan Manager"; onActivated: win.dismiss() }
            }
            ScrollView {
                id: scroll
                Layout.fillWidth: true; Layout.fillHeight: true; contentWidth: availableWidth; clip: true
                ColumnLayout {
                    width: scroll.availableWidth; spacing: 10
                    Text { Layout.fillWidth: true; text: win.sample ? (win.sample.vendor+" "+win.sample.model).trim() || "Unknown hardware" : "Detecting hardware…"; textFormat: Text.PlainText; color: win.prefs.muted; elide: Text.ElideRight }
                    SectionLabel { prefs: win.prefs; label: "FAN SPEED" }
                    Text { Layout.fillWidth: true; visible: !win.sample || win.sample.fans.length===0; text: "No readable fan RPM sensor exposed by the kernel."; wrapMode: Text.WordWrap; color: win.prefs.muted }
                    Repeater {
                        model: win.sample ? win.sample.fans : []
                        Rectangle {
                            required property var modelData
                            Layout.fillWidth: true; implicitHeight: 62; radius: 10; color: win.prefs.cardColor; border.color: win.prefs.outline
                            RowLayout {
                                anchors.fill: parent; anchors.margins: 10
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    Text { Layout.fillWidth: true; text: modelData.label; textFormat: Text.PlainText; color: win.prefs.foreground; elide: Text.ElideRight }
                                    Text { Layout.fillWidth: true; text: modelData.driver; textFormat: Text.PlainText; color: win.prefs.muted; font.pixelSize: 11; elide: Text.ElideRight }
                                }
                                Text { text: modelData.rpm+" RPM"; color: win.prefs.accent; font.pixelSize: 20; font.bold: true }
                            }
                        }
                    }
                    SectionLabel { prefs: win.prefs; label: "TEMPERATURE SENSORS" }
                    Text { Layout.fillWidth: true; visible: !win.sample || win.sample.temperatures.length===0; text: "Temperature sensors unavailable."; color: win.prefs.muted; wrapMode: Text.WordWrap }
                    Repeater {
                        model: win.sample ? win.sample.temperatures : []
                        RowLayout {
                            required property var modelData
                            Layout.fillWidth: true
                            Text { Layout.fillWidth: true; text: modelData.driver+" · "+modelData.label; textFormat: Text.PlainText; color: win.prefs.foreground; font.pixelSize: 12; elide: Text.ElideRight }
                            Text { text: modelData.celsius.toFixed(1)+" °C"; color: win.prefs.foreground; font.pixelSize: 13 }
                        }
                    }
                    SectionLabel { prefs: win.prefs; label: "FIRMWARE / SYSTEM PROFILES" }
                    Text { Layout.fillWidth: true; wrapMode: Text.WordWrap; color: win.prefs.muted; text: "Automatic thermal management remains active. System power profiles may affect cooling and performance; they do not set a fixed fan speed." }
                    Text { Layout.fillWidth: true; wrapMode: Text.WordWrap; textFormat: Text.PlainText; color: win.prefs.foreground; text: "Power profile: "+sys.profile+(win.sample && win.sample.platformProfile ? " · Firmware: "+win.sample.platformProfile : "") }
                    Flow {
                        Layout.fillWidth: true; spacing: 6
                        Repeater {
                            model: sys.profiles
                            Chip {
                                required property string modelData
                                prefs: win.prefs; label: modelData==="power-saver"?"Power saver":modelData==="balanced"?"Balanced":"Performance"
                                enabled: win.canChange && !sys.busy; selected: sys.profile===modelData
                                onActivated: { if (win.canChange) sys.request("profile",modelData); }
                            }
                        }
                    }
                    Text { Layout.fillWidth: true; wrapMode: Text.WordWrap; color: win.prefs.muted; text: sys.profiles.length ? sys.message : "No supported power profile provider found." }
                    SectionLabel { prefs: win.prefs; label: "MANUAL SPEED" }
                    Text { Layout.fillWidth: true; wrapMode: Text.WordWrap; color: win.prefs.foreground; text: "Not enabled: hardware-specific RPM/PWM control and thermal fallback have not been validated." }
                    Text { Layout.fillWidth: true; wrapMode: Text.WordWrap; color: win.prefs.muted; text: win.sample ? "Detected control attributes: "+win.sample.controls.length+" · asusctl: "+(win.sample.asusctl?"installed":"not found") : "Checking control capabilities…" }
                    Text { Layout.fillWidth: true; wrapMode: Text.WordWrap; color: win.prefs.muted; font.pixelSize: 11; text: "Sensor refresh runs only while this panel is open. No EC, PWM, or fan curve writes are performed." }
                    RowLayout {
                        Layout.fillWidth: true
                        Text { Layout.fillWidth: true; text: win.sensorStatus; color: win.prefs.muted; font.pixelSize: 11 }
                        Chip { prefs: win.prefs; label: "Refresh"; enabled: !sensor.running && !sys.busy; onActivated: { win.refresh(); sys.request("status",""); } }
                    }
                }
            }
        }
    }
}
