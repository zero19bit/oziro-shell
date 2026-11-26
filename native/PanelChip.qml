import QtQuick

FocusScope {
    id: chip
    required property var prefs
    property string label: ""
    property bool selected: false
    property string kind: "action" // brand, workspace, action
    signal activated()
    implicitWidth: Math.max(kind === "workspace" ? 30 : 32, caption.implicitWidth + (kind === "workspace" ? 16 : kind === "brand" ? 26 : 20))
    implicitHeight: 26
    activeFocusOnTab: enabled
    Accessible.role: Accessible.Button
    Accessible.name: label
    Accessible.onPressAction: { if (enabled) activated(); }
    Keys.onReturnPressed: { if (enabled) activated(); }
    Keys.onSpacePressed: { if (enabled) activated(); }
    Rectangle {
        anchors.fill: parent
        radius: chip.prefs.theme === "minimal" ? 3 : chip.kind === "workspace" ? 8 : 10
        color: !chip.enabled ? "transparent" :
            chip.kind === "brand" ? (mouse.containsMouse || chip.activeFocus ? chip.prefs.hoverColor : "transparent") :
            chip.kind === "workspace" && chip.selected ? Qt.rgba(chip.prefs.accent.r,chip.prefs.accent.g,chip.prefs.accent.b,0.18) :
            mouse.pressed || mouse.containsMouse || chip.activeFocus ? chip.prefs.outline : "transparent"
        border.width: chip.activeFocus ? 2 : chip.kind === "brand" ? 0 : chip.selected || mouse.containsMouse ? 1 : 0
        border.color: chip.activeFocus || chip.selected ? chip.prefs.accent : chip.prefs.outline
        Behavior on color { enabled: !chip.prefs.eco; ColorAnimation { duration: 100 } }
    }
    Text {
        id: caption
        anchors.centerIn: parent
        text: chip.label
        textFormat: Text.PlainText
        color: !chip.enabled ? chip.prefs.muted : chip.selected ? chip.prefs.accent : chip.prefs.foreground
        font.pixelSize: 12
        font.weight: chip.kind === "brand" ? Font.Bold : chip.selected ? Font.DemiBold : Font.Medium
        font.letterSpacing: 0
        opacity: chip.enabled ? 1 : 0.65
    }
    Rectangle {
        visible: chip.kind === "workspace" && chip.selected
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 2
        width: 12
        height: 2
        radius: 1
        color: chip.prefs.accent
    }
    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: chip.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: { if (chip.enabled) chip.activated(); }
    }
}
