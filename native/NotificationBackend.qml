import QtQuick
import Quickshell
import Quickshell.Services.Notifications

Scope {
    id: backend
    readonly property var entries: server.trackedNotifications.values
    readonly property int count: entries.filter(n => !n.transient).length
    property int latestId: -1
    readonly property var latest: entries.find(n => n.id === latestId) || null
    function hideToast() {
        const old = latest;
        latestId = -1;
        if (old && old.transient) old.expire();
    }
    function clear() {
        const copy = entries.slice();
        latestId = -1;
        for (const n of copy) n.dismiss();
    }
    NotificationServer {
        id: server
        keepOnReload: false
        persistenceSupported: true
        bodySupported: true
        bodyMarkupSupported: false
        actionsSupported: false
        imageSupported: false
        onNotification: n => {
            backend.hideToast();
            const old = backend.entries.slice();
            while (old.length >= 40) old.shift().expire();
            n.tracked = true;
            backend.latestId = n.id;
            toastTimeout.restart();
        }
    }
    Timer {
        id: toastTimeout
        interval: 5000
        repeat: false
        onTriggered: backend.hideToast()
    }
}
