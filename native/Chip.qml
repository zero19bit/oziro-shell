import QtQuick
import QtQuick.Controls

AbstractButton {
    id: chip
    required property var prefs
    property string label: ""
    property bool selected: false
    signal activated()
    onClicked: activated()
    implicitWidth: Math.max(32, caption.implicitWidth + 20)
    implicitHeight: 32
    Accessible.name: label
    background: Rectangle {
        radius: chip.prefs.theme === "minimal" ? 4 : 10
        color: chip.selected ? chip.prefs.accent : chip.hovered || chip.activeFocus ? chip.prefs.outline : "transparent"
        border.color: chip.selected || chip.activeFocus ? chip.prefs.accent : chip.prefs.outline
        border.width: chip.activeFocus ? 2 : 1
        Behavior on color { enabled: !chip.prefs.eco; ColorAnimation { duration: 120 } }
    }
    contentItem: Text {
        id: caption
        text: chip.label
        textFormat: Text.PlainText
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        color: !chip.enabled ? chip.prefs.muted : chip.selected ? chip.prefs.selectedText : chip.prefs.foreground
        font.pixelSize: 12
        font.weight: Font.Medium
        opacity: chip.enabled ? 1 : 0.65
    }
}
