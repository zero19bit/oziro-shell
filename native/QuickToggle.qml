import QtQuick
import QtQuick.Controls

AbstractButton {
    id: tile
    required property var prefs
    property string label: ""
    property string detail: ""
    property bool selected: false
    signal activated()
    implicitWidth: 140
    implicitHeight: 58
    Accessible.name: label + ", " + detail
    onClicked: activated()
    background: Rectangle {
        radius: 12
        color: tile.selected ? tile.prefs.accent : tile.hovered ? tile.prefs.hoverColor : tile.prefs.cardColor
        border.color: tile.activeFocus ? tile.prefs.accent : tile.prefs.outline
        border.width: tile.activeFocus ? 2 : 1
        opacity: tile.enabled ? 1 : 0.65
    }
    contentItem: Item {
        Column {
            anchors.left: parent.left
            anchors.leftMargin: 8
            anchors.right: statusDot.left
            anchors.rightMargin: 6
            anchors.verticalCenter: parent.verticalCenter
            spacing: 3
            Text { width: parent.width; text: tile.label; textFormat: Text.PlainText; elide: Text.ElideRight; color: tile.selected ? tile.prefs.selectedText : tile.prefs.foreground; font.pixelSize: 13; font.bold: true }
            Text { width: parent.width; text: tile.detail; textFormat: Text.PlainText; elide: Text.ElideRight; color: tile.selected ? tile.prefs.selectedText : tile.prefs.muted; font.pixelSize: 11 }
        }
        Rectangle {
            id: statusDot
            anchors.right: parent.right
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            width: 8; height: 8; radius: 4
            color: tile.selected ? tile.prefs.selectedText : tile.prefs.muted
        }
    }
}
