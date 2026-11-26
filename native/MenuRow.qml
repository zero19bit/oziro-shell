import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

AbstractButton {
    id: row
    required property var prefs
    property string label: ""
    property string trailing: ""
    property bool selected: false
    signal activated()
    onClicked: activated()
    Accessible.name: label
    implicitHeight: 33
    implicitWidth: caption.implicitWidth + 28
    background: Rectangle {
        radius: 6
        color: row.selected ? Qt.rgba(row.prefs.accent.r,row.prefs.accent.g,row.prefs.accent.b,0.20) : row.hovered || row.activeFocus ? row.prefs.hoverColor : "transparent"
        border.width: row.activeFocus ? 1 : 0
        border.color: row.prefs.accent
    }
    contentItem: RowLayout {
        spacing: 8
        Text {
            id: caption
            Layout.fillWidth: true
            text: row.label; textFormat: Text.PlainText
            color: !row.enabled ? row.prefs.muted : row.selected ? row.prefs.accent : row.prefs.foreground
            opacity: row.enabled ? 1 : 0.55
            font.pixelSize: 13; font.weight: row.selected ? Font.DemiBold : Font.Normal
            elide: Text.ElideRight
            verticalAlignment: Text.AlignVCenter
        }
        Text { visible: row.trailing!==""; text: row.trailing; color: row.prefs.muted; font.pixelSize: 14 }
    }
}
