import QtQuick
import QtQuick.Controls
import Quickshell

AbstractButton {
    id: btn
    required property var prefs
    property string glyph: "controls"
    property string label: ""
    signal activated()
    onClicked: activated()
    implicitWidth: 29; implicitHeight: 26
    Accessible.name: label
    property bool tipReady: false
    readonly property bool wantsTip: hovered && enabled && btn.prefs.openMenuCount === 0
    onWantsTipChanged: {
        tipReady = false;
        if (wantsTip) tipDelay.restart(); else tipDelay.stop();
    }
    Timer { id: tipDelay; interval: 650; repeat: false; onTriggered: btn.tipReady = btn.wantsTip }
    Loader {
        active: btn.tipReady && btn.wantsTip
        sourceComponent: OziroTooltip { prefs: btn.prefs; targetItem: btn; hostWindow: btn.QsWindow.window; label: btn.label; above: btn.prefs.layoutMode === "bottom"; hostEdgeMargin: btn.prefs.layoutMode === "floating" ? 6 : 0 }
    }
    background: Rectangle {
        radius: 5
        color: btn.hovered || btn.activeFocus ? btn.prefs.hoverColor : "transparent"
        border.width: btn.activeFocus ? 1 : 0; border.color: btn.prefs.accent
    }
    contentItem: Item {
        Canvas {
            id: icon
            anchors.centerIn: parent; width: 18; height: 18
            readonly property color ink: btn.prefs.foreground
            onInkChanged: requestPaint()
            Connections { target: btn; function onGlyphChanged() { icon.requestPaint(); } }
            onPaint: {
                var c=getContext("2d"); c.clearRect(0,0,width,height); c.strokeStyle=ink; c.fillStyle=ink; c.lineWidth=1.35; c.lineCap="round"; c.lineJoin="round";
                function line(x1,y1,x2,y2) { c.beginPath(); c.moveTo(x1,y1); c.lineTo(x2,y2); c.stroke(); }
                function dot(x,y,r) { c.beginPath(); c.arc(x,y,r,0,Math.PI*2); c.fill(); }
                if (btn.glyph==="brand") {
                    c.lineWidth=2.4; c.beginPath(); c.arc(9,9,6.6,0,Math.PI*1.5); c.stroke(); line(10,2.4,15.5,2.4);line(15.5,2.4,15.5,8);line(15,3,8,10);
                } else if (btn.glyph==="network") {
                    for(var r=4;r<=12;r+=4){c.beginPath();c.arc(9,14,r,-2.34,-0.80);c.stroke();} dot(9,14,1);
                } else if (btn.glyph==="controls") {
                    line(2,5,16,5); line(2,13,16,13); dot(6,5,2.5); dot(12,13,2.5);
                } else if (btn.glyph==="widgets" || btn.glyph==="apps") {
                    for(var x=3;x<=11;x+=8) for(var y=3;y<=11;y+=8) c.strokeRect(x,y,4,4);
                } else if (btn.glyph==="bell") {
                    c.beginPath(); c.moveTo(3,13); c.lineTo(5,10); c.lineTo(5,7); c.bezierCurveTo(5,1,13,1,13,7); c.lineTo(13,10); c.lineTo(15,13); c.closePath(); c.stroke(); dot(9,15.5,1);
                } else if (btn.glyph==="settings") {
                    c.beginPath(); c.arc(9,9,5.5,0,Math.PI*2); c.stroke(); c.beginPath(); c.arc(9,9,2,0,Math.PI*2); c.stroke();
                    for(var i=0;i<8;i++){var a=i*Math.PI/4; line(9+5.5*Math.cos(a),9+5.5*Math.sin(a),9+7.5*Math.cos(a),9+7.5*Math.sin(a));}
                } else {
                    c.beginPath(); c.moveTo(2,7); c.lineTo(5,7); c.lineTo(9,3.5); c.lineTo(9,14.5); c.lineTo(5,11); c.lineTo(2,11); c.closePath(); c.stroke();
                    if(btn.glyph==="mute"){line(12,6,16,12);line(16,6,12,12);}
                    else {c.beginPath();c.arc(9,9,4, -0.9,0.9);c.stroke();c.beginPath();c.arc(9,9,7,-0.9,0.9);c.stroke();}
                }
            }
        }
    }
}
