import QtQuick

FocusScope {
    id: chip
    required property var prefs
    property string label: ""
    property bool selected: false
    signal activated()
    implicitWidth: Math.max(32, caption.implicitWidth + 20)
    implicitHeight: 32
    activeFocusOnTab: enabled
    Accessible.role: Accessible.Button
    Accessible.name: label
    Accessible.onPressAction: { if (enabled) activated(); }
    Keys.onReturnPressed: { if (enabled) activated(); }
    Keys.onSpacePressed: { if (enabled) activated(); }
    Rectangle {
        anchors.fill: parent
        radius: chip.prefs.theme === "minimal" ? 4 : 10
        color: chip.selected ? chip.prefs.accent : mouse.containsMouse || chip.activeFocus ? chip.prefs.outline : "transparent"
        border.color: chip.selected ? chip.prefs.accent : chip.prefs.outline
        Behavior on color { enabled: !chip.prefs.eco; ColorAnimation { duration: 120 } }
    }
    Text {
        id: caption
        anchors.centerIn: parent
        text: chip.label
        color: !chip.enabled ? chip.prefs.muted : chip.selected ? chip.prefs.selectedText : chip.prefs.foreground
        font.pixelSize: 12
        font.weight: Font.Medium
        opacity: chip.enabled ? 1 : 0.65
    }
    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: chip.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: { if (chip.enabled) chip.activated(); }
    }
}
