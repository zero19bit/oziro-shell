import QtQuick
import Quickshell
import Quickshell.Wayland

// Only exists while a menu is open. No global input capture or permanent overlay.
// An outside click is deliberately consumed; the next click reaches the desktop.
PanelWindow {
    id: popup
    required property var prefs
    property string alignment: "right"
    property bool dismissBlocked: false
    property int menuWidth: 430
    property int menuHeight: 480
    readonly property int bodyWidth: Math.max(1, Math.min(menuWidth, width-20))
    readonly property int bodyHeight: Math.max(1, Math.min(menuHeight, height-prefs.popupMargin-10))
    readonly property int bodyX: alignment==="left" ? 10 : alignment==="center" ? Math.round((width-bodyWidth)/2) : width-bodyWidth-12
    readonly property int bodyY: prefs.layoutMode==="bottom" ? height-prefs.popupMargin-bodyHeight : prefs.popupMargin
    signal dismiss()
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    WlrLayershell.namespace: "oziro-transient-menu"
    color: "transparent"
    onClosed: { if (!dismissBlocked) dismiss(); }
    MouseArea {
        anchors.fill: parent
        z: -1
        acceptedButtons: Qt.AllButtons
        onClicked: mouse => {
            if (popup.dismissBlocked) return;
            if (mouse.x < popup.bodyX || mouse.x >= popup.bodyX+popup.bodyWidth
                || mouse.y < popup.bodyY || mouse.y >= popup.bodyY+popup.bodyHeight)
                popup.dismiss();
        }
    }
}
