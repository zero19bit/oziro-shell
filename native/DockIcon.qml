import QtQuick
import QtQuick.Controls
import Quickshell

FocusScope {
    id: icon
    required property var prefs
    required property string title
    required property string iconName
    property url customSource: ""
    property bool running: false
    property bool selected: false
    property bool inverted: false
    property real waveFactor: 0
    readonly property bool animated: prefs.dockMagnification && !prefs.eco
    signal activated()
    width: prefs.dockIconSize; height: prefs.dockIconSize
    activeFocusOnTab: enabled
    z: waveFactor
    Keys.onReturnPressed: { if (enabled) activated(); }
    Keys.onSpacePressed: { if (enabled) activated(); }
    Accessible.role: Accessible.Button
    Accessible.name: title
    Accessible.onPressAction: { if (enabled) activated(); }
    property bool tipReady: false
    readonly property bool wantsTip: mouse.containsMouse && enabled && icon.prefs.openMenuCount === 0
    onWantsTipChanged: {
        tipReady = false;
        if (wantsTip) tipDelay.restart(); else tipDelay.stop();
    }
    Timer { id: tipDelay; interval: 450; repeat: false; onTriggered: icon.tipReady = icon.wantsTip }
    Loader {
        active: icon.tipReady && icon.wantsTip
        sourceComponent: OziroTooltip { prefs: icon.prefs; targetItem: icon; label: icon.title; above: !icon.inverted }
    }
    Rectangle {
        anchors.fill: parent; radius: 10
        color: icon.activeFocus ? icon.prefs.hoverColor : "transparent"
        border.width: icon.activeFocus ? 1 : 0; border.color: icon.prefs.accent
    }
    Image {
        id: artwork
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: (icon.inverted ? 1 : -1) * (2 + icon.waveFactor * 10)
        width: Math.round(icon.width*0.80); height: width
        source: String(icon.customSource) !== "" ? icon.customSource : Quickshell.iconPath(icon.iconName || "application-x-executable","application-x-executable")
        sourceSize.width: Math.ceil(width*1.4); sourceSize.height: sourceSize.width
        fillMode: Image.PreserveAspectFit
        smooth: true
        scale: 1 + icon.waveFactor*0.38
        Behavior on scale { enabled: icon.animated; NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
        Behavior on anchors.verticalCenterOffset { enabled: icon.animated; NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
    }
    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: icon.inverted ? undefined : parent.bottom
        anchors.top: icon.inverted ? parent.top : undefined
        anchors.margins: 1
        visible: icon.running
        width: icon.selected ? 10 : 4; height: 4; radius: 2
        color: icon.selected ? icon.prefs.foreground : icon.prefs.muted
        Behavior on width { enabled: icon.animated; NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
    }
    MouseArea {
        id: mouse; anchors.fill: parent; hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: { if (icon.enabled) icon.activated(); }
    }
}
