//@ pragma StateDir $BASE/oziro-shell/v2
import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import "EnergyPolicy.js" as EnergyPolicy
import "WidgetRegistry.js" as WidgetRegistry
import "WallpaperPolicy.js" as WallpaperPolicy
import "ThemeIdentity.js" as Identity

ShellRoot {
    id: shell
    Preferences { id: settings }
    property alias theme: settings.theme
    property alias layoutMode: settings.layoutMode
    property alias reduceEffects: settings.reduceEffects
    property alias autoEco: settings.autoEco
    property alias energyMode: settings.energyMode
    property alias suspendDockOnBattery: settings.suspendDockOnBattery
    EnergyEngine { id: energy }
    readonly property string powerSource: energy.source
    readonly property bool onBattery: powerSource === "battery"
    readonly property string powerLabel: powerSource === "battery" ? "On battery" : powerSource === "ac" ? "AC power" : "Power unknown"
    readonly property int batteryPercent: energy.percentage
    readonly property var energyPolicy: EnergyPolicy.policy(energyMode, powerSource, reduceEffects, autoEco, dockEnabled, suspendDockOnBattery)
    readonly property bool dockSuspended: energyPolicy.suspended
    readonly property string energyReason: energyPolicy.reason
    readonly property bool powerMonitorRunning: energy.monitorRunning
    readonly property bool powerChecking: energy.checking
    function refreshPower() { energy.refresh(); }
    function energySelfTest() { return EnergyPolicy.selfTest(); }
    function selectEnergyMode(mode) {
        if (!["adaptive","balanced","eco"].includes(mode)) return;
        reduceEffects = false;
        if (mode === "adaptive") autoEco = true;
        energyMode = mode;
    }
    function resetEnergyPolicy() {
        selectEnergyMode("adaptive");
        suspendDockOnBattery = false;
    }
    property alias dockEnabled: settings.dockEnabled
    property alias dockMagnification: settings.dockMagnification
    property alias pinnedApps: settings.pinnedApps
    readonly property var wallpaper: settings.wallpaper
    readonly property var identity: Identity.palette(theme)
    readonly property var themeCatalog: Identity.themes
    function themeWallpaper(id) { return Qt.resolvedUrl("wallpaper-"+Identity.palette(id).file+".svg"); }
    function packWallpaper(id) { return Qt.resolvedUrl("wallpaper-"+Identity.wallpaperId(theme,id)+".svg"); }
    readonly property string wallpaperUrl: wallpaper.mode === "image" ? WallpaperPolicy.fileUrl(wallpaper.path) : wallpaper.mode === "builtin" ? packWallpaper(wallpaper.preset) : ""
    function useThemePack(id) {
        if (!themeCatalog.some(x=>x.id===id)) return;
        const w=wallpaper;
        settings.applyThemePack(id,{enabled:true,mode:"builtin",preset:"auto",color:Identity.palette(id).bg,path:w.path,fit:"cover",layer:w.layer});
    }
    function wallpaperPathValid(path) { return WallpaperPolicy.fileUrl(path) !== ""; }
    function wallpaperSelfTest() { const a=WallpaperPolicy.selfTest(), b=Identity.selfTest(); return {total:a.total+b.total,passed:a.passed+b.passed}; }
    function selectBuiltinWallpaper(preset) {
        if (!["auto","midnight","graphite","aurora","porcelain"].includes(preset)) return;
        const w=wallpaper;
        settings.setWallpaper({enabled:true,mode:"builtin",preset:preset,color:identity.bg,path:w.path,fit:w.fit,layer:w.layer});
    }
    function updateWallpaper(key,value) {
        const next = {enabled:wallpaper.enabled,mode:wallpaper.mode,color:wallpaper.color,path:wallpaper.path,fit:wallpaper.fit,layer:wallpaper.layer,preset:wallpaper.preset};
        if (!["enabled","mode","color","path","fit","layer","preset"].includes(key)) return;
        next[key] = value;
        settings.setWallpaper(next);
    }
    function useWallpaperImage(path) {
        if (!wallpaperPathValid(path)) return false;
        settings.setWallpaper({enabled:wallpaper.enabled,mode:"image",color:wallpaper.color,path:path,fit:wallpaper.fit,layer:wallpaper.layer});
        return true;
    }
    readonly property var widgetExtensions: settings.widgetExtensions
    readonly property var enabledWidgets: settings.enabledWidgets
    readonly property var widgetCards: WidgetRegistry.builtinCards().concat(widgetExtensions)
    readonly property string widgetClock: Qt.formatDateTime(clock.date, clock24Hour ? "HH:mm" : "h:mm AP")
    readonly property string widgetDate: Qt.formatDateTime(clock.date, "dddd, MMM d")
    function toggleWidget(id) {
        if (!widgetCards.some(m => m.id === id)) return;
        const next = enabledWidgets.includes(id) ? enabledWidgets.filter(x=>x!==id) : enabledWidgets.concat([id]);
        settings.setWidgetConfig(widgetExtensions,next);
    }
    function installWidget(text) {
        if (typeof text !== "string" || text.length > 512) return "Manifest too long";
        let m;
        try { m = WidgetRegistry.validateManifest(JSON.parse(text)); } catch(e) { return "Invalid JSON"; }
        if (!m) return "Invalid manifest: check version, ID, title and type";
        if (widgetExtensions.some(x=>x.id===m.id)) return "ID already installed";
        if (widgetExtensions.length >= 4) return "Maximum four custom cards";
        settings.setWidgetConfig(widgetExtensions.concat([m]),enabledWidgets.concat([m.id]));
        return "Installed: " + m.title;
    }
    function removeWidget(id) {
        if (!widgetExtensions.some(m=>m.id===id)) return;
        settings.setWidgetConfig(widgetExtensions.filter(m=>m.id!==id),enabledWidgets.filter(x=>x!==id));
    }
    function resetWidgets() { settings.setWidgetConfig([],WidgetRegistry.builtinCards().map(m=>m.id)); }
    function widgetSelfTest() { return WidgetRegistry.selfTest(); }
    property alias customAccent: settings.customAccent
    property alias panelHeight: settings.panelHeight
    property alias dockIconSize: settings.dockIconSize
    property alias clock24Hour: settings.clock24Hour
    function resetAppearance() { settings.resetAppearance(); }
    function setAccent(value) {
        if (value === "" || /^#[0-9a-fA-F]{6}$/.test(value)) customAccent = value.toLowerCase();
    }
    readonly property int popupMargin: panelHeight + (layoutMode === "floating" ? 12 : 5)
    function linearChannel(c) { return c <= 0.04045 ? c / 12.92 : Math.pow((c + 0.055) / 1.055, 2.4); }
    function togglePin(id) {
        if (typeof id !== "string" || !id.length || id.length > 256) return;
        if (pinnedApps.includes(id)) pinnedApps = pinnedApps.filter(value => value !== id);
        else if (pinnedApps.length < 12) pinnedApps = pinnedApps.concat([id]);
    }
    readonly property string settingsStatus: settings.status
    readonly property bool loginSession: Quickshell.env("OZIRO_LOGIN_SESSION") === "1"
    readonly property bool nestedPreview: Quickshell.env("OZIRO_NESTED_PREVIEW") === "1"
    readonly property bool panelOnly: Quickshell.env("OZIRO_PANEL_ONLY") === "1"
    readonly property bool eco: energyPolicy.eco
    readonly property color baseSurface: identity.surface
    readonly property color surfaceColor: eco || theme==="light" ? baseSurface : Qt.rgba(baseSurface.r,baseSurface.g,baseSurface.b,0.94)
    // Opaque content surfaces keep text legible over busy applications.
    readonly property color popupColor: Qt.rgba(surfaceColor.r,surfaceColor.g,surfaceColor.b,1)
    readonly property color cardColor: identity.card
    readonly property color hoverColor: Qt.tint(popupColor, theme === "light" ? "#10000000" : "#18ffffff")
    readonly property color foreground: identity.fg
    readonly property color accent: customAccent !== "" ? customAccent : identity.accent
    readonly property real accentLuminance: 0.2126 * linearChannel(accent.r) + 0.7152 * linearChannel(accent.g) + 0.0722 * linearChannel(accent.b)
    readonly property color selectedText: accentLuminance > 0.179 ? "#000000" : "#ffffff"
    readonly property color muted: identity.muted
    readonly property color outline: identity.outline
    readonly property bool notificationRequested: Quickshell.env("OZIRO_NOTIFICATIONS") === "1" && !panelOnly
    property bool quietNotifications: false
    property int openMenuCount: 0
    property var activeMenuOutput: null
    readonly property var notificationBackend: notificationLoader.item
    readonly property int notificationCount: notificationBackend ? notificationBackend.count : 0
    Loader {
        id: notificationLoader
        active: shell.notificationRequested
        source: active ? Qt.resolvedUrl("NotificationBackend.qml") : ""
    }
    NiriBackend { id: niri }
    SystemClock { id: clock; precision: SystemClock.Minutes }
    PwObjectTracker { objects: Pipewire.defaultAudioSink ? [Pipewire.defaultAudioSink] : [] }
    Variants {
        model: Quickshell.screens
        Scope {
            id: output
            required property var modelData
            property string popup: ""
            property int popupEpoch: 0
            property bool transientOpen: popup !== "" && popup !== "settings"
            onTransientOpenChanged: shell.openMenuCount = Math.max(0,shell.openMenuCount+(transientOpen ? 1 : -1))
            Component.onDestruction: { if (transientOpen) shell.openMenuCount = Math.max(0,shell.openMenuCount-1); if (shell.activeMenuOutput === output) shell.activeMenuOutput = null; }
            function toggle(name) {
                if (shell.panelOnly || (popupLoader.item && popupLoader.item.dismissBlocked === true)) return;
                if (popup === name) { closePopup(); return; }
                if (name !== "settings" && shell.activeMenuOutput && shell.activeMenuOutput !== output) {
                    shell.activeMenuOutput.closePopup();
                    if (shell.activeMenuOutput) return;
                }
                if (shell.activeMenuOutput === output) shell.activeMenuOutput = null;
                if (name !== "settings") shell.activeMenuOutput = output;
                popupEpoch++;
                popup = name;
                if (name === "wifi") console.info("Oziro Wi-Fi: opening panel");
                popupLoader.setSource(Qt.resolvedUrl(name === "wifi" ? "WifiCenter.qml" : name === "launcher" ? "Launcher.qml" : name === "notifications" ? "NotificationCenter.qml" : name === "settings" ? "SettingsCenter.qml" : name === "appearance" ? "ThemeStudio.qml" : name === "power" ? "PowerCenter.qml" : name === "energy" ? "EnergyCenter.qml" : name === "widgets" ? "WidgetCenter.qml" : name === "wallpaper" ? "WallpaperCenter.qml" : name === "tray" ? "TrayCenter.qml" : name === "lock" ? "LockCenter.qml" : "ControlCenter.qml"),
                                      {screen: output.modelData, prefs: shell});
            }
            function closePopup() {
                if (popupLoader.item && popupLoader.item.dismissBlocked === true) return;
                if (shell.activeMenuOutput === output) shell.activeMenuOutput = null;
                popupEpoch++;
                popup = "";
                popupLoader.source = "";
            }
            Loader {
                active: shell.wallpaper.enabled && !shell.panelOnly && Quickshell.env("OZIRO_DISABLE_WALLPAPER") !== "1"
                sourceComponent: Component {
                    WallpaperSurface { screen: output.modelData; prefs: shell }
                }
            }
            TopBar {
                id: topBar
                screen: output.modelData
                prefs: shell
                niriBackend: niri
                clockText: Qt.formatDateTime(clock.date, shell.clock24Hour ? "ddd, MMM d  ·  HH:mm" : "ddd, MMM d  ·  h:mm AP")
                onOpenLauncher: output.toggle("launcher")
                onOpenControls: output.toggle("controls")
                onOpenNotifications: output.toggle("notifications")
                onOpenWidgets: output.toggle("widgets")
                onOpenPower: output.toggle("power")
                onOpenSettings: output.toggle("settings")
            }
            Loader {
                id: popupLoader
                onLoaded: { if (output.popup === "wifi") console.info("Oziro Wi-Fi: panel loaded"); }
                onStatusChanged: {
                    if (status === Loader.Error) {
                        console.warn("Oziro menu load failed:", output.popup);
                        const epoch=output.popupEpoch;
                        Qt.callLater(() => { if (output.popupEpoch===epoch) output.closePopup(); });
                    }
                }
            }
            Loader {
                active: shell.notificationBackend !== null && !shell.quietNotifications
                    && Quickshell.screens[0] === output.modelData
                source: active ? Qt.resolvedUrl("NotificationToast.qml") : ""
                onLoaded: {
                    item.screen = output.modelData;
                    item.prefs = shell;
                    item.backend = shell.notificationBackend;
                }
            }
            Loader {
                id: dockLoader
                active: shell.dockEnabled && !shell.panelOnly && !shell.dockSuspended
                sourceComponent: Component {
                    Dock {
                        screen: output.modelData
                        prefs: shell
                        niriBackend: niri
                        onOpenLauncher: output.toggle("launcher")
                        onOpenSettings: output.toggle("settings")
                    }
                }
            }
            Connections {
                target: popupLoader.item
                ignoreUnknownSignals: true
                function onDismiss() {
                    const epoch = output.popupEpoch;
                    Qt.callLater(() => { if (output.popupEpoch === epoch) output.closePopup(); });
                }
                function onOpenSettings() { Qt.callLater(() => output.toggle("settings")); }
                function onOpenAppearance() { Qt.callLater(() => output.toggle("appearance")); }
                function onOpenPower() { Qt.callLater(() => output.toggle("power")); }
                function onOpenEnergy() { Qt.callLater(() => output.toggle("energy")); }
                function onOpenWidgets() { Qt.callLater(() => output.toggle("widgets")); }
                function onOpenWallpaper() { Qt.callLater(() => output.toggle("wallpaper")); }
                function onOpenTray() { Qt.callLater(() => output.toggle("tray")); }
                function onOpenLock() { Qt.callLater(() => output.toggle("lock")); }
                function onOpenNotifications() { Qt.callLater(() => output.toggle("notifications")); }
                function onOpenControls() { Qt.callLater(() => output.toggle("controls")); }
                function onOpenWifi() { const epoch = output.popupEpoch; Qt.callLater(() => { if (output.popupEpoch === epoch) output.toggle("wifi"); }); }
            }
        }
    }
}
