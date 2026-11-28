import QtQuick
import QtQuick.Controls

AbstractButton {
    id: tile
    required property var prefs
    property string label: ""
    property string detail: ""
    property string glyph: ""
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
            anchors.leftMargin: tile.glyph === "" ? 8 : 43
            anchors.right: statusDot.left
            anchors.rightMargin: 6
            anchors.verticalCenter: parent.verticalCenter
            spacing: 3
            Text { width: parent.width; text: tile.label; textFormat: Text.PlainText; elide: Text.ElideRight; color: tile.selected ? tile.prefs.selectedText : tile.prefs.foreground; font.pixelSize: 13; font.bold: true }
            Text { width: parent.width; text: tile.detail; textFormat: Text.PlainText; elide: Text.ElideRight; color: tile.selected ? tile.prefs.selectedText : tile.prefs.muted; font.pixelSize: 11 }
        }
        Canvas {
            id: symbol
            visible: tile.glyph !== ""
            anchors.left: parent.left; anchors.leftMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            width: 24; height: 24
            readonly property color ink: tile.selected ? tile.prefs.selectedText : tile.prefs.foreground
            onInkChanged: requestPaint()
            onPaint: {
                var c=getContext("2d"); c.clearRect(0,0,width,height); c.strokeStyle=ink; c.fillStyle=ink; c.lineWidth=1.7; c.lineCap="round"; c.lineJoin="round";
                if (tile.glyph==="wifi") {
                    for (var r=5;r<=15;r+=5) { c.beginPath(); c.arc(12,19,r,-2.34,-0.80); c.stroke(); }
                    c.beginPath(); c.arc(12,19,1.6,0,Math.PI*2); c.fill();
                } else if (tile.glyph==="bluetooth") {
                    c.beginPath(); c.moveTo(12,2); c.lineTo(19,8); c.lineTo(5,19);
                    c.moveTo(12,2); c.lineTo(12,22); c.lineTo(19,16); c.lineTo(5,5); c.stroke();
                }
            }
        }
        Rectangle {
            id: statusDot
            anchors.right: parent.right; anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            width: 30; height: 17; radius: 9
            color: tile.selected ? tile.prefs.selectedText : tile.prefs.outline
            Rectangle {
                width: 13; height: 13; radius: 7; y: 2
                x: tile.selected ? parent.width-width-2 : 2
                color: tile.selected ? tile.prefs.accent : tile.prefs.foreground
            }
        }
    }
}
