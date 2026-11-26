import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pipewire

PanelWindow {
    id: win
    required property var prefs
    signal dismiss()
    signal openSettings()
    signal openEnergy()
    SystemControls { id: sys }
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property bool audioReady: Pipewire.ready && sink !== null && sink.audio !== null
    anchors { top: win.prefs.layoutMode !== "bottom"; bottom: win.prefs.layoutMode === "bottom"; right: true }
    margins { top: win.prefs.popupMargin; bottom: win.prefs.popupMargin; right: 12 }
    implicitWidth: Math.min(470, screen ? Math.max(1, screen.width - 24) : 470)
    implicitHeight: Math.min(650, screen ? Math.max(1, screen.height - 140) : 650)
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    color: "transparent"
    Rectangle {
        anchors.fill: parent
        color: win.prefs.surfaceColor
        border.color: win.prefs.outline
        radius: 20
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 18
            spacing: 10
            RowLayout {
                Text { text: "Control Center"; color: win.prefs.foreground; font.pixelSize: 20; font.bold: true; Layout.fillWidth: true }
                Chip { prefs: win.prefs; label: "Settings"; onActivated: win.openSettings() }
                Chip { prefs: win.prefs; label: "Close"; onActivated: win.dismiss() }
            }
            ScrollView {
                Layout.fillHeight: true
                Layout.fillWidth: true
                contentWidth: availableWidth
                ColumnLayout {
                    width: parent.width
                    spacing: 10
                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: "SYSTEM"; color: win.prefs.accent; font.bold: true; Layout.fillWidth: true }
                        Chip { prefs: win.prefs; label: sys.busy ? "Working…" : "Refresh"; enabled: !sys.busy; onActivated: { win.prefs.refreshPower(); sys.request("status", ""); } }
                    }
                    GridLayout {
                        Layout.fillWidth: true
                        columns: 2
                        columnSpacing: 8
                        rowSpacing: 8
                        Chip {
                            Layout.fillWidth: true
                            prefs: win.prefs
                            label: "Wi-Fi · " + sys.wifi
                            selected: sys.wifi === "enabled"
                            enabled: !sys.busy && sys.wifi !== "unavailable"
                            onActivated: sys.request("wifi", sys.wifi === "enabled" ? "off" : "on")
                        }
                        Chip {
                            Layout.fillWidth: true
                            prefs: win.prefs
                            label: "Bluetooth · " + sys.bluetooth
                            selected: sys.bluetooth === "enabled"
                            enabled: !sys.busy && sys.bluetooth !== "unavailable"
                            onActivated: sys.request("bluetooth", sys.bluetooth === "enabled" ? "off" : "on")
                        }
                    }
                    Text { Layout.fillWidth: true; wrapMode: Text.WordWrap; text: sys.message; color: win.prefs.muted; font.pixelSize: 11 }
                    Text { text: sys.brightness >= 0 ? "Display brightness · " + sys.brightness + "%" : "Brightness unavailable"; color: win.prefs.muted }
                    RowLayout {
                        Layout.fillWidth: true
                        Chip { prefs: win.prefs; label: "−10%"; enabled: !sys.busy && sys.brightness > 5; onActivated: sys.request("brightness", String(Math.max(5, sys.brightness - 10))) }
                        Rectangle {
                            Layout.fillWidth: true
                            height: 6; radius: 3; color: win.prefs.outline
                            Rectangle { width: parent.width * Math.max(0,sys.brightness)/100; height: parent.height; radius: 3; color: win.prefs.accent }
                        }
                        Chip { prefs: win.prefs; label: "+10%"; enabled: !sys.busy && sys.brightness >= 0 && sys.brightness < 100; onActivated: sys.request("brightness", String(Math.min(100, sys.brightness + 10))) }
                    }
                    Text { text: win.audioReady ? "Audio output" : "Audio unavailable"; color: win.prefs.muted }
                    RowLayout {
                        Layout.fillWidth: true
                        Slider {
                            Layout.fillWidth: true
                            enabled: win.audioReady
                            from: 0; to: 1
                            value: win.audioReady ? Math.min(1, win.sink.audio.volume) : 0
                            onMoved: { if (win.audioReady) win.sink.audio.volume = value }
                        }
                        Chip {
                            prefs: win.prefs
                            enabled: win.audioReady
                            label: enabled && win.sink.audio.muted ? "Unmute" : "Mute"
                            onActivated: { if (enabled) win.sink.audio.muted = !win.sink.audio.muted }
                        }
                    }
                    Text {
                        Layout.fillWidth: true
                        text: win.prefs.batteryPercent >= 0 ? "Battery · " + win.prefs.batteryPercent + "% · " + win.prefs.powerLabel : "Battery unavailable · " + win.prefs.powerLabel
                        color: win.prefs.foreground
                    }
                    Text { text: "System power profile · " + sys.profile; color: win.prefs.accent; font.bold: true }
                    Flow {
                        Layout.fillWidth: true
                        spacing: 6
                        Repeater {
                            model: ["power-saver","balanced","performance"]
                            Chip {
                                required property string modelData
                                prefs: win.prefs
                                label: modelData
                                selected: sys.profile === modelData
                                enabled: !sys.busy && sys.profiles.includes(modelData)
                                onActivated: sys.request("profile", modelData)
                            }
                        }
                    }
                    Text { Layout.fillWidth: true; wrapMode: Text.WordWrap; text: "System profiles are separate from Oziro rendering. Unsupported services are disabled."; color: win.prefs.muted; font.pixelSize: 11 }
                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: "Energy / shell effects"; color: win.prefs.accent; font.bold: true; Layout.fillWidth: true }
                        Chip { prefs: win.prefs; label: "Energy"; onActivated: win.openEnergy() }
                    }
                    RowLayout {
                        Chip { prefs: win.prefs; label: "Reduce effects"; selected: win.prefs.eco; onActivated: win.prefs.selectEnergyMode(win.prefs.eco ? "balanced" : "eco") }
                        Chip { prefs: win.prefs; label: "Auto on battery"; enabled: win.prefs.energyMode === "adaptive"; selected: win.prefs.autoEco; onActivated: win.prefs.autoEco = !win.prefs.autoEco }
                    }
                    Text { text: (win.prefs.eco ? "Eco rendering · " : "Standard rendering · ") + win.prefs.energyReason; color: win.prefs.muted }
                    Text { text: "Appearance"; color: win.prefs.accent; font.bold: true }
                    Flow {
                        Layout.fillWidth: true
                        spacing: 6
                        Repeater {
                            model: ["glass","material","minimal","cyber","light"]
                            Chip { required property string modelData; prefs: win.prefs; label: modelData; selected: win.prefs.theme === modelData; onActivated: win.prefs.theme = modelData }
                        }
                    }
                    Text { text: "Panel layout"; color: win.prefs.accent; font.bold: true }
                    Flow {
                        Layout.fillWidth: true
                        spacing: 6
                        Repeater {
                            model: ["floating","top","bottom"]
                            Chip { required property string modelData; prefs: win.prefs; label: modelData; selected: win.prefs.layoutMode === modelData; onActivated: win.prefs.layoutMode = modelData }
                        }
                    }
                    Text { text: "Dock"; color: win.prefs.accent; font.bold: true }
                    Chip {
                        prefs: win.prefs
                        label: win.prefs.dockSuspended ? "Dock paused by Energy" : win.prefs.dockEnabled ? "Dock enabled" : "Enable dock"
                        selected: win.prefs.dockEnabled
                        onActivated: win.prefs.dockEnabled = !win.prefs.dockEnabled
                    }
                    Text { Layout.fillWidth: true; wrapMode: Text.WordWrap; text: "Pin apps using + in the launcher. Disable the dock to release its UI."; color: win.prefs.muted; font.pixelSize: 11 }
                    Text { Layout.fillWidth: true; text: win.prefs.settingsStatus; color: win.prefs.muted; font.pixelSize: 12 }
                    Text { Layout.fillWidth: true; wrapMode: Text.WordWrap; text: "Eco changes shell effects, not CPU or hardware power limits."; color: win.prefs.muted; font.pixelSize: 11 }
                }
            }
        }
    }
}
