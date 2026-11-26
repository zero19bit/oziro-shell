import QtQuick
import Quickshell

FocusScope {
    id: icon
    required property var prefs
    required property string title
    required property string iconName
    property bool running: false
    property bool selected: false
    signal activated()
    width: icon.prefs.dockIconSize; height: icon.prefs.dockIconSize
    activeFocusOnTab: enabled
    Keys.onReturnPressed: { if (enabled) activated(); }
    Keys.onSpacePressed: { if (enabled) activated(); }
    Accessible.role: Accessible.Button
    Accessible.name: title
    Accessible.onPressAction: { if (enabled) activated(); }
    Rectangle {
        anchors.fill: parent
        radius: icon.prefs.theme === "minimal" ? 5 : 12
        color: icon.selected || mouse.containsMouse || icon.activeFocus ? icon.prefs.outline : "transparent"
        border.width: icon.activeFocus ? 2 : 0
        border.color: icon.prefs.accent
        Behavior on color { enabled: !icon.prefs.eco; ColorAnimation { duration: 100 } }
    }
    Image {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: -2
        width: Math.round(icon.width * 0.82); height: width
        source: Quickshell.iconPath(icon.iconName || "application-x-executable","application-x-executable")
        sourceSize.width: width; sourceSize.height: height
        fillMode: Image.PreserveAspectFit
    }
    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 2
        visible: icon.running
        width: 4
        height: 4; radius: 2; color: icon.selected ? icon.prefs.foreground : icon.prefs.muted
    }
    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: { if (icon.enabled) icon.activated(); }
    }
}
