import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pipewire

ShellPopup {
    id: win
    property bool managing: false
    property string message: ""
    property string memoryValue: "Unavailable"
    property string memoryDetail: "System RAM"
    readonly property var cards: prefs.widgetCards.filter(m=>prefs.enabledWidgets.includes(m.id))
    readonly property bool needsMemory: cards.some(m=>m.type==="memory")
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property bool audioReady: Pipewire.ready && sink !== null && sink.audio !== null
    function refresh() {
        if (needsMemory && !memoryProbe.running) {
            memoryValue = "Reading…";
            memoryProbe.running = true;
        }
    }
    onNeedsMemoryChanged: { if (needsMemory) Qt.callLater(refresh); }
    Component.onCompleted: refresh()
    Process {
        id: memoryProbe
        command: ["timeout","3s","awk","/^MemTotal:/ {t=$2} /^MemAvailable:/ {a=$2} END {if(t>0 && a>=0 && a<=t) printf \"%.1f / %.1f GiB\\n\", (t-a)/1048576,t/1048576; else exit 1}", "/proc/meminfo"]
        stdout: SplitParser { onRead: data => { win.memoryValue = data.trim(); } }
        onExited: (code,status) => { if (code !== 0 || win.memoryValue === "Reading…") win.memoryValue = "Unavailable"; }
    }
    function valueFor(type) {
        if (type === "clock") return prefs.widgetClock;
        if (type === "battery") return prefs.batteryPercent >= 0 ? prefs.batteryPercent + "%" : "Unavailable";
        if (type === "audio") return !audioReady ? "Unavailable" : sink.audio.muted ? "Muted" : Math.round(sink.audio.volume*100) + "%";
        return memoryValue;
    }
    function detailFor(type) {
        if (type === "clock") return prefs.widgetDate;
        if (type === "battery") return prefs.powerLabel + " · " + (prefs.eco ? "Eco" : "Standard");
        if (type === "audio") return "Default audio output";
        return "Used / total · manual snapshot";
    }
    implicitWidth: Math.min(540, popupParent && popupParent.screen ? Math.max(1,popupParent.screen.width-24) : 540)
    implicitHeight: Math.min(650, popupParent && popupParent.screen ? Math.max(1,popupParent.screen.height-160) : 650)
    Rectangle {
        focus: true
        Keys.onEscapePressed: { if (!win.dismissBlocked) win.dismiss(); }
        anchors.fill: parent; radius: 20; color: win.prefs.popupColor; border.color: win.prefs.outline
        ColumnLayout {
            anchors.fill: parent; anchors.margins: 16; spacing: 12
            RowLayout {
                Text { Layout.fillWidth: true; text: "OZIRO / Widgets"; font.pixelSize: 20; font.bold: true; color: win.prefs.foreground }
                Chip { prefs: win.prefs; label: win.managing ? "Done" : "Manage"; selected: win.managing; onActivated: win.managing = !win.managing }
                Chip { prefs: win.prefs; label: "Close"; onActivated: win.dismiss() }
            }
            ScrollView {
                id: scroll
                Layout.fillWidth: true; Layout.fillHeight: true; contentWidth: availableWidth
                ColumnLayout {
                    width: scroll.availableWidth; spacing: 10
                    RowLayout {
                        visible: !win.managing
                        Layout.fillWidth: true
                        Text { Layout.fillWidth: true; text: "Dashboard"; color: win.prefs.accent; font.bold: true }
                        Chip { prefs: win.prefs; label: "Refresh RAM"; enabled: win.needsMemory && !memoryProbe.running; onActivated: win.refresh() }
                    }
                    Text { visible: !win.managing && !win.cards.length; text: "No widgets enabled. Open Manage."; color: win.prefs.muted }
                    GridLayout {
                        visible: !win.managing; Layout.fillWidth: true
                        columns: width >= 360 ? 2 : 1; columnSpacing: 8; rowSpacing: 8
                        Repeater {
                            model: win.managing ? [] : win.cards
                            delegate: Rectangle {
                                id: card
                                required property var modelData
                                Layout.fillWidth: true; Layout.preferredWidth: 200; Layout.preferredHeight: 120
                                radius: 14; color: win.prefs.cardColor; border.color: win.prefs.outline
                                ColumnLayout {
                                    anchors.fill: parent; anchors.margins: 14; spacing: 5
                                    Text { Layout.fillWidth: true; font.pixelSize: 12; font.weight: Font.DemiBold; text: card.modelData.title; textFormat: Text.PlainText; elide: Text.ElideRight; color: win.prefs.muted }
                                    Text { Layout.fillWidth: true; text: win.valueFor(card.modelData.type); textFormat: Text.PlainText; elide: Text.ElideRight; font.pixelSize: card.modelData.type === "memory" ? 18 : 26; font.bold: true; color: win.prefs.foreground }
                                    Text { Layout.fillWidth: true; text: win.detailFor(card.modelData.type); textFormat: Text.PlainText; elide: Text.ElideRight; color: win.prefs.muted; font.pixelSize: 11 }
                                }
                            }
                        }
                    }
                    Text { visible: win.managing; text: "Enable or disable cards"; color: win.prefs.accent; font.bold: true }
                    Repeater {
                        model: win.managing ? win.prefs.widgetCards : []
                        delegate: RowLayout {
                            id: option
                            required property var modelData
                            Layout.fillWidth: true
                            Text { Layout.fillWidth: true; text: option.modelData.title; textFormat: Text.PlainText; elide: Text.ElideRight; color: win.prefs.foreground }
                            Chip { prefs: win.prefs; label: win.prefs.enabledWidgets.includes(option.modelData.id) ? "On" : "Off"; selected: win.prefs.enabledWidgets.includes(option.modelData.id); onActivated: win.prefs.toggleWidget(option.modelData.id) }
                            Chip { visible: option.modelData.id.startsWith("user-"); prefs: win.prefs; label: "Remove"; onActivated: win.prefs.removeWidget(option.modelData.id) }
                        }
                    }
                    Text { visible: win.managing; text: "Declarative extensions · up to four"; color: win.prefs.accent; font.bold: true }
                    Text { visible: win.managing; Layout.fillWidth: true; wrapMode: Text.WordWrap; text: "Edit the example JSON, then Install. Allowed types: clock, battery, audio, memory. No commands, scripts or network access."; color: win.prefs.muted; font.pixelSize: 12 }
                    TextArea {
                        id: manifest
                        visible: win.managing; Layout.fillWidth: true; Layout.preferredHeight: 110
                        wrapMode: TextEdit.Wrap; color: win.prefs.foreground
                        text: '{"version":1,"id":"user-power","title":"My battery","type":"battery"}'
                        background: Rectangle { color: win.prefs.cardColor; border.color: win.prefs.outline; radius: 8 }
                    }
                    Flow {
                        visible: win.managing; Layout.fillWidth: true; spacing: 6
                        Chip { prefs: win.prefs; label: "Install"; enabled: manifest.length <= 512; onActivated: win.message = win.prefs.installWidget(manifest.text) }
                        Chip { prefs: win.prefs; label: "Run self-test"; onActivated: {
                            const r=win.prefs.widgetSelfTest();
                            win.message=r.passed+"/"+r.total+" registry cases passed"+(r.failures.length ? " · failed: "+r.failures.join(", ") : "");
                        } }
                    }
                    Text { visible: win.managing; Layout.fillWidth: true; wrapMode: Text.WordWrap; textFormat: Text.PlainText; text: win.message; color: win.prefs.foreground }
                    Text { visible: win.managing; Layout.fillWidth: true; wrapMode: Text.WordWrap; text: win.prefs.settingsStatus; color: win.prefs.muted; font.pixelSize: 11 }
                }
            }
        }
    }
}
