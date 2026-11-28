import QtQuick
import Quickshell
import Quickshell.Wayland

// Independent non-interactive layer surface. Coordinates use the actual host window,
// not a Qt Controls tooltip confined to a 32px bar.
PanelWindow {
    id: tip
    required property var prefs
    required property Item targetItem
    required property var hostWindow
    required property string label
    property bool above: false
    property int hostEdgeMargin: 0
    readonly property real centerX: {
        if (!hostWindow || !hostWindow.screen) return 0;
        const transform = hostWindow.windowTransform;
        const p=hostWindow.mapFromItem(targetItem,targetItem.width/2,0);
        return (hostWindow.screen.width-hostWindow.width)/2+p.x;
    }
    screen: hostWindow ? hostWindow.screen : null
    // Loader controls lifetime; the target screen is resolved from the host, not our own visibility-dependent screen.
    visible: hostWindow !== null && hostWindow !== undefined && !!hostWindow.screen
    anchors { top: !tip.above; bottom: tip.above; left: true }
    margins {
        left: Math.round(Math.max(4, Math.min(tip.centerX-tip.implicitWidth/2, (tip.screen ? tip.screen.width : 300)-tip.implicitWidth-4)))
        top: !tip.above && tip.hostWindow ? tip.hostWindow.height+tip.hostEdgeMargin+5 : 0
        bottom: tip.above && tip.hostWindow ? tip.hostWindow.height+tip.hostEdgeMargin+5 : 0
    }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.namespace: "oziro-tooltip"
    mask: Region {}
    color: "transparent"
    implicitWidth: Math.min(260, Math.ceil(metrics.advanceWidth)+20)
    implicitHeight: 28
    TextMetrics { id: metrics; text: tip.label; font.pixelSize: 12 }
    Rectangle {
        anchors.fill: parent
        radius: 6
        color: tip.prefs.popupColor
        border.color: tip.prefs.outline
        Text {
            anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 10
            text: tip.label; textFormat: Text.PlainText
            color: tip.prefs.foreground; font.pixelSize: 12
            verticalAlignment: Text.AlignVCenter; horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
        }
    }
}
