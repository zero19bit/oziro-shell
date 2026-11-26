import QtQuick
import Quickshell

PopupWindow {
    id: popup
    required property var prefs
    required property var popupParent
    property string alignment: "right"
    property bool dismissBlocked: false
    signal dismiss()
    color: "transparent"
    grabFocus: true
    visible: true
    anchor.window: popupParent
    anchor.rect.x: !popupParent ? 0 : alignment === "left" ? 10 : alignment === "center" ? Math.max(0,Math.round((popupParent.width-implicitWidth)/2)) : Math.max(0,popupParent.width-implicitWidth-10)
    anchor.rect.y: !popupParent ? 0 : prefs.layoutMode === "bottom" ? -5 : popupParent.height+5
    anchor.gravity: (prefs.layoutMode === "bottom" ? Edges.Top : Edges.Bottom) | Edges.Right
    anchor.adjustment: PopupAdjustment.Slide | PopupAdjustment.FlipY
    onVisibleChanged: { if (!visible && !dismissBlocked) dismiss(); }
    onDismissBlockedChanged: { if (!dismissBlocked && !visible) dismiss(); }
}
