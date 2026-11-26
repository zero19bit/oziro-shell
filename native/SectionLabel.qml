import QtQuick
import QtQuick.Layouts

RowLayout {
    id: section
    required property var prefs
    property string label: ""
    Layout.fillWidth: true
    spacing: 10
    Text {
        text: section.label
        textFormat: Text.PlainText
        color: section.prefs.muted
        font.pixelSize: 11
        font.weight: Font.DemiBold
        font.letterSpacing: 0.8
    }
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 1
        color: section.prefs.outline
    }
}
