import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell

FloatingWindow {
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
    property string section: "Appearance"
    title: "System Settings"
    implicitWidth: 840
    implicitHeight: 570
    minimumSize: Qt.size(580,420)
    color: win.prefs.popupColor
    onVisibleChanged: { if (!visible) Qt.callLater(win.dismiss); }
    RowLayout {
        anchors.fill: parent; spacing: 0
        Rectangle {
            Layout.preferredWidth: 208; Layout.fillHeight: true; color: win.prefs.cardColor
            ColumnLayout {
                anchors.fill: parent; anchors.margins: 14; spacing: 5
                RowLayout { Image { source: Qt.resolvedUrl("oziro-mark.svg"); Layout.preferredWidth: 24; Layout.preferredHeight: 24; sourceSize.width: 32; sourceSize.height: 32 } Text { Layout.fillWidth: true; text: "System Settings"; color: win.prefs.foreground; font.pixelSize: 17; font.weight: Font.DemiBold; Layout.bottomMargin: 12 } }
                Text { text: "Desktop"; color: win.prefs.muted; font.pixelSize: 11; Layout.topMargin: 6 }
                Repeater {
                    model: ["Appearance","Desktop & Dock","Wallpaper"]
                    MenuRow { required property string modelData; Layout.fillWidth: true; prefs: win.prefs; label: modelData; selected: win.section===modelData; onActivated: win.section=modelData }
                }
                Text { text: "System"; color: win.prefs.muted; font.pixelSize: 11; Layout.topMargin: 12 }
                Repeater {
                    model: ["Devices","Power & Security","Apps & Widgets","About"]
                    MenuRow { required property string modelData; Layout.fillWidth: true; prefs: win.prefs; label: modelData; selected: win.section===modelData; onActivated: win.section=modelData }
                }
                Item { Layout.fillHeight: true }
                Text { text: "Oziro 0.9.22"; color: win.prefs.muted; font.pixelSize: 11 }
            }
        }
        Rectangle { Layout.fillHeight: true; Layout.preferredWidth: 1; color: win.prefs.outline }
        ColumnLayout {
            Layout.fillWidth: true; Layout.fillHeight: true; Layout.margins: 22; spacing: 16
            RowLayout {
                Text { Layout.fillWidth: true; text: win.section; color: win.prefs.foreground; font.pixelSize: 21; font.weight: Font.DemiBold }
                Chip { prefs: win.prefs; label: "Close"; onActivated: win.dismiss() }
            }
            ScrollView {
                id: scroll; Layout.fillWidth: true; Layout.fillHeight: true; clip: true; contentWidth: availableWidth
                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                ColumnLayout {
                    width: scroll.availableWidth; spacing: 14
                    ColumnLayout {
                        visible: win.section==="Appearance"; Layout.fillWidth: true; spacing: 12
                        Text { text: "Theme & matching wallpaper"; color: win.prefs.muted; font.pixelSize: 12 }
                        GridLayout {
                            Layout.fillWidth: true; columns: 2; columnSpacing: 10; rowSpacing: 10
                            Repeater {
                                model: win.prefs.themeCatalog
                                AbstractButton {
                                    id: tile
                                    required property var modelData
                                    Layout.fillWidth: true; implicitHeight: 116
                                    Accessible.name: modelData.name
                                    onClicked: win.prefs.useThemePack(modelData.id)
                                    background: Rectangle { radius: 7; color: "transparent"; border.width: win.prefs.theme===tile.modelData.id || tile.activeFocus ? 2 : 1; border.color: win.prefs.theme===tile.modelData.id || tile.activeFocus ? win.prefs.accent : win.prefs.outline }
                                    contentItem: ColumnLayout {
                                        spacing: 5
                                        Rectangle {
                                            Layout.fillWidth: true; Layout.preferredHeight: 76; radius: 4; color: tile.modelData.bg; clip: true
                                            Image { anchors.fill: parent; source: win.prefs.themeWallpaper(tile.modelData.id); sourceSize.width: 320; sourceSize.height: 180; fillMode: Image.PreserveAspectCrop; asynchronous: true }
                                            Rectangle { anchors.left: parent.left; anchors.right: parent.right; height: 6; color: tile.modelData.surface }
                                            Rectangle { anchors.centerIn: parent; width: parent.width*0.55; height: 24; radius: 3; color: tile.modelData.surface }
                                        }
                                        Text { Layout.alignment: Qt.AlignHCenter; text: tile.modelData.name; color: win.prefs.foreground; font.pixelSize: 12 }
                                    }
                                }
                            }
                        }
                        Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: win.prefs.outline }
                        MenuRow { Layout.fillWidth: true; prefs: win.prefs; label: "Accent color and advanced appearance"; trailing: "›"; onActivated: win.openAppearance() }
                    }
                    ColumnLayout {
                        visible: win.section==="Desktop & Dock"; Layout.fillWidth: true; spacing: 12
                        RowLayout { Layout.fillWidth: true; Text { Layout.fillWidth: true; text: "Show Dock"; color: win.prefs.foreground } Switch { checked: win.prefs.dockEnabled; onToggled: win.prefs.dockEnabled=checked } }
                        RowLayout { Layout.fillWidth: true; Text { Layout.fillWidth: true; text: "Dock magnification"; color: win.prefs.foreground } Switch { checked: win.prefs.dockMagnification; onToggled: win.prefs.dockMagnification=checked } }
                        Text { Layout.fillWidth: true; visible: win.prefs.eco; wrapMode: Text.WordWrap; text: "Magnification paused · " + win.prefs.energyReason; color: win.prefs.muted; font.pixelSize: 12 }
                        MenuRow { Layout.fillWidth: true; visible: win.prefs.eco; prefs: win.prefs; label: "Use Balanced energy mode"; trailing: "›"; onActivated: win.prefs.selectEnergyMode("balanced") }
                        Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: win.prefs.outline }
                        RowLayout { Layout.fillWidth: true; Text { Layout.fillWidth: true; text: "24-hour clock"; color: win.prefs.foreground } Switch { checked: win.prefs.clock24Hour; onToggled: win.prefs.clock24Hour=checked } }
                        Text { text: "Menu bar position"; color: win.prefs.muted; font.pixelSize: 12 }
                        Flow { Layout.fillWidth: true; spacing: 6; Repeater { model: ["top","floating","bottom"]; Chip { required property string modelData; prefs: win.prefs; label: modelData; selected: win.prefs.layoutMode===modelData; onActivated: win.prefs.layoutMode=modelData } } }
                        MenuRow { Layout.fillWidth: true; prefs: win.prefs; label: "Panel and Dock size"; trailing: "›"; onActivated: win.openAppearance() }
                    }
                    ColumnLayout {
                        visible: win.section==="Wallpaper"; Layout.fillWidth: true; spacing: 12
                        Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 140; radius: 8; color: win.prefs.wallpaper.color; clip: true
                            Image { anchors.fill: parent; source: win.prefs.wallpaperUrl; fillMode: Image.PreserveAspectCrop; sourceSize.width: 480; sourceSize.height: 270; asynchronous: true; cache: false }
                        }
                        RowLayout { Layout.fillWidth: true; Text { Layout.fillWidth: true; text: "Show wallpaper"; color: win.prefs.foreground } Switch { checked: win.prefs.wallpaper.enabled; onToggled: win.prefs.updateWallpaper("enabled",checked) } }
                        MenuRow { Layout.fillWidth: true; prefs: win.prefs; label: "Choose wallpaper"; trailing: "›"; onActivated: win.openWallpaper() }
                    }
                    ColumnLayout {
                        visible: win.section==="Devices"; Layout.fillWidth: true; spacing: 12
                        Text { Layout.fillWidth: true; text: "Sound, network and brightness"; color: win.prefs.foreground; font.pixelSize: 15 }
                        MenuRow { Layout.fillWidth: true; prefs: win.prefs; label: "Control Center"; trailing: "›"; onActivated: win.openControls() }
                        Text { Layout.fillWidth: true; wrapMode: Text.WordWrap; text: "Oziro login: tap to click, two-finger right click and natural scrolling. Host desktop input settings remain unchanged."; color: win.prefs.muted }
                        Text { Layout.fillWidth: true; text: "Screenshot shortcuts (Oziro login)"; color: win.prefs.foreground; font.weight: Font.Medium }
                        Text { Layout.fillWidth: true; text: "Print / Super+Shift+S  ·  Select area\nCtrl+Print  ·  Focused screen\nAlt+Print  ·  Focused window"; color: win.prefs.muted; wrapMode: Text.WordWrap }
                        Text { Layout.fillWidth: true; wrapMode: Text.WordWrap; text: "Custom shortcuts, display arrangement and editable input settings are not available yet."; color: win.prefs.muted }
                    }
                    ColumnLayout {
                        visible: win.section==="Power & Security"; Layout.fillWidth: true; spacing: 12
                        Text { text: "Energy mode"; color: win.prefs.muted; font.pixelSize: 12 }
                        Flow { Layout.fillWidth: true; spacing: 6; Repeater { model: ["adaptive","balanced","eco"]; Chip { required property string modelData; prefs: win.prefs; label: modelData; selected: win.prefs.energyMode===modelData; onActivated: win.prefs.selectEnergyMode(modelData) } } }
                        MenuRow { Layout.fillWidth: true; prefs: win.prefs; label: "Battery and energy"; trailing: "›"; onActivated: win.openEnergy() }
                        MenuRow { Layout.fillWidth: true; prefs: win.prefs; label: "Lock Screen"; trailing: "›"; enabled: !win.prefs.nestedPreview; onActivated: win.openLock() }
                        MenuRow { Layout.fillWidth: true; prefs: win.prefs; label: "Power menu"; trailing: "›"; onActivated: win.openPower() }
                        Text { Layout.fillWidth: true; wrapMode: Text.WordWrap; text: "Automatic lock and sleep are not implemented."; color: win.prefs.muted }
                    }
                    ColumnLayout {
                        visible: win.section==="Apps & Widgets"; Layout.fillWidth: true; spacing: 8
                        MenuRow { Layout.fillWidth: true; prefs: win.prefs; label: "Widgets"; trailing: "›"; onActivated: win.openWidgets() }
                        MenuRow { Layout.fillWidth: true; prefs: win.prefs; label: "System Tray"; trailing: "›"; onActivated: win.openTray() }
                        MenuRow { Layout.fillWidth: true; prefs: win.prefs; label: "Notifications"; trailing: "›"; onActivated: win.openNotifications() }
                    }
                    ColumnLayout {
                        visible: win.section==="About"; Layout.fillWidth: true; spacing: 10
                        Text { text: "Oziro"; color: win.prefs.foreground; font.pixelSize: 32; font.weight: Font.DemiBold }
                        Text { text: "Desktop Environment 0.9.22"; color: win.prefs.foreground; font.pixelSize: 16 }
                        Text { Layout.fillWidth: true; wrapMode: Text.WordWrap; text: win.prefs.loginSession ? "Independent experimental login" : win.prefs.nestedPreview ? "Development preview" : "Existing desktop session"; color: win.prefs.muted }
                        Text { text: "Wayland · Niri · Quickshell"; color: win.prefs.muted }
                    }
                }
            }
            Text { Layout.fillWidth: true; text: win.prefs.settingsStatus; color: win.prefs.muted; font.pixelSize: 11 }
        }
    }
}
