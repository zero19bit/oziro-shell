import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: prefs
    property string theme: "glass"
    property string layoutMode: "floating"
    property bool reduceEffects: false
    property bool autoEco: true
    property bool dockEnabled: false
    property var pinnedApps: []
    property bool initialized: false
    property bool writable: true
    property string status: "Loading settings"
    readonly property string settingsPath: Quickshell.statePath("preferences.json")
    function load() {
        const text = file.text();
        if (text.trim()) {
            try {
                const data = JSON.parse(text);
                if (!data || data.version !== 1) throw new Error("Unsupported settings format");
                if (["glass","material","minimal","cyber","light"].includes(data.theme)) theme = data.theme;
                if (["floating","top","bottom"].includes(data.layoutMode)) layoutMode = data.layoutMode;
                if (typeof data.reduceEffects === "boolean") reduceEffects = data.reduceEffects;
                if (typeof data.autoEco === "boolean") autoEco = data.autoEco;
                if (typeof data.dockEnabled === "boolean") dockEnabled = data.dockEnabled;
                if (Array.isArray(data.pinnedApps)) pinnedApps = [...new Set(data.pinnedApps.filter(id =>
                    typeof id === "string" && id.length > 0 && id.length <= 256))].slice(0,12);
                status = "Settings loaded";
            } catch (error) {
                writable = false;
                status = "Invalid settings: read-only session";
                console.warn("Oziro preferences:", error);
            }
        } else if (writable) status = "Default settings";
        initialized = true;
    }
    function save() {
        if (!initialized || !writable) return;
        file.setText(JSON.stringify({
            version: 1, theme: theme, layoutMode: layoutMode,
            reduceEffects: reduceEffects, autoEco: autoEco,
            dockEnabled: dockEnabled, pinnedApps: pinnedApps
        }, null, 2) + "\n");
    }
    onThemeChanged: save()
    onLayoutModeChanged: save()
    onReduceEffectsChanged: save()
    onAutoEcoChanged: save()
    onDockEnabledChanged: save()
    onPinnedAppsChanged: save()
    FileView {
        id: file
        path: prefs.settingsPath
        blockLoading: true
        atomicWrites: true
        // The document is tiny and writes only follow explicit user actions.
        // Synchronous writes avoid dropping the last setting on immediate exit.
        blockWrites: true
        onSaved: prefs.status = "Settings saved"
        onSaveFailed: error => {
            prefs.status = "Settings save failed";
            console.warn("Oziro preferences save:", error);
        }
        onLoadFailed: error => {
            if (error !== FileViewError.FileNotFound) {
                prefs.writable = false;
                prefs.status = "Settings unreadable: read-only session";
            }
        }
    }
    Component.onCompleted: load()
}
