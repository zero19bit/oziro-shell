import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: win
    required property var prefs
    signal dismiss()
    signal openAppearance()
    signal openWallpaper()
    signal openEnergy()
    signal openControls()
    signal openWidgets()
    signal openTray()
    signal openLock()
    signal openPower()
    signal openNotifications()
    property string section: "Personalization"
    anchors { top: win.prefs.layoutMode !== "bottom"; bottom: win.prefs.layoutMode === "bottom" }
    margins { top: win.prefs.popupMargin; bottom: win.prefs.popupMargin }
    implicitWidth: Math.min(880, screen ? Math.max(1,screen.width-32) : 880)
    implicitHeight: Math.min(640, screen ? Math.max(1,screen.height-win.prefs.popupMargin-40) : 640)
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    color: "transparent"
    Rectangle {
        anchors.fill: parent; color: win.prefs.popupColor; radius: 20; border.color: win.prefs.outline
        ColumnLayout {
            anchors.fill: parent; anchors.margins: 18; spacing: 12
            RowLayout {
                ColumnLayout {
                    Layout.fillWidth: true; spacing: 3
                    Text { text: "Oziro Settings"; color: win.prefs.foreground; font.pixelSize: 24; font.bold: true }
                    Text { text: "Your desktop, your way"; color: win.prefs.muted; font.pixelSize: 12 }
                }
                Chip { prefs: win.prefs; label: "Close"; onActivated: win.dismiss() }
            }
            RowLayout {
                Layout.fillWidth: true; Layout.fillHeight: true; spacing: 14
                Rectangle {
                    Layout.preferredWidth: win.width < 600 ? 112 : 190
                    Layout.fillHeight: true; color: win.prefs.cardColor; radius: 12
                    ColumnLayout {
                        anchors.fill: parent; anchors.margins: 8; spacing: 6
                        Repeater {
                            model: ["Personalization","System","Power & security","Apps & widgets","About"]
                            Chip {
                                required property string modelData
                                prefs: win.prefs; Layout.fillWidth: true
                                label: modelData; selected: win.section === modelData
                                onActivated: win.section = modelData
                            }
                        }
                        Item { Layout.fillHeight: true }
                    }
                }
                ScrollView {
                    id: scroll
                    Layout.fillWidth: true; Layout.fillHeight: true
                    rightPadding: 12; clip: true; contentWidth: availableWidth
                    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                    ColumnLayout {
                        width: scroll.availableWidth; spacing: 12
                        Text { Layout.fillWidth: true; text: win.section; color: win.prefs.foreground; font.pixelSize: 20; font.bold: true; wrapMode: Text.WordWrap }
                        ColumnLayout {
                            visible: win.section === "Personalization"; Layout.fillWidth: true; spacing: 10
                            SectionLabel { prefs: win.prefs; label: "DESIGN" }
                            Flow {
                                Layout.fillWidth: true; spacing: 6
                                Repeater {
                                    model: ["glass","material","minimal","cyber","light"]
                                    Chip { required property string modelData; prefs: win.prefs; label: modelData; selected: win.prefs.theme === modelData; onActivated: win.prefs.theme = modelData }
                                }
                            }
                            QuickToggle { Layout.fillWidth: true; prefs: win.prefs; label: "Dock"; detail: win.prefs.dockEnabled ? "Enabled" : "Disabled"; selected: win.prefs.dockEnabled; onActivated: win.prefs.dockEnabled = !win.prefs.dockEnabled }
                            QuickToggle { Layout.fillWidth: true; prefs: win.prefs; label: "24-hour clock"; detail: win.prefs.clock24Hour ? "24-hour" : "12-hour"; selected: win.prefs.clock24Hour; onActivated: win.prefs.clock24Hour = !win.prefs.clock24Hour }
                            Chip { prefs: win.prefs; label: "Theme Studio · colors, sizes and placement"; onActivated: win.openAppearance() }
                            Chip { prefs: win.prefs; label: "Wallpaper · background and local images"; onActivated: win.openWallpaper() }
                        }
                        ColumnLayout {
                            visible: win.section === "System"; Layout.fillWidth: true; spacing: 10
                            SectionLabel { prefs: win.prefs; label: "DEVICE CONTROLS" }
                            Text { Layout.fillWidth: true; wrapMode: Text.WordWrap; text: "Manage available Wi-Fi, Bluetooth, sound, brightness and system power profiles in Quick Controls."; color: win.prefs.muted }
                            Chip { prefs: win.prefs; label: "Open Quick Controls"; onActivated: win.openControls() }
                            SectionLabel { prefs: win.prefs; label: "DISPLAYS & INPUT" }
                            Text { Layout.fillWidth: true; wrapMode: Text.WordWrap; text: "Connected output: " + (win.screen ? win.screen.name : "Unknown") + (win.screen ? " · " + win.screen.width + " × " + win.screen.height + " logical px" : ""); color: win.prefs.foreground; textFormat: Text.PlainText }
                            Text { Layout.fillWidth: true; wrapMode: Text.WordWrap; text: "Display arrangement, resolution, keyboard and mouse configuration are not implemented yet."; color: win.prefs.muted }
                        }
                        ColumnLayout {
                            visible: win.section === "Power & security"; Layout.fillWidth: true; spacing: 10
                            SectionLabel { prefs: win.prefs; label: "ENERGY MODE" }
                            Flow {
                                Layout.fillWidth: true; spacing: 6
                                Repeater {
                                    model: ["adaptive","balanced","eco"]
                                    Chip { required property string modelData; prefs: win.prefs; label: modelData; selected: win.prefs.energyMode === modelData; onActivated: win.prefs.selectEnergyMode(modelData) }
                                }
                            }
                            Text { Layout.fillWidth: true; wrapMode: Text.WordWrap; text: win.prefs.powerLabel + " · " + win.prefs.energyReason; color: win.prefs.muted }
                            Chip { prefs: win.prefs; label: "Energy details"; onActivated: win.openEnergy() }
                            Chip { prefs: win.prefs; label: "Session lock"; enabled: !win.prefs.nestedPreview; onActivated: win.openLock() }
                            Chip { prefs: win.prefs; label: "Power menu"; onActivated: win.openPower() }
                            Text { Layout.fillWidth: true; wrapMode: Text.WordWrap; text: "Automatic lock and sleep integration are not ready."; color: win.prefs.muted }
                        }
                        ColumnLayout {
                            visible: win.section === "Apps & widgets"; Layout.fillWidth: true; spacing: 10
                            SectionLabel { prefs: win.prefs; label: "DESKTOP SERVICES" }
                            Chip { prefs: win.prefs; label: "Widget Center"; onActivated: win.openWidgets() }
                            Chip { prefs: win.prefs; label: "System Tray"; onActivated: win.openTray() }
                            Chip { prefs: win.prefs; label: "Notifications"; onActivated: win.openNotifications() }
                            Text { Layout.fillWidth: true; wrapMode: Text.WordWrap; text: "Notification ownership and default application management are not complete in the independent session."; color: win.prefs.muted }
                        }
                        ColumnLayout {
                            visible: win.section === "About"; Layout.fillWidth: true; spacing: 10
                            Text { text: "OZIRO"; color: win.prefs.accent; font.pixelSize: 36; font.bold: true }
                            Text { text: "Desktop Environment · 0.9.14"; color: win.prefs.foreground; font.pixelSize: 16 }
                            Text { Layout.fillWidth: true; wrapMode: Text.WordWrap; text: win.prefs.loginSession ? "Independent experimental login" : win.prefs.nestedPreview ? "Windowed development preview" : "Shell running in an existing session"; color: win.prefs.muted }
                            Text { Layout.fillWidth: true; wrapMode: Text.WordWrap; text: "Native QML / Quickshell · Wayland · Niri\nExperimental release. Oziro is not yet a standalone Linux distribution."; color: win.prefs.muted }
                        }
                    }
                }
            }
            Text { Layout.fillWidth: true; text: win.prefs.settingsStatus; color: win.prefs.muted; font.pixelSize: 11 }
        }
    }
}
