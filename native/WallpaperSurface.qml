import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: win
    required property var prefs
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: win.prefs.wallpaper.layer === "bottom" ? WlrLayer.Bottom : WlrLayer.Background
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.namespace: "oziro-wallpaper"
    mask: Region {}
    color: win.prefs.wallpaper.color
    Image {
        anchors.fill: parent
        visible: status === Image.Ready
        source: win.prefs.wallpaperUrl
        asynchronous: true
        cache: false
        sourceSize.width: 1920
        sourceSize.height: 1080
        fillMode: win.prefs.wallpaper.fit === "contain" ? Image.PreserveAspectFit : Image.PreserveAspectCrop
        onStatusChanged: if (status === Image.Error) console.warn("Oziro wallpaper: local image could not be loaded; using solid color")
    }
}
