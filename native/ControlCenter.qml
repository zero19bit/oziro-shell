import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pipewire

ShellPopup {
    id: win
    signal openSettings()
    signal openEnergy()
    signal openWidgets()
    signal openTray()
    signal openLock()
    signal openPower()
    SystemControls { id: sys }
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property bool audioReady: Pipewire.ready && sink !== null && sink.audio !== null
    menuWidth: Math.min(500, screen ? Math.max(1, screen.width - 24) : 500)
    menuHeight: Math.min(660, screen ? Math.max(1, screen.height - win.prefs.popupMargin - 36) : 660)
    Rectangle {
        focus: true
        Keys.onEscapePressed: { if (!win.dismissBlocked) win.dismiss(); }
        x: win.bodyX; y: win.bodyY; width: win.bodyWidth; height: win.bodyHeight
        color: win.prefs.popupColor
        border.color: win.prefs.outline
        radius: 20
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 10
            RowLayout {
                Text { text: "Control Center"; color: win.prefs.foreground; font.pixelSize: 20; font.bold: true; Layout.fillWidth: true; elide: Text.ElideRight }
                Chip { prefs: win.prefs; label: sys.busy ? "Reading…" : "Refresh"; enabled: !sys.busy; onActivated: { win.prefs.refreshPower(); sys.request("status", ""); } }
                Chip { prefs: win.prefs; label: "Close"; onActivated: win.dismiss() }
            }
            ScrollView {
                id: scroll
                Layout.fillHeight: true
                Layout.fillWidth: true
                rightPadding: 12
                clip: true
                contentWidth: availableWidth
                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                ScrollBar.vertical.policy: ScrollBar.AsNeeded
                ColumnLayout {
                    width: scroll.availableWidth
                    spacing: 9
                    SectionLabel { prefs: win.prefs; label: "CONNECTIVITY" }
                    GridLayout {
                        Layout.fillWidth: true
                        columns: width >= 290 ? 2 : 1
                        columnSpacing: 8
                        rowSpacing: 8
                        QuickToggle {
                            Layout.fillWidth: true
                            prefs: win.prefs
                            label: "Wi-Fi"
                            detail: sys.wifi
                            selected: sys.wifi === "enabled"
                            enabled: !win.prefs.nestedPreview && !sys.busy && sys.wifi !== "unavailable"
                            onActivated: sys.request("wifi", sys.wifi === "enabled" ? "off" : "on")
                        }
                        QuickToggle {
                            Layout.fillWidth: true
                            prefs: win.prefs
                            label: "Bluetooth"
                            detail: sys.bluetooth
                            selected: sys.bluetooth === "enabled"
                            enabled: !win.prefs.nestedPreview && !sys.busy && sys.bluetooth !== "unavailable"
                            onActivated: sys.request("bluetooth", sys.bluetooth === "enabled" ? "off" : "on")
                        }
                    }
                    Text { Layout.fillWidth: true; wrapMode: Text.WordWrap; text: sys.message; color: win.prefs.muted; font.pixelSize: 11 }
                    SectionLabel { prefs: win.prefs; label: "DISPLAY & SOUND" }
                    Rectangle {
                        id: levels
                        Layout.fillWidth: true
                        implicitHeight: levelsContent.implicitHeight + 20
                        color: win.prefs.cardColor
                        border.color: win.prefs.outline
                        radius: 12
                        ColumnLayout {
                            id: levelsContent
                            anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
                            anchors.margins: 10
                            spacing: 4
                            RowLayout {
                                Text { Layout.fillWidth: true; text: "Brightness"; color: win.prefs.foreground; font.weight: Font.Medium }
                                Text { text: sys.brightness >= 0 ? sys.brightness + "%" : "Unavailable"; color: win.prefs.muted }
                            }
                            RowLayout {
                                Layout.fillWidth: true
                                Chip { prefs: win.prefs; label: "−10%"; enabled: !win.prefs.nestedPreview && !sys.busy && sys.brightness > 5; onActivated: sys.request("brightness", String(Math.max(5, sys.brightness - 10))) }
                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 7; radius: 4; color: win.prefs.outline
                                    Rectangle { width: parent.width * Math.max(0,sys.brightness)/100; height: parent.height; radius: 4; color: win.prefs.accent }
                                }
                                Chip { prefs: win.prefs; label: "+10%"; enabled: !win.prefs.nestedPreview && !sys.busy && sys.brightness >= 0 && sys.brightness < 100; onActivated: sys.request("brightness", String(Math.min(100, sys.brightness + 10))) }
                            }
                            RowLayout {
                                Text { Layout.fillWidth: true; text: "Audio output"; color: win.prefs.foreground; font.weight: Font.Medium }
                                Text { text: win.audioReady ? Math.round(win.sink.audio.volume*100) + "%" : "Unavailable"; color: win.prefs.muted }
                            }
                            RowLayout {
                                Layout.fillWidth: true
                                AccentSlider {
                                    prefs: win.prefs
                                    Layout.fillWidth: true
                                    enabled: !win.prefs.nestedPreview && win.audioReady
                                    from: 0; to: 1
                                    value: win.audioReady ? Math.min(1, win.sink.audio.volume) : 0
                                    onMoved: { if (win.audioReady) win.sink.audio.volume = value; }
                                }
                                Chip { prefs: win.prefs; enabled: !win.prefs.nestedPreview && win.audioReady; label: enabled && win.sink.audio.muted ? "Unmute" : "Mute"; onActivated: { if (enabled) win.sink.audio.muted = !win.sink.audio.muted; } }
                            }
                        }
                    }
                    SectionLabel { prefs: win.prefs; label: "POWER & BATTERY" }
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 64
                        color: win.prefs.cardColor; border.color: win.prefs.outline; radius: 12
                        RowLayout {
                            anchors.fill: parent; anchors.margins: 10; spacing: 10
                            Rectangle {
                                Layout.preferredWidth: 30; Layout.preferredHeight: 17
                                radius: 4; border.color: win.prefs.muted; color: "transparent"
                                Rectangle { x: 3; y: 3; height: 11; width: 24*Math.max(0,Math.min(100,win.prefs.batteryPercent))/100; radius: 2; color: win.prefs.accent }
                                Rectangle { x: parent.width; anchors.verticalCenter: parent.verticalCenter; width: 3; height: 7; radius: 1; color: win.prefs.muted }
                            }
                            ColumnLayout {
                                Layout.fillWidth: true; spacing: 3
                                Text { text: "Battery"; color: win.prefs.foreground; font.weight: Font.Medium }
                                Text { text: win.prefs.powerLabel; color: win.prefs.muted; font.pixelSize: 11 }
                            }
                            Text { text: win.prefs.batteryPercent >= 0 ? win.prefs.batteryPercent + "%" : "N/A"; color: win.prefs.foreground; font.pixelSize: 24; font.bold: true }
                        }
                    }
                    Text { Layout.fillWidth: true; text: "System profile · " + sys.profile; color: win.prefs.foreground; font.weight: Font.Medium }
                    Flow {
                        Layout.fillWidth: true; spacing: 6
                        Repeater {
                            model: ["power-saver","balanced","performance"]
                            Chip { required property string modelData; prefs: win.prefs; label: modelData; selected: sys.profile === modelData; enabled: !win.prefs.nestedPreview && !sys.busy && sys.profiles.includes(modelData); onActivated: sys.request("profile", modelData) }
                        }
                    }
                    Text { Layout.fillWidth: true; wrapMode: Text.WordWrap; text: "System profiles and Oziro effects are separate."; color: win.prefs.muted; font.pixelSize: 11 }
                    Flow {
                        Layout.fillWidth: true; spacing: 6
                        Chip { prefs: win.prefs; label: "Reduce effects"; selected: win.prefs.eco; onActivated: win.prefs.selectEnergyMode(win.prefs.eco ? "balanced" : "eco") }
                        Chip { prefs: win.prefs; label: "Auto on battery"; enabled: win.prefs.energyMode === "adaptive"; selected: win.prefs.autoEco; onActivated: win.prefs.autoEco = !win.prefs.autoEco }
                        Chip { prefs: win.prefs; label: win.prefs.dockSuspended ? "Dock paused" : "Dock"; selected: win.prefs.dockEnabled; onActivated: win.prefs.dockEnabled = !win.prefs.dockEnabled }
                    }
                    Text { Layout.fillWidth: true; wrapMode: Text.WordWrap; text: (win.prefs.eco ? "Eco rendering · " : "Standard rendering · ") + win.prefs.energyReason; color: win.prefs.muted; font.pixelSize: 11 }
                }
            }
            Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: win.prefs.outline }
            Flow {
                Layout.fillWidth: true; spacing: 6
                Chip { prefs: win.prefs; label: "Settings"; onActivated: win.openSettings() }
                Chip { prefs: win.prefs; label: "Energy"; onActivated: win.openEnergy() }
                Chip { prefs: win.prefs; label: "Widgets"; onActivated: win.openWidgets() }
                Chip { prefs: win.prefs; label: "Tray"; onActivated: win.openTray() }
                Chip { prefs: win.prefs; label: "Power"; onActivated: win.openPower() }
            }
        }
    }
}
