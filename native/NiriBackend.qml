import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: backend
    readonly property string socketPath: Quickshell.env("NIRI_SOCKET") || ""
    readonly property bool enabled: socketPath.length > 0
    property bool ready: false
    property var workspaces: []
    property string lastError: ""
    property var targetId: null

    function consume(line) {
        try {
            const event = JSON.parse(line);
            if (event.WorkspacesChanged && Array.isArray(event.WorkspacesChanged.workspaces)) {
                workspaces = event.WorkspacesChanged.workspaces;
                ready = true;
            } else if (event.WorkspaceActivated && ready) {
                const activation = event.WorkspaceActivated;
                const target = workspaces.find(w => w.id === activation.id);
                if (!target) return;
                workspaces = workspaces.map(w => Object.assign({}, w, {
                    is_active: w.output === target.output ? w.id === target.id : w.is_active,
                    is_focused: activation.focused ? w.id === target.id : w.is_focused
                }));
            }
        } catch (e) { console.warn("Oziro Niri event parse:", e); }
    }

    function activate(id) {
        if (!ready || targetId !== null || !Number.isSafeInteger(id) ||
                !workspaces.some(w => w.id === id)) return;
        targetId = id;
        lastError = "";
        actionSocket.connected = true;
        actionTimeout.restart();
    }

    function finishAction(error) {
        actionTimeout.stop();
        if (error) { lastError = error; console.warn("Oziro Niri action:", error); }
        actionSocket.connected = false;
        targetId = null;
    }

    Socket {
        id: events
        path: backend.socketPath
        onConnectedChanged: {
            if (connected) {
                retry.stop();
                write(JSON.stringify("EventStream") + "\n");
                flush();
            } else {
                backend.ready = false;
                backend.workspaces = [];
                if (backend.enabled) retry.restart();
            }
        }
        onError: {
            backend.ready = false;
            backend.workspaces = [];
            connected = false;
            if (backend.enabled) retry.restart();
        }
        parser: SplitParser { onRead: data => backend.consume(data) }
    }
    Timer {
        id: retry
        interval: 3000
        repeat: false
        onTriggered: { if (backend.enabled && !events.connected) events.connected = true; }
    }
    Component.onCompleted: { if (enabled) events.connected = true; }

    Socket {
        id: actionSocket
        path: backend.socketPath
        onConnectedChanged: {
            if (connected && backend.targetId !== null) {
                write(JSON.stringify({Action:{FocusWorkspace:{reference:{Id:backend.targetId}}}}) + "\n");
                flush();
            }
        }
        onError: backend.finishAction("IPC connection failed")
        parser: SplitParser {
            onRead: data => {
                try {
                    const response = JSON.parse(data);
                    backend.finishAction(response.Err ? String(response.Err) : "");
                } catch (e) { backend.finishAction("Invalid reply"); }
            }
        }
    }
    Timer {
        id: actionTimeout
        interval: 3000
        onTriggered: backend.finishAction("IPC timeout")
    }
}
