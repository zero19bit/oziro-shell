import QtQuick
import QtQuick.Layouts
import Quickshell

PanelWindow {
    id: dock
    required property var prefs
    required property var niriBackend
    signal openLauncher()
    readonly property var pinned: prefs.pinnedApps
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
    anchors { top: dock.prefs.layoutMode === "bottom"; bottom: dock.prefs.layoutMode !== "bottom" }
    margins { top: 8; bottom: 8 }
    implicitWidth: Math.min(screen ? Math.max(80,screen.width-32) : 640, items.implicitWidth + 20)
    implicitHeight: dock.prefs.dockIconSize + 16
    color: "transparent"
    Rectangle {
        anchors.fill: parent
        radius: dock.prefs.theme === "minimal" ? 6 : 19
        color: dock.prefs.surfaceColor
        border.color: dock.prefs.outline
        Flickable {
            anchors.fill: parent
            anchors.margins: 8
            contentWidth: items.implicitWidth
            contentHeight: height
            clip: true
            Row {
                id: items
                height: parent.height
                spacing: 7
                PanelChip {
                    anchors.verticalCenter: parent.verticalCenter
                    prefs: dock.prefs
                    label: "Apps"
                    kind: "brand"
                    onActivated: dock.openLauncher()
                }
                Repeater {
                    model: dock.pinned
                    delegate: DockIcon {
                        required property string modelData
                        prefs: dock.prefs
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
}
