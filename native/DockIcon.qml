import QtQuick
import Quickshell

Item {
    id: icon
    required property var prefs
    required property string title
    required property string iconName
    property bool running: false
    property bool selected: false
    signal activated()
    width: icon.prefs.dockIconSize; height: icon.prefs.dockIconSize
    Accessible.role: Accessible.Button
    Accessible.name: title
    Accessible.onPressAction: activated()
    Rectangle {
        anchors.fill: parent
        radius: icon.prefs.theme === "minimal" ? 5 : 12
        color: icon.selected || mouse.containsMouse ? icon.prefs.outline : "transparent"
        Behavior on color { enabled: !icon.prefs.eco; ColorAnimation { duration: 100 } }
    }
    Image {
        anchors.centerIn: parent
        width: Math.round(icon.width * 0.65); height: width
        source: Quickshell.iconPath(icon.iconName || "application-x-executable","application-x-executable")
        sourceSize.width: width; sourceSize.height: height
        fillMode: Image.PreserveAspectFit
    }
    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 2
        visible: icon.running
        width: icon.selected ? 14 : 5
        height: 3; radius: 2; color: icon.prefs.accent
    }
    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: icon.activated()
    }
}
