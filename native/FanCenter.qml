import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

// One ordinary Wayland toplevel, not a full-screen layer or keyboard grab.
FloatingWindow {
    id: win
    required property var prefs
    signal dismiss()
    title: "Oziro Command Center"
    implicitWidth: 1040
    implicitHeight: 700
    minimumSize: Qt.size(640,480)
    color: prefs.popupColor
    onClosed: dismiss()
    property string page: "Overview"
    property var sample: null
    property string sensorStatus: "Reading hardware…"
    property string curveFan: "CPU"
    property var drafts: ({})
    property string baselineProfile: ""
    readonly property bool canChange: !prefs.nestedPreview && Quickshell.env("OZIRO_LOGIN_SESSION")==="1"
    readonly property var curves: sample ? sample.curves : []
    readonly property var currentCurve: curves.find(c=>c.fan===curveFan) || null
    readonly property var shownPoints: drafts[curveFan] || (currentCurve ? currentCurve.points : [])
    readonly property bool dirty: Object.keys(drafts).length>0
    function valueFor(kind) {
        if (!sample) return null;
        if (kind==="CPU FAN" || kind==="GPU FAN") {
            const name=kind==="CPU FAN"?"cpu_fan":"gpu_fan";
            const f=sample.fans.find(x=>x.driver==="asus" && x.label.toLowerCase()===name);
            return f ? f.rpm : null;
        }
        if (kind==="CPU") {
            const t=sample.temperatures.find(x=>x.driver==="k10temp" && x.label==="Tctl")
                || sample.temperatures.find(x=>x.driver==="coretemp" && x.label.indexOf("Package")===0);
            return t ? t.celsius : null;
        }
        const t=sample.temperatures.find(x=>x.driver==="amdgpu" && x.label==="edge");
        return t ? t.celsius : null;
    }
    function refresh() { if (!sensor.running) sensor.running=true; }
    function resetDraft() { drafts={}; baselineProfile=""; }
    function editPoint(index,value) {
        if (!currentCurve || index<0 || index>=shownPoints.length) return;
        const n=Number(value);
        if (!Number.isFinite(n)) return;
        const next=shownPoints.map((p,i)=>({temp:p.temp,pwm:i===index?Math.max(0,Math.min(255,Math.round(n*255/100))):p.pwm}));
        const copy=Object.assign({},drafts);
        copy[curveFan]=next;
        if (!dirty) baselineProfile=sample.platformProfile;
        drafts=copy;
    }
    function receive(line) {
        try {
            const s=JSON.parse(line);
            if (!Array.isArray(s.fans) || !Array.isArray(s.temperatures) || !Array.isArray(s.curves)) throw Error("invalid data");
            if (dirty && baselineProfile!==s.platformProfile) resetDraft();
            sample=s; sensorStatus="Live · refresh every 3 s";
        } catch(e) { sample=null; resetDraft(); sensorStatus="Invalid hardware snapshot"; }
    }
    SystemControls { id: sys }
    Process {
        id: sensor
        command: ["/usr/bin/timeout","-k","1s","4s","/usr/bin/python","-I",Quickshell.shellPath("fan-status.py")]
        stdout: SplitParser { onRead: line => win.receive(line) }
        stderr: StdioCollector {}
        onExited: (code,status) => { if (code!==0) { win.sample=null; win.resetDraft(); win.sensorStatus="Sensor reader unavailable"; } }
    }
    Timer { interval: 3000; repeat: true; running: win.visible; onTriggered: win.refresh() }
    Component.onCompleted: Qt.callLater(()=>win.refresh())
    Rectangle {
        anchors.fill: parent
        color: win.prefs.popupColor
        Keys.onEscapePressed: win.dismiss()
        focus: true
        RowLayout {
            anchors.fill: parent; spacing: 0
            Rectangle {
                Layout.fillHeight: true
                Layout.preferredWidth: win.width<800?150:196
                color: win.prefs.cardColor
                ColumnLayout {
                    anchors.fill: parent; anchors.margins: 14; spacing: 10
                    Text { Layout.fillWidth: true; text: "OZIRO"; color: win.prefs.accent; font.pixelSize: 24; font.bold: true }
                    Text { Layout.fillWidth: true; text: "COMMAND CENTER"; color: win.prefs.muted; font.pixelSize: 10; font.letterSpacing: 1.2; wrapMode: Text.WordWrap }
                    Rectangle { Layout.fillWidth: true; height: 1; color: win.prefs.outline }
                    Repeater {
                        model: ["Overview","Cooling","Hardware","Capabilities"]
                        MenuRow {
                            required property string modelData
                            Layout.fillWidth: true; prefs: win.prefs; label: modelData
                            selected: win.page===modelData; trailing: selected?"›":""
                            onActivated: win.page=modelData
                        }
                    }
                    Item { Layout.fillHeight: true }
                    Text { Layout.fillWidth: true; text: win.prefs.powerLabel; color: win.prefs.muted; font.pixelSize: 12; wrapMode: Text.WordWrap }
                    Text { Layout.fillWidth: true; text: win.prefs.batteryPercent>=0 ? win.prefs.batteryPercent+"% battery" : "Battery unavailable"; color: win.prefs.foreground; font.pixelSize: 13 }
                    Text { Layout.fillWidth: true; text: "0.9.25 · Command preview"; wrapMode: Text.WordWrap; color: win.prefs.muted; font.pixelSize: 10 }
                }
            }
            ColumnLayout {
                Layout.fillWidth: true; Layout.fillHeight: true; spacing: 0
                RowLayout {
                    Layout.fillWidth: true; Layout.margins: 20
                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 4
                        Text { Layout.fillWidth: true; text: win.page; color: win.prefs.foreground; font.pixelSize: 28; font.bold: true }
                        Text { Layout.fillWidth: true; text: win.sample ? win.sample.model || "Unknown hardware" : "Detecting hardware…"; color: win.prefs.muted; textFormat: Text.PlainText; elide: Text.ElideRight; font.pixelSize: 12 }
                    }
                    Chip { prefs: win.prefs; label: "Refresh"; enabled: !sensor.running && !sys.busy; onActivated: { win.refresh(); sys.request("status",""); } }
                    Chip { prefs: win.prefs; label: "×"; Accessible.name: "Close Command Center"; onActivated: win.dismiss() }
                }
                ScrollView {
                    id: scroll
                    Layout.fillWidth: true; Layout.fillHeight: true; Layout.leftMargin: 20; Layout.rightMargin: 20
                    clip: true; contentWidth: availableWidth
                    ColumnLayout {
                        width: scroll.availableWidth; spacing: 16
                        // Keep the views instantiated so draft data stays separate from live readings.
                        ColumnLayout {
                            Layout.fillWidth: true; visible: win.page==="Overview"; spacing: 16
                            GridLayout {
                                Layout.fillWidth: true; columns: 2; columnSpacing: 12; rowSpacing: 12
                                Repeater {
                                    model: ["CPU","GPU","CPU FAN","GPU FAN"]
                                    Rectangle {
                                        id: gauge
                                        required property string modelData
                                        readonly property var reading: win.valueFor(modelData)
                                        readonly property bool rpm: modelData.endsWith("FAN")
                                        Layout.fillWidth: true; Layout.preferredHeight: 142; Layout.minimumWidth: 120
                                        radius: 14; color: win.prefs.cardColor; border.color: win.prefs.outline
                                        ColumnLayout {
                                            anchors.fill: parent; anchors.margins: 14; spacing: 5
                                            Text { Layout.fillWidth: true; text: gauge.modelData; color: win.prefs.muted; font.pixelSize: 12; font.bold: true }
                                            Item { Layout.fillHeight: true }
                                            Text { Layout.fillWidth: true; text: gauge.reading===null?"—":gauge.rpm?String(gauge.reading):gauge.reading.toFixed(1)+"°"; color: win.prefs.accent; font.pixelSize: 32; font.bold: true; horizontalAlignment: Text.AlignHCenter }
                                            Text { Layout.fillWidth: true; text: gauge.reading===null?"Sensor unavailable":gauge.rpm?"Measured RPM":"Measured temperature · °C"; color: win.prefs.muted; font.pixelSize: 11; horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight }
                                            Item { Layout.fillHeight: true }
                                        }
                                    }
                                }
                            }
                            SectionLabel { prefs: win.prefs; label: "OPERATING MODE" }
                            RowLayout {
                                Layout.fillWidth: true; spacing: 8
                                Repeater {
                                    model: ["power-saver","balanced","performance"]
                                    Chip {
                                        required property string modelData
                                        Layout.fillWidth: true
                                        prefs: win.prefs
                                        label: modelData==="power-saver"?"Silent":modelData==="balanced"?"Balanced":"Performance"
                                        selected: sys.profile===modelData
                                        enabled: win.canChange && !sys.busy && sys.profiles.includes(modelData)
                                        onActivated: { win.resetDraft(); sys.request("profile",modelData); }
                                    }
                                }
                            }
                            Text { Layout.fillWidth: true; text: "System profile: "+sys.profile+" · Firmware: "+(win.sample && win.sample.platformProfile || "unavailable"); textFormat: Text.PlainText; color: win.prefs.foreground; wrapMode: Text.WordWrap }
                            Text { Layout.fillWidth: true; text: "System power profiles influence cooling and performance, not a fixed RPM. "+(sys.profiles.length?sys.message:"No compatible power profile provider."); color: win.prefs.muted; wrapMode: Text.WordWrap }
                            MenuRow { Layout.fillWidth: true; prefs: win.prefs; label: "Cooling and fan curves"; trailing: "›"; onActivated: win.page="Cooling" }
                        }
                        ColumnLayout {
                            Layout.fillWidth: true; visible: win.page==="Cooling"; spacing: 12
                            RowLayout {
                                Layout.fillWidth: true
                                SectionLabel { prefs: win.prefs; label: "FAN CURVES" }
                                Chip { prefs: win.prefs; label: "CPU"; selected: win.curveFan==="CPU"; onActivated: win.curveFan="CPU" }
                                Chip { prefs: win.prefs; label: "GPU"; selected: win.curveFan==="GPU"; onActivated: win.curveFan="GPU" }
                            }
                            Text { Layout.fillWidth: true; color: win.prefs.muted; wrapMode: Text.WordWrap; text: win.currentCurve ? "Firmware profile: "+win.sample.platformProfile+" · Controller mode: "+(win.currentCurve.mode===null?"unknown":win.currentCurve.mode)+" · "+(win.drafts[win.curveFan]?"Unsaved preview":"Driver-reported curve") : "No complete ASUS curve available for this fan." }
                            Rectangle {
                                Layout.fillWidth: true; Layout.preferredHeight: 238; radius: 12; color: win.prefs.cardColor; border.color: win.prefs.outline
                                Canvas {
                                    id: chart
                                    anchors.fill: parent; anchors.margins: 8
                                    property var points: win.shownPoints
                                    property color lineColor: win.prefs.accent
                                    property color gridColor: win.prefs.outline
                                    property color labelColor: win.prefs.muted
                                    onPointsChanged: requestPaint()
                                    onLineColorChanged: requestPaint()
                                    onGridColorChanged: requestPaint()
                                    onLabelColorChanged: requestPaint()
                                    onWidthChanged: requestPaint()
                                    onHeightChanged: requestPaint()
                                    onPaint: {
                                        const c=getContext("2d");
                                        c.clearRect(0,0,width,height);
                                        const l=40,r=Math.max(l+1,width-16),t=12,b=Math.max(t+1,height-28);
                                        c.font="11px sans-serif"; c.textAlign="right"; c.textBaseline="middle";
                                        c.strokeStyle=gridColor; c.fillStyle=labelColor; c.lineWidth=1;
                                        for (let p=0;p<=100;p+=25) { const y=b-p*(b-t)/100; c.beginPath(); c.moveTo(l,y); c.lineTo(r,y); c.stroke(); c.fillText(p+"%",l-5,y); }
                                        c.textAlign="center";
                                        for (let d=0;d<=100;d+=20) { const x=l+d*(r-l)/100; c.fillText(d+"°",x,b+15); }
                                        if (!points.length) return;
                                        c.strokeStyle=lineColor; c.fillStyle=lineColor; c.lineWidth=2.5;
                                        c.beginPath();
                                        for(let i=0;i<points.length;i++){ const p=points[i],x=l+p.temp*(r-l)/100,y=b-p.pwm*(b-t)/255; if(i===0)c.moveTo(x,y);else c.lineTo(x,y); }
                                        c.stroke();
                                        for(const p of points){const x=l+p.temp*(r-l)/100,y=b-p.pwm*(b-t)/255;c.beginPath();c.arc(x,y,4,0,Math.PI*2);c.fill();}
                                    }
                                }
                            }
                            Text { Layout.fillWidth: true; text: "Edit duty values numerically to preview a curve. PWM duty is not RPM."; color: win.prefs.muted; wrapMode: Text.WordWrap }
                            GridLayout {
                                Layout.fillWidth: true; columns: win.width<850?2:4; columnSpacing: 8; rowSpacing: 8
                                Repeater {
                                    model: win.shownPoints
                                    ColumnLayout {
                                        id: point
                                        required property var modelData
                                        required property int index
                                        Layout.fillWidth: true; spacing: 4
                                        Text { text: point.modelData.temp+" °C"; color: win.prefs.muted; font.pixelSize: 12 }
                                        SpinBox {
                                            Layout.fillWidth: true; from: 0; to: 100; editable: true
                                            value: Math.round(point.modelData.pwm*100/255)
                                            onValueModified: win.editPoint(point.index,value)
                                            Accessible.name: "Preview fan duty at "+point.modelData.temp+" degrees"
                                        }
                                    }
                                }
                            }
                            RowLayout {
                                Layout.fillWidth: true
                                Chip { prefs: win.prefs; label: "Discard preview"; enabled: win.dirty; onActivated: win.resetDraft() }
                                Item { Layout.fillWidth: true }
                                Chip { prefs: win.prefs; label: "Apply to hardware"; enabled: false }
                            }
                            Text { Layout.fillWidth: true; wrapMode: Text.WordWrap; color: win.prefs.muted; text: "Preview only. Hardware writes and fixed RPM are not validated. No curve, fan mode, or firmware setting is changed by this editor." }
                        }
                        ColumnLayout {
                            Layout.fillWidth: true; visible: win.page==="Hardware"; spacing: 10
                            SectionLabel { prefs: win.prefs; label: "FAN SENSORS" }
                            Repeater {
                                model: win.sample ? win.sample.fans : []
                                RowLayout {
                                    required property var modelData
                                    Layout.fillWidth: true
                                    Text { Layout.fillWidth: true; text: modelData.driver+" · "+modelData.label; textFormat: Text.PlainText; color: win.prefs.foreground; elide: Text.ElideRight }
                                    Text { text: modelData.rpm+" RPM"; color: win.prefs.accent }
                                }
                            }
                            SectionLabel { prefs: win.prefs; label: "TEMPERATURE SENSORS" }
                            Repeater {
                                model: win.sample ? win.sample.temperatures : []
                                RowLayout {
                                    required property var modelData
                                    Layout.fillWidth: true
                                    Text { Layout.fillWidth: true; text: modelData.driver+" · "+modelData.label; textFormat: Text.PlainText; color: win.prefs.foreground; elide: Text.ElideRight }
                                    Text { text: modelData.celsius.toFixed(1)+" °C"; color: win.prefs.accent }
                                }
                            }
                            Text { Layout.fillWidth: true; text: "No active GPU polling or synthetic readings. Missing values remain unavailable."; color: win.prefs.muted; wrapMode: Text.WordWrap }
                        }
                        ColumnLayout {
                            Layout.fillWidth: true; visible: win.page==="Capabilities"; spacing: 10
                            SectionLabel { prefs: win.prefs; label: "DETECTED SUPPORT" }
                            Text { Layout.fillWidth: true; text: win.sample ? "ASUS CLI: "+(win.sample.asusctl?"installed":"not detected")+"\nFirmware profiles: "+(win.sample.platformChoices.join(", ")||"unavailable")+"\nComplete fan curves: "+win.curves.length : "Waiting for hardware"; textFormat: Text.PlainText; color: win.prefs.foreground; wrapMode: Text.WordWrap }
                            SectionLabel { prefs: win.prefs; label: "NOT AVAILABLE IN THIS BUILD" }
                            Text { Layout.fillWidth: true; color: win.prefs.muted; wrapMode: Text.WordWrap; text: "Fixed RPM / hardware curve writes\nGPU switching / power limits\nBattery charge cap\nKeyboard RGB and game profiles\n\nThese require individually validated providers. No privileged helper or daemon is installed." }
                        }
                    }
                }
                Text { Layout.fillWidth: true; Layout.margins: 14; text: win.sensorStatus+(win.canChange?" · Local hardware":" · Read-only preview"); color: win.prefs.muted; font.pixelSize: 11; elide: Text.ElideRight }
            }
        }
    }
}
