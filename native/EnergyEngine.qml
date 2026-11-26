import QtQuick
import Quickshell
import Quickshell.Services.UPower

// Pure reactive policy. No polling, command execution or hardware writes.
Scope {
    id: engine
    required property var prefs
    readonly property bool onBattery: UPower.onBattery
    readonly property var battery: {
        const aggregate = UPower.displayDevice;
        if (aggregate && aggregate.ready && aggregate.isLaptopBattery && aggregate.isPresent) return aggregate;
        for (const device of UPower.devices.values)
            if (device.ready && device.isLaptopBattery && device.isPresent) return device;
        return null;
    }
    readonly property int percentage: battery ? Math.round(battery.percentage * 100) : -1
    readonly property bool eco: prefs.reduceEffects || prefs.energyMode === "eco" ||
        (prefs.energyMode === "adaptive" && prefs.autoEco && onBattery)
    readonly property bool dockSuspended: prefs.dockEnabled && prefs.suspendDockOnBattery && onBattery && eco
    readonly property string reason: prefs.reduceEffects ? "Manual reduce effects" :
        prefs.energyMode === "eco" ? "Eco selected" :
        prefs.energyMode === "balanced" ? "Balanced selected" :
        !prefs.autoEco ? "Adaptive battery reduction disabled" :
        onBattery ? "Adaptive: battery power" : "Adaptive: AC power"
}
