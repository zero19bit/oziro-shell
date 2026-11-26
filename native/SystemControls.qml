import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: sys
    property string wifi: "unavailable"
    property string bluetooth: "unavailable"
    property int brightness: -1
    property string profile: "unavailable"
    property var profiles: []
    property string message: "Reading system state"
    readonly property bool busy: runner.running
    function request(action, value) {
        if (busy) return;
        profiles = [];
        message = action === "status" ? "Refreshing…" : "Applying…";
        runner.command = ["bash", Quickshell.shellPath("system-controls.sh"), action, value || ""];
        runner.running = true;
    }
    function consume(line) {
        const eq = line.indexOf("=");
        if (eq < 0) return;
        const key = line.slice(0,eq), value = line.slice(eq+1).trim();
        if (key === "wifi" || key === "bluetooth") {
            if (["enabled","disabled","unavailable"].includes(value)) {
                if (key === "wifi") wifi = value; else bluetooth = value;
            }
        } else if (key === "brightness") {
            brightness = /^\d{1,3}$/.test(value) && Number(value) <= 100 ? Number(value) : -1;
        } else if (key === "profile") {
            profile = ["power-saver","balanced","performance"].includes(value) ? value : "unavailable";
        } else if (key === "available" && ["power-saver","balanced","performance"].includes(value)) {
            if (!profiles.includes(value)) profiles = profiles.concat([value]);
        } else if (key === "result") {
            message = value === "ok" ? "System state refreshed" : "Action failed — check service or permissions";
        }
    }
    Process {
        id: runner
        stdout: SplitParser { onRead: data => sys.consume(data) }
        stderr: StdioCollector {}
        onExited: (code, status) => {
            if (code !== 0) sys.message = "Action failed — check service or permissions";
        }
    }
    Component.onCompleted: request("status", "")
}
