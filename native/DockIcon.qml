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
    // Checked lookup returns an empty URL instead of Quickshell's missing texture.
    readonly property url fallbackSource: Qt.resolvedUrl("dock-apps.svg")
    readonly property string checkedIcon: iconName ? Quickshell.iconPath(iconName, true) : ""
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
    readonly property bool wantsTip: hover.hovered && enabled && icon.prefs.openMenuCount === 0
    onWantsTipChanged: {
        tipReady = false;
        if (wantsTip) tipDelay.restart(); else tipDelay.stop();
    }
    Timer { id: tipDelay; interval: 450; repeat: false; onTriggered: icon.tipReady = icon.wantsTip }
    Loader {
        active: icon.tipReady && icon.wantsTip
        sourceComponent: OziroTooltip { prefs: icon.prefs; targetItem: icon; hostWindow: icon.QsWindow.window; label: icon.title; above: !icon.inverted; hostEdgeMargin: 8 }
    }
    Rectangle {
        anchors.fill: parent; radius: 10
        color: icon.activeFocus ? icon.prefs.hoverColor : "transparent"
        border.width: icon.activeFocus ? 1 : 0; border.color: icon.prefs.accent
    }
    Item {
        id: artwork
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: (icon.inverted ? 1 : -1) * (2 + icon.waveFactor * 10)
        width: Math.round(icon.width*0.80); height: width
        Image {
            id: primary
            anchors.fill: parent
            source: String(icon.customSource) !== "" ? icon.customSource : icon.checkedIcon
            sourceSize.width: Math.ceil(width*1.4); sourceSize.height: sourceSize.width
            fillMode: Image.PreserveAspectFit
            smooth: true
            visible: status === Image.Ready
        }
        // Local artwork cannot depend on an installed icon theme.
        Image {
            anchors.fill: parent
            source: primary.status === Image.Ready ? "" : icon.fallbackSource
            sourceSize.width: Math.ceil(width*1.4); sourceSize.height: sourceSize.width
            fillMode: Image.PreserveAspectFit
            smooth: true
            visible: primary.status !== Image.Ready
        }
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
    HoverHandler {
        id: hover
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad | PointerDevice.Stylus
        blocking: false
        cursorShape: Qt.PointingHandCursor
    }
    TapHandler {
        enabled: icon.enabled
        gesturePolicy: TapHandler.DragThreshold
        acceptedButtons: Qt.LeftButton
        onTapped: icon.activated()
    }
}
