import QtQuick
import Quickshell

PanelWindow {
    id: toast
    property var prefs: null
    property var backend: null
    readonly property var notice: backend ? backend.latest : null
    visible: notice !== null && prefs !== null && !prefs.quietNotifications
    anchors { top: !toast.prefs || toast.prefs.layoutMode !== "bottom"; bottom: toast.prefs && toast.prefs.layoutMode === "bottom"; right: true }
    margins { top: 64; bottom: 64; right: 12 }
    exclusionMode: ExclusionMode.Ignore
    implicitWidth: Math.min(360, screen ? Math.max(1,screen.width-24) : 360)
    implicitHeight: 116
    color: "transparent"
    Rectangle {
        anchors.fill: parent
        radius: 14
        color: toast.prefs ? toast.prefs.surfaceColor : "transparent"
        border.color: toast.prefs ? toast.prefs.outline : "transparent"
        Column {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 5
            Text { width: parent.width; text: toast.notice ? toast.notice.appName.slice(0,100) : ""; textFormat: Text.PlainText; color: toast.prefs ? toast.prefs.accent : "white"; elide: Text.ElideRight; font.pixelSize: 12 }
            Text { width: parent.width; text: toast.notice ? toast.notice.summary.slice(0,250) : ""; textFormat: Text.PlainText; color: toast.prefs ? toast.prefs.foreground : "white"; elide: Text.ElideRight; font.bold: true }
            Text { width: parent.width; text: toast.notice ? toast.notice.body.slice(0,1000) : ""; textFormat: Text.PlainText; wrapMode: Text.Wrap; maximumLineCount: 2; elide: Text.ElideRight; color: toast.prefs ? toast.prefs.foreground : "white" }
        }
        MouseArea { anchors.fill: parent; onClicked: { if (toast.backend) toast.backend.hideToast(); } }
    }
}
