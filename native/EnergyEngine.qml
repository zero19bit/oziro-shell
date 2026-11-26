import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower

// One verified power-source state for all surfaces. Unknown is not AC.
Scope {
    id: engine
    property string source: "unknown"
    property string rawSource: "unknown"
    property bool pending: false
    readonly property var battery: {
        const aggregate = UPower.displayDevice;
        if (aggregate && aggregate.ready && aggregate.isLaptopBattery && aggregate.isPresent) return aggregate;
        for (const device of UPower.devices.values)
            if (device.ready && device.isLaptopBattery && device.isPresent) return device;
        return null;
    }
    readonly property int percentage: battery ? Math.round(battery.percentage * 100) : -1
    readonly property bool monitorRunning: watcher.running
    readonly property bool checking: snapshot.running
    function refresh() {
        if (snapshot.running) { pending = true; return; }
        pending = false;
        rawSource = "unknown";
        snapshot.running = true;
    }
    function schedule() {
        if (!debounce.running) debounce.start();
    }
    Process {
        id: snapshot
        command: ["timeout","-k","1s","4s","busctl","--system","get-property","org.freedesktop.UPower","/org/freedesktop/UPower","org.freedesktop.UPower","OnBattery"]
        stdout: SplitParser {
            onRead: data => {
                const value = data.trim();
                if (value === "b true") engine.rawSource = "battery";
                else if (value === "b false") engine.rawSource = "ac";
            }
        }
        stderr: StdioCollector {}
        onExited: (code,status) => {
            const next = code === 0 ? engine.rawSource : "unknown";
            if (engine.source !== next) console.info("Oziro power source:", next);
            engine.source = next;
            if (engine.pending) engine.schedule();
        }
    }
    Process {
        id: watcher
        command: ["stdbuf","-oL","upower","--monitor"]
        stdout: SplitParser { onRead: data => engine.schedule() }
        stderr: StdioCollector {}
        onExited: (code,status) => { engine.schedule(); }
    }
    Timer {
        id: debounce
        interval: 300
        repeat: false
        onTriggered: engine.refresh()
    }
    // Slow reconciliation handles missed events, daemon restart or monitor failure.
    Timer {
        interval: 30000
        repeat: true
        running: true
        onTriggered: {
            if (!watcher.running) watcher.running = true;
            engine.refresh();
        }
    }
    Connections {
        target: UPower
        function onOnBatteryChanged() { engine.schedule(); }
    }
    Component.onCompleted: {
        watcher.running = true;
        refresh();
    }
}
