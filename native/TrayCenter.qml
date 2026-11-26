import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.SystemTray

// Explicit opening opts into Quickshell's StatusNotifier tracking.
ShellPopup {
    id: win
    signal openControls()
    readonly property var entries: SystemTray.items.values
    implicitWidth: Math.min(480, popupParent && popupParent.screen ? Math.max(1,popupParent.screen.width-24) : 480)
    implicitHeight: Math.min(560, popupParent && popupParent.screen ? Math.max(1,popupParent.screen.height-win.prefs.popupMargin-36) : 560)
    Rectangle {
        focus: true
        Keys.onEscapePressed: { if (!win.dismissBlocked) win.dismiss(); }
        anchors.fill: parent; radius: 20; color: win.prefs.popupColor; border.color: win.prefs.outline
        ColumnLayout {
            anchors.fill: parent; anchors.margins: 16; spacing: 12
            RowLayout {
                Text { Layout.fillWidth: true; text: "System Tray"; color: win.prefs.foreground; font.pixelSize: 20; font.bold: true }
                Chip { prefs: win.prefs; label: "Back"; onActivated: win.openControls() }
                Chip { prefs: win.prefs; label: "Close"; onActivated: win.dismiss() }
            }
            SectionLabel { prefs: win.prefs; label: "BACKGROUND APPLICATIONS" }
            Text { Layout.fillWidth: true; wrapMode: Text.WordWrap; text: win.entries.length + " registered items"; color: win.prefs.muted; font.pixelSize: 12 }
            Text {
                visible: win.entries.length === 0
                Layout.fillWidth: true; wrapMode: Text.WordWrap
                text: "No compatible tray items have registered yet. Start an application that supports StatusNotifier / AppIndicator, then check again."
                color: win.prefs.muted
            }
            ListView {
                id: list
                Layout.fillWidth: true; Layout.fillHeight: true
                clip: true; spacing: 7; cacheBuffer: 0
                model: SystemTray.items
                ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
                delegate: Rectangle {
                    id: tile
                    required property var modelData
                    width: Math.max(1,list.width-12)
                    height: 66
                    radius: 12; color: win.prefs.cardColor; border.color: win.prefs.outline
                    RowLayout {
                        anchors.fill: parent; anchors.margins: 10; spacing: 10
                        Image {
                            id: appIcon
                            Layout.preferredWidth: 30; Layout.preferredHeight: 30
                            source: tile.modelData.icon || Quickshell.iconPath("application-x-executable")
                            sourceSize.width: 32; sourceSize.height: 32
                            fillMode: Image.PreserveAspectFit; cache: false
                        }
                        ColumnLayout {
                            Layout.fillWidth: true; spacing: 3
                            Text { Layout.fillWidth: true; text: tile.modelData.title || tile.modelData.id || "Application"; textFormat: Text.PlainText; elide: Text.ElideRight; font.bold: true; color: win.prefs.foreground }
                            Text { Layout.fillWidth: true; text: tile.modelData.tooltipTitle || (tile.modelData.onlyMenu ? "Menu only" : "Background application"); textFormat: Text.PlainText; elide: Text.ElideRight; font.pixelSize: 11; color: win.prefs.muted }
                        }
                        Chip {
                            prefs: win.prefs
                            label: "Open"
                            enabled: !tile.modelData.onlyMenu
                            onActivated: tile.modelData.activate()
                        }
                        Chip {
                            id: menuButton
                            prefs: win.prefs; label: "Menu"
                            enabled: tile.modelData.hasMenu
                            onActivated: {
                                const point = menuButton.mapToItem(win.contentItem,0,menuButton.height);
                                tile.modelData.display(win,Math.round(point.x),Math.round(point.y));
                            }
                        }
                    }
                }
            }
            Text { Layout.fillWidth: true; wrapMode: Text.WordWrap; text: "Open and Menu are supplied by each app. Legacy XEmbed tray icons are not supported. Existing Ryoku services remain untouched."; color: win.prefs.muted; font.pixelSize: 11 }
        }
    }
}
