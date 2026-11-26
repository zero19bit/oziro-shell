import QtQuick
import Quickshell
import Quickshell.Io
import "WidgetRegistry.js" as Registry
import "WallpaperPolicy.js" as WallpaperPolicy

Scope {
    id: prefs
    property string theme: "glass"
    property string layoutMode: "top"
    property bool reduceEffects: false
    property bool autoEco: true
    property string energyMode: "adaptive"
    property bool suspendDockOnBattery: false
    property bool dockEnabled: false
    property var pinnedApps: []
    property var wallpaper: WallpaperPolicy.normalize(null)
    function setWallpaper(config) { wallpaper = WallpaperPolicy.normalize(config); save(); }
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
    property int panelHeight: 32
    property int dockIconSize: 46
    property bool clock24Hour: true
    property bool resettingAppearance: false
    function resetAppearance() {
        resettingAppearance = true;
        theme = "glass";
        customAccent = "";
        panelHeight = 32;
        dockIconSize = 46;
        layoutMode = "top";
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
    readonly property string settingsPath: Quickshell.statePath(Quickshell.env("OZIRO_LOGIN_SESSION") === "1" ? "login-preferences.json" : "preferences.json")
    function load() {
        if (Quickshell.env("OZIRO_NESTED_PREVIEW") === "1") {
            dockEnabled = true;
            wallpaper = WallpaperPolicy.normalize({enabled:true,color:"#18232f"});
            status = "Temporary preview settings";
            initialized = true;
            return;
        }
        if (Quickshell.env("OZIRO_LOGIN_SESSION") === "1") {
            dockEnabled = true;
            wallpaper = WallpaperPolicy.normalize({enabled:true,color:"#18232f"});
        }
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
                panelHeight = boundedInt(data.panelHeight, 32, 30, 68);
                // Migrate only the old stock bar dimensions; retain other explicit sizes and layouts.
                if (data.appearanceRevision !== 2 && data.panelHeight === 48 && data.layoutMode === "floating") {
                    panelHeight = 32;
                    layoutMode = "top";
                }
                dockIconSize = boundedInt(data.dockIconSize, 46, 36, 64);
                if (typeof data.clock24Hour === "boolean") clock24Hour = data.clock24Hour;
                if (["adaptive","balanced","eco"].includes(data.energyMode)) energyMode = data.energyMode;
                if (typeof data.suspendDockOnBattery === "boolean") suspendDockOnBattery = data.suspendDockOnBattery;
                widgetExtensions = Registry.normalizeExtensions(data.widgetExtensions);
                enabledWidgets = Registry.normalizeEnabled(data.enabledWidgets, widgetExtensions);
                wallpaper = WallpaperPolicy.normalize(data.wallpaper);
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
        if (!initialized || !writable || resettingAppearance || updatingWidgets || Quickshell.env("OZIRO_NESTED_PREVIEW") === "1") return;
        file.setText(JSON.stringify({
            version: 1, appearanceRevision: 2, theme: theme, layoutMode: layoutMode,
            reduceEffects: reduceEffects, autoEco: autoEco,
            energyMode: energyMode, suspendDockOnBattery: suspendDockOnBattery,
            dockEnabled: dockEnabled, pinnedApps: pinnedApps,
            customAccent: customAccent, panelHeight: panelHeight,
            dockIconSize: dockIconSize, clock24Hour: clock24Hour,
            widgetExtensions: widgetExtensions, enabledWidgets: enabledWidgets,
            wallpaper: wallpaper
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
        path: Quickshell.env("OZIRO_NESTED_PREVIEW") === "1" ? "" : prefs.settingsPath
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
