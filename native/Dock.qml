import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "DockMotion.js" as Motion

PanelWindow {
    id: dock
    required property var prefs
    required property var niriBackend
    signal openLauncher()
    signal openSettings()
    readonly property var pinned: prefs.pinnedApps
    readonly property bool topDock: prefs.layoutMode === "bottom"
    readonly property bool motionEnabled: prefs.dockMagnification && !prefs.eco
    readonly property real pitch: prefs.dockIconSize + 8
    readonly property int shelfHeight: prefs.dockIconSize + 16
    readonly property int headroom: motionEnabled ? 44 : 28
    readonly property bool waveActive: motionEnabled && pointer.hovered && !viewport.dragging
    readonly property real pointerX: pointer.point.position.x + viewport.contentX - items.x
    function wave(center) { return Motion.factor(center-pointerX,pitch,waveActive); }
    // Windows are scoped to this output, except pinned apps which are shared.
    readonly property var localWindows: niriBackend.enabled && niriBackend.ready && screen
        ? niriBackend.windows.filter(w => niriBackend.workspaces.some(ws => ws.id === w.workspace_id && ws.output === screen.name))
        : []
    function entryFor(w) {
        return w.app_id ? DesktopEntries.heuristicLookup(w.app_id) : null;
    }
    readonly property var running: localWindows.filter(w => {
        const e = entryFor(w);
        return !e || !pinned.includes(e.id);
    }).sort((a,b) => a.id-b.id)
    // A primitive key changes only when the ordered membership changes.
    // Focus and title updates change delegate bindings, not the Repeater model.
    readonly property string runningKey: running.map(w => String(w.id)).join(",")
    readonly property var runningIds: runningKey ? runningKey.split(",") : []
    function windowById(id) {
        return localWindows.find(w => String(w.id) === id) || null;
    }
    anchors { top: dock.topDock; bottom: !dock.topDock }
    margins { top: 8; bottom: 8 }
    implicitWidth: Math.min(screen ? Math.max(80,screen.width-32) : 640, items.implicitWidth + 24)
    implicitHeight: dock.shelfHeight + dock.headroom
    exclusiveZone: dock.shelfHeight
    WlrLayershell.namespace: "oziro-dock"
    mask: Region { item: shelf }
    color: "transparent"
    Rectangle {
        id: shelf
        anchors.left: parent.left; anchors.right: parent.right
        anchors.top: dock.topDock ? parent.top : undefined
        anchors.bottom: dock.topDock ? undefined : parent.bottom
        height: dock.shelfHeight
        radius: dock.prefs.theme === "minimal" ? 9 : 20
        color: Qt.rgba(dock.prefs.popupColor.r,dock.prefs.popupColor.g,dock.prefs.popupColor.b,dock.prefs.eco ? 1 : 0.82)
        border.color: dock.prefs.outline
        Rectangle {
            anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
            anchors.leftMargin: 20; anchors.rightMargin: 20; anchors.topMargin: 1
            height: 1; color: Qt.rgba(dock.prefs.foreground.r,dock.prefs.foreground.g,dock.prefs.foreground.b,0.13)
        }
    }
    Flickable {
        id: viewport
        anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 12
        contentWidth: items.implicitWidth; contentHeight: height
        flickableDirection: Flickable.HorizontalFlick
        boundsBehavior: Flickable.StopAtBounds
        interactive: contentWidth > width
        clip: true
        HoverHandler {
            id: pointer
            parent: viewport
            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad | PointerDevice.Stylus
            blocking: false
        }
        // Do not depend on Flickable's kinetic state for wheel/trackpad input.
        function scrollBy(delta) {
            if (delta === 0) return;
            cancelFlick();
            contentX = Motion.scrollOffset(contentX, delta, contentWidth, width);
        }
        WheelHandler {
            parent: viewport
            target: null
            orientation: Qt.Horizontal
            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
            enabled: viewport.interactive
            onWheel: event => {
                viewport.scrollBy(event.pixelDelta.x !== 0 ? event.pixelDelta.x : event.angleDelta.x / 120 * dock.pitch);
                event.accepted = true;
            }
        }
        WheelHandler {
            parent: viewport
            target: null
            orientation: Qt.Vertical
            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
            enabled: viewport.interactive
            onWheel: event => {
                // A diagonal event is handled by the horizontal handler only.
                if (event.pixelDelta.x !== 0 || event.angleDelta.x !== 0) { event.accepted = false; return; }
                viewport.scrollBy(event.pixelDelta.y !== 0 ? event.pixelDelta.y : event.angleDelta.y / 120 * dock.pitch);
                event.accepted = true;
            }
        }
        Row {
            id: items
            y: dock.topDock ? 8 : dock.headroom+8
            height: dock.prefs.dockIconSize
            spacing: 8
            DockIcon {
                prefs: dock.prefs; title: "Applications"; iconName: ""
                customSource: Qt.resolvedUrl("dock-apps.svg")
                waveFactor: dock.wave(x+width/2); inverted: dock.topDock
                onActivated: dock.openLauncher()
            }
            DockIcon {
                prefs: dock.prefs; title: "System Settings"; iconName: ""
                customSource: Qt.resolvedUrl("dock-settings.svg")
                waveFactor: dock.wave(x+width/2); inverted: dock.topDock
                onActivated: dock.openSettings()
            }
            Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 1; height: 26; color: dock.prefs.outline; visible: dock.pinned.length+dock.running.length>0 }
                Repeater {
                    model: dock.pinned
                    delegate: DockIcon {
                        required property string modelData
                        prefs: dock.prefs
                        waveFactor: dock.wave(x+width/2); inverted: dock.topDock
                        readonly property var entry: DesktopEntries.byId(modelData)
                        readonly property var matches: dock.localWindows.filter(w => {
                            const e = dock.entryFor(w);
                            return e && e.id === modelData;
                        })
                        title: entry ? entry.name : modelData
                        iconName: entry ? entry.icon : "application-x-executable"
                        running: matches.length > 0
                        selected: matches.some(w => w.is_focused)
                        onActivated: {
                            if (matches.length) {
                                let index = matches.findIndex(w => w.is_focused);
                                dock.niriBackend.focusWindow(matches[(index+1)%matches.length].id);
                            } else if (entry && !entry.runInTerminal) entry.execute();
                        }
                    }
                }
                Rectangle {
                    visible: dock.running.length > 0 && dock.pinned.length > 0
                    anchors.verticalCenter: parent.verticalCenter
                    width: 1; height: 30; color: dock.prefs.outline
                }
                Repeater {
                    model: dock.runningIds
                    delegate: DockIcon {
                        required property string modelData
                        prefs: dock.prefs
                        waveFactor: dock.wave(x+width/2); inverted: dock.topDock
                        readonly property var windowData: dock.windowById(modelData)
                        readonly property var entry: windowData ? dock.entryFor(windowData) : null
                        title: windowData ? windowData.title || windowData.app_id || "Window" : "Window"
                        iconName: entry ? entry.icon : "application-x-executable"
                        running: windowData !== null
                        selected: windowData !== null && windowData.is_focused
                        onActivated: { if (windowData) dock.niriBackend.focusWindow(windowData.id); }
                    }
                }
        }
    }
}
