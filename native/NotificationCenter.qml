import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland

ShellPopup {
    id: win
    readonly property var backend: prefs.notificationBackend
    menuWidth: Math.min(430, screen ? Math.max(1,screen.width-24) : 430)
    menuHeight: Math.min(550, screen ? Math.max(1,screen.height-140) : 550)
    Rectangle {
        focus: true
        Keys.onEscapePressed: { if (!win.dismissBlocked) win.dismiss(); }
        x: win.bodyX; y: win.bodyY; width: win.bodyWidth; height: win.bodyHeight
        radius: 20
        color: win.prefs.popupColor
        border.color: win.prefs.outline
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 10
            RowLayout {
                Text { text: "Notifications"; font.pixelSize: 20; font.bold: true; color: win.prefs.foreground; Layout.fillWidth: true }
                Chip { prefs: win.prefs; label: "Close"; onActivated: win.dismiss() }
            }
            Text {
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                color: win.prefs.muted
                text: !win.backend ? "Notifications unavailable in this session. Oziro does not read another notification daemon's history." :
                    win.backend.count + " stored this session · maximum 40 · no disk history"
            }
            RowLayout {
                visible: win.backend !== null
                Layout.fillWidth: true
                Chip { prefs: win.prefs; label: "Do not disturb"; selected: win.prefs.quietNotifications; onActivated: win.prefs.quietNotifications = !win.prefs.quietNotifications }
                Item { Layout.fillWidth: true }
                Chip { prefs: win.prefs; label: "Clear all"; enabled: win.backend !== null && win.backend.count > 0; onActivated: win.backend.clear() }
            }
            ListView {
                id: list
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: 8
                model: win.backend ? win.backend.entries.filter(n => !n.transient).slice().reverse() : []
                delegate: Rectangle {
                    id: card
                    required property var modelData
                    width: list.width
                    height: contents.implicitHeight + 22
                    radius: 12
                    color: win.prefs.outline
                    ColumnLayout {
                        id: contents
                        x: 11; y: 11; width: parent.width-22
                        spacing: 5
                        RowLayout {
                            Text { Layout.fillWidth: true; text: card.modelData.appName.slice(0,100); textFormat: Text.PlainText; elide: Text.ElideRight; color: win.prefs.accent; font.pixelSize: 12 }
                            Chip { prefs: win.prefs; label: "×"; Accessible.name: "Dismiss notification"; onActivated: card.modelData.dismiss() }
                        }
                        Text { Layout.fillWidth: true; text: card.modelData.summary.slice(0,250); textFormat: Text.PlainText; wrapMode: Text.Wrap; font.bold: true; color: win.prefs.foreground; maximumLineCount: 3; elide: Text.ElideRight }
                        Text { Layout.fillWidth: true; text: card.modelData.body.slice(0,1000); textFormat: Text.PlainText; wrapMode: Text.Wrap; color: win.prefs.foreground; maximumLineCount: 5; elide: Text.ElideRight }
                    }
                }
                Text {
                    anchors.centerIn: parent
                    visible: win.backend !== null && list.count === 0
                    text: "You're all caught up"
                    color: win.prefs.muted
                }
            }
        }
    }
}
