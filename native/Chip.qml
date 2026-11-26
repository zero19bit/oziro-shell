import QtQuick
import QtQuick.Controls

AbstractButton {
    id: chip
    property string label: ""
    property bool selected: false
    signal activated()
    onClicked: activated()
    implicitWidth: Math.max(30, caption.implicitWidth + 18)
    implicitHeight: 30
    Accessible.name: label
    background: Rectangle {
        radius: 9
        color: chip.selected ? "#a9dbfa" : chip.hovered ? "#354355" : "#222b39"
        Behavior on color { ColorAnimation { duration: 130 } }
    }
    contentItem: Text {
        id: caption
        text: chip.label
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        color: !chip.enabled ? "#8290a2" : chip.selected ? "#122433" : "#dce7f2"
        font.pixelSize: 12
        font.weight: Font.Medium
    }
}
