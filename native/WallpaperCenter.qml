import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: win
    required property var prefs
    signal dismiss()
    signal openSettings()
    property string message: ""
    anchors { top: win.prefs.layoutMode !== "bottom"; bottom: win.prefs.layoutMode === "bottom"; right: true }
    margins { top: win.prefs.popupMargin; bottom: win.prefs.popupMargin; right: 12 }
    implicitWidth: Math.min(510, screen ? Math.max(1,screen.width-24) : 510)
    implicitHeight: Math.min(650, screen ? Math.max(1,screen.height-win.prefs.popupMargin-36) : 650)
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    color: "transparent"
    Rectangle {
        anchors.fill: parent; radius: 20; color: win.prefs.popupColor; border.color: win.prefs.outline
        ColumnLayout {
            anchors.fill: parent; anchors.margins: 16; spacing: 10
            RowLayout {
                Text { Layout.fillWidth: true; text: "Wallpaper"; color: win.prefs.foreground; font.bold: true; font.pixelSize: 20 }
                Chip { prefs: win.prefs; label: "Back"; onActivated: win.openSettings() }
                Chip { prefs: win.prefs; label: "Close"; onActivated: win.dismiss() }
            }
            ScrollView {
                id: scroll
                Layout.fillWidth: true; Layout.fillHeight: true; contentWidth: availableWidth
                clip: true; rightPadding: 12
                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                ColumnLayout {
                    width: scroll.availableWidth; spacing: 10
                    QuickToggle {
                        Layout.fillWidth: true
                        prefs: win.prefs
                        label: "Oziro desktop background"
                        detail: win.prefs.wallpaper.enabled ? "Enabled" : "Disabled"
                        selected: win.prefs.wallpaper.enabled
                        onActivated: win.prefs.updateWallpaper("enabled",!win.prefs.wallpaper.enabled)
                    }
                    Text { Layout.fillWidth: true; wrapMode: Text.WordWrap; text: "Optional layer. Existing wallpaper services are not stopped; other background layers may cover Oziro. Disable to return to the existing desktop."; color: win.prefs.muted; font.pixelSize: 11 }
                    SectionLabel { prefs: win.prefs; label: "LAYER COMPATIBILITY" }
                    Flow {
                        Layout.fillWidth: true; spacing: 6
                        Chip { prefs: win.prefs; label: "Background"; selected: win.prefs.wallpaper.layer === "background"; onActivated: win.prefs.updateWallpaper("layer","background") }
                        Chip { prefs: win.prefs; label: "Compatibility (Bottom)"; selected: win.prefs.wallpaper.layer === "bottom"; onActivated: win.prefs.updateWallpaper("layer","bottom") }
                    }
                    Text { Layout.fillWidth: true; wrapMode: Text.WordWrap; text: "If another shell covers the background, try Compatibility on an empty workspace. This can cover other desktop widgets, but does not stop their services. Switch back or disable wallpaper to undo."; color: win.prefs.muted; font.pixelSize: 11 }
                    SectionLabel { prefs: win.prefs; label: "PREVIEW" }
                    Rectangle {
                        Layout.fillWidth: true; Layout.preferredHeight: 155
                        color: win.prefs.wallpaper.color; radius: 8; clip: true
                        Image {
                            id: preview
                            anchors.fill: parent
                            source: win.prefs.wallpaperUrl
                            asynchronous: true; cache: false
                            sourceSize.width: 480; sourceSize.height: 270
                            fillMode: win.prefs.wallpaper.fit === "contain" ? Image.PreserveAspectFit : Image.PreserveAspectCrop
                            visible: status === Image.Ready
                        }
                    }
                    Text { visible: win.prefs.wallpaper.mode === "image"; Layout.fillWidth: true; wrapMode: Text.WordWrap; text: preview.status === Image.Ready ? "Image preview ready" : preview.status === Image.Error ? "Could not read image — solid color fallback" : "Loading local image…"; color: win.prefs.muted; font.pixelSize: 11 }
                    SectionLabel { prefs: win.prefs; label: "BACKGROUND STYLE" }
                    Flow {
                        Layout.fillWidth: true; spacing: 6
                        Chip { prefs: win.prefs; label: "Solid"; selected: win.prefs.wallpaper.mode === "solid"; onActivated: win.prefs.updateWallpaper("mode","solid") }
                        Chip { prefs: win.prefs; label: "Image"; selected: win.prefs.wallpaper.mode === "image"; enabled: win.prefs.wallpaperPathValid(win.prefs.wallpaper.path); onActivated: win.prefs.updateWallpaper("mode","image") }
                        Chip { prefs: win.prefs; label: "Fill"; selected: win.prefs.wallpaper.fit === "cover"; onActivated: win.prefs.updateWallpaper("fit","cover") }
                        Chip { prefs: win.prefs; label: "Fit"; selected: win.prefs.wallpaper.fit === "contain"; onActivated: win.prefs.updateWallpaper("fit","contain") }
                    }
                    Flow {
                        Layout.fillWidth: true; spacing: 8
                        Repeater {
                            model: ["#18232f","#102d30","#30233e","#333029","#111111","#e4e7ef"]
                            Button {
                                id: swatch
                                required property string modelData
                                width: 38; height: 36
                                Accessible.name: "Wallpaper color " + modelData
                                background: Rectangle { radius: 9; color: swatch.modelData; border.color: win.prefs.foreground; border.width: win.prefs.wallpaper.color === swatch.modelData || swatch.activeFocus ? 3 : 1 }
                                onClicked: win.prefs.updateWallpaper("color",modelData)
                            }
                        }
                    }
                    SectionLabel { prefs: win.prefs; label: "LOCAL IMAGE" }
                    TextField {
                        id: pathInput
                        Layout.fillWidth: true; maximumLength: 2048
                        text: win.prefs.wallpaper.path
                        placeholderText: "/home/user/Pictures/wallpaper.jpg"
                        color: win.prefs.foreground; placeholderTextColor: win.prefs.muted
                        selectByMouse: true
                        background: Rectangle { radius: 8; color: win.prefs.cardColor; border.color: pathInput.activeFocus ? win.prefs.accent : win.prefs.outline }
                    }
                    Flow {
                        Layout.fillWidth: true; spacing: 6
                        Chip { prefs: win.prefs; label: "Use image"; enabled: win.prefs.wallpaperPathValid(pathInput.text); onActivated: { win.message = win.prefs.useWallpaperImage(pathInput.text) ? "Local image selected" : "Invalid path"; } }
                        Chip { prefs: win.prefs; label: "Self-test"; onActivated: { const r=win.prefs.wallpaperSelfTest(); win.message=r.passed+"/"+r.total+" policy cases passed"; } }
                    }
                    Text { Layout.fillWidth: true; wrapMode: Text.WordWrap; text: "Absolute local paths only. PNG, JPG, WebP or BMP. No downloads or commands. Images are decoded with a bounded requested size; full-resolution loading behavior depends on the Qt image decoder."; color: win.prefs.muted; font.pixelSize: 11 }
                    Text { Layout.fillWidth: true; textFormat: Text.PlainText; wrapMode: Text.WordWrap; text: win.message + " · " + win.prefs.settingsStatus; color: win.prefs.foreground; font.pixelSize: 11 }
                }
            }
        }
    }
}
