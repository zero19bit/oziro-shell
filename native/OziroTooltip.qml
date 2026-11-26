import QtQuick
import Quickshell

PopupWindow {
    id: tip
    required property var prefs
    required property Item targetItem
    required property string label
    property bool above: false
    grabFocus: false
    visible: true
    color: "transparent"
    mask: Region {}
    implicitWidth: Math.min(260, Math.ceil(metrics.advanceWidth)+20)
    implicitHeight: 28
    TextMetrics { id: metrics; text: tip.label; font.pixelSize: 12 }
    anchor.item: targetItem
    anchor.rect.x: Math.round((targetItem.width-implicitWidth)/2)
    anchor.rect.y: above ? -8 : targetItem.height+6
    anchor.gravity: (above ? Edges.Top : Edges.Bottom) | Edges.Right
    anchor.adjustment: PopupAdjustment.Slide | PopupAdjustment.FlipY
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
