import QtQuick
import Quickshell
import Quickshell.Io
import "WidgetRegistry.js" as Registry

Scope {
    id: prefs
    property string theme: "glass"
    property string layoutMode: "floating"
    property bool reduceEffects: false
    property bool autoEco: true
    property string energyMode: "adaptive"
    property bool suspendDockOnBattery: false
    property bool dockEnabled: false
    property var pinnedApps: []
    property var widgetExtensions: []
    property var enabledWidgets: ["clock","battery","audio","memory"]
    property bool updatingWidgets: false
    function setWidgetConfig(extensions, enabled) {
        updatingWidgets = true;
        widgetExtensions = Registry.normalizeExtensions(extensions);
        enabledWidgets = Registry.normalizeEnabled(enabled, widgetExtensions);
        updatingWidgets = false;
        save();
    }
    property string customAccent: ""
    property int panelHeight: 48
    property int dockIconSize: 46
    property bool clock24Hour: true
    property bool resettingAppearance: false
    function resetAppearance() {
        resettingAppearance = true;
        theme = "glass";
        customAccent = "";
        panelHeight = 48;
        dockIconSize = 46;
        layoutMode = "floating";
        clock24Hour = true;
        resettingAppearance = false;
        save();
    }
    function boundedInt(value, fallback, min, max) {
        return typeof value === "number" && Number.isFinite(value) ? Math.max(min, Math.min(max, Math.round(value))) : fallback;
    }
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
                if (typeof data.customAccent === "string" && /^#[0-9a-fA-F]{6}$/.test(data.customAccent)) customAccent = data.customAccent;
                panelHeight = boundedInt(data.panelHeight, 48, 44, 68);
                dockIconSize = boundedInt(data.dockIconSize, 46, 36, 64);
                if (typeof data.clock24Hour === "boolean") clock24Hour = data.clock24Hour;
                if (["adaptive","balanced","eco"].includes(data.energyMode)) energyMode = data.energyMode;
                if (typeof data.suspendDockOnBattery === "boolean") suspendDockOnBattery = data.suspendDockOnBattery;
                widgetExtensions = Registry.normalizeExtensions(data.widgetExtensions);
                enabledWidgets = Registry.normalizeEnabled(data.enabledWidgets, widgetExtensions);
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
        if (!initialized || !writable || resettingAppearance || updatingWidgets) return;
        file.setText(JSON.stringify({
            version: 1, theme: theme, layoutMode: layoutMode,
            reduceEffects: reduceEffects, autoEco: autoEco,
            energyMode: energyMode, suspendDockOnBattery: suspendDockOnBattery,
            dockEnabled: dockEnabled, pinnedApps: pinnedApps,
            customAccent: customAccent, panelHeight: panelHeight,
            dockIconSize: dockIconSize, clock24Hour: clock24Hour,
            widgetExtensions: widgetExtensions, enabledWidgets: enabledWidgets
        }, null, 2) + "\n");
    }
    onThemeChanged: save()
    onLayoutModeChanged: save()
    onReduceEffectsChanged: save()
    onAutoEcoChanged: save()
    onEnergyModeChanged: save()
    onSuspendDockOnBatteryChanged: save()
    onDockEnabledChanged: save()
    onPinnedAppsChanged: save()
    onCustomAccentChanged: save()
    onPanelHeightChanged: save()
    onDockIconSizeChanged: save()
    onClock24HourChanged: save()
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
