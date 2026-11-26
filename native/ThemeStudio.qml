import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: win
    required property var prefs
    signal dismiss()
    anchors { top: win.prefs.layoutMode !== "bottom"; bottom: win.prefs.layoutMode === "bottom"; right: true }
    margins { top: win.prefs.popupMargin; bottom: win.prefs.popupMargin; right: 12 }
    implicitWidth: Math.min(540, screen ? Math.max(1,screen.width-24) : 540)
    implicitHeight: Math.min(760, screen ? Math.max(1,screen.height-win.prefs.popupMargin-36) : 760)
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    color: "transparent"
    Rectangle {
        anchors.fill: parent
        radius: 20
        color: win.prefs.popupColor
        border.color: win.prefs.outline
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12
            RowLayout {
                Text { Layout.fillWidth: true; text: "OZIRO / Theme Studio"; font.pixelSize: 20; font.bold: true; color: win.prefs.foreground }
                Chip { prefs: win.prefs; label: "Close"; onActivated: win.dismiss() }
            }
            ScrollView {
                id: scroll
                Layout.fillWidth: true
                Layout.fillHeight: true
                rightPadding: 12
                clip: true
                contentWidth: availableWidth
                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                ScrollBar.vertical.policy: ScrollBar.AsNeeded
                ColumnLayout {
                    width: scroll.availableWidth
                    spacing: 12
                    SectionLabel { prefs: win.prefs; label: "LIVE PREVIEW" }
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 114
                        radius: 14
                        color: win.prefs.cardColor
                        border.color: win.prefs.outline
                        Rectangle {
                            anchors { left: parent.left; right: parent.right; top: win.prefs.layoutMode === "bottom" ? undefined : parent.top; bottom: win.prefs.layoutMode === "bottom" ? parent.bottom : undefined; margins: 10 }
                            height: win.prefs.panelHeight * 0.65
                            radius: win.prefs.layoutMode === "floating" ? 10 : 0
                            color: win.prefs.surfaceColor
                            Row {
                                anchors.centerIn: parent; spacing: 6
                                Rectangle { width: 44; height: 20; radius: 6; color: win.prefs.accent
                                    Text { anchors.centerIn: parent; text: "OZIRO"; color: win.prefs.selectedText; font.pixelSize: 9; font.bold: true }
                                }
                                Text { anchors.verticalCenter: parent.verticalCenter; text: win.prefs.clock24Hour ? "14:30" : "2:30 PM"; color: win.prefs.foreground }
                            }
                        }
                        Row {
                            anchors { horizontalCenter: parent.horizontalCenter; bottom: win.prefs.layoutMode === "bottom" ? undefined : parent.bottom; top: win.prefs.layoutMode === "bottom" ? parent.top : undefined; margins: 10 }
                            visible: win.prefs.dockEnabled && !win.prefs.dockSuspended
                            spacing: 5
                            Repeater {
                                model: 4
                                Rectangle {
                                    required property int index
                                    width: win.prefs.dockIconSize * 0.55; height: width; radius: 6
                                    color: index === 0 ? win.prefs.accent : win.prefs.surfaceColor
                                }
                            }
                        }
                    }
                    SectionLabel { prefs: win.prefs; label: "DESIGN PRESET" }
                    Flow {
                        Layout.fillWidth: true; spacing: 7
                        Repeater {
                            model: ["glass","material","minimal","cyber","light"]
                            Chip {
                                required property string modelData
                                prefs: win.prefs; label: modelData; selected: win.prefs.theme === modelData
                                onActivated: win.prefs.theme = modelData
                            }
                        }
                    }
                    Text { text: "Accent color"; color: win.prefs.foreground; font.bold: true }
                    Flow {
                        Layout.fillWidth: true; spacing: 8
                        Repeater {
                            model: ["#93d9e9","#a78bfa","#34d399","#fbbf24","#fb7185","#60a5fa","#e2e8f0","#64748b"]
                            Button {
                                id: swatch
                                required property string modelData
                                width: 34; height: 34
                                Accessible.name: "Accent " + modelData
                                onClicked: win.prefs.setAccent(modelData)
                                background: Rectangle {
                                    radius: 10; color: swatch.modelData
                                    border.width: win.prefs.customAccent === swatch.modelData || swatch.activeFocus ? 3 : 1
                                    border.color: win.prefs.foreground
                                }
                            }
                        }
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        TextField {
                            id: hex
                            Layout.fillWidth: true
                            maximumLength: 7
                            placeholderText: "#RRGGBB"
                            text: win.prefs.customAccent
                            color: win.prefs.foreground
                            background: Rectangle { color: win.prefs.cardColor; radius: 8; border.color: win.prefs.outline }
                            onAccepted: { if (/^#[0-9a-fA-F]{6}$/.test(text)) win.prefs.setAccent(text); }
                        }
                        Chip { prefs: win.prefs; label: "Apply"; enabled: /^#[0-9a-fA-F]{6}$/.test(hex.text); onActivated: win.prefs.setAccent(hex.text) }
                        Chip { prefs: win.prefs; label: "Default"; onActivated: { win.prefs.setAccent(""); hex.text = ""; } }
                    }
                    SectionLabel { prefs: win.prefs; label: "PANEL PLACEMENT" }
                    Flow {
                        Layout.fillWidth: true; spacing: 6
                        Repeater {
                            model: ["floating","top","bottom"]
                            Chip { required property string modelData; prefs: win.prefs; label: modelData; selected: win.prefs.layoutMode === modelData; onActivated: win.prefs.layoutMode = modelData }
                        }
                    }
                    Text { text: "Panel height · " + Math.round(panelSize.value) + " px"; color: win.prefs.foreground }
                    AccentSlider {
                        prefs: win.prefs
                        id: panelSize
                        Layout.fillWidth: true
                        from: 44; to: 68; stepSize: 2
                        value: win.prefs.panelHeight
                        onPressedChanged: { if (!pressed) win.prefs.panelHeight = Math.round(value); }
                        Keys.onLeftPressed: { win.prefs.panelHeight = Math.max(44, win.prefs.panelHeight-2); }
                        Keys.onRightPressed: { win.prefs.panelHeight = Math.min(68, win.prefs.panelHeight+2); }
                    }
                    Text { text: "Dock size · " + Math.round(dockSize.value) + " px"; color: win.prefs.foreground }
                    AccentSlider {
                        prefs: win.prefs
                        id: dockSize
                        Layout.fillWidth: true
                        from: 36; to: 64; stepSize: 2
                        value: win.prefs.dockIconSize
                        onPressedChanged: { if (!pressed) win.prefs.dockIconSize = Math.round(value); }
                        Keys.onLeftPressed: { win.prefs.dockIconSize = Math.max(36, win.prefs.dockIconSize-2); }
                        Keys.onRightPressed: { win.prefs.dockIconSize = Math.min(64, win.prefs.dockIconSize+2); }
                    }
                    Flow {
                        Layout.fillWidth: true; spacing: 6
                        Chip { prefs: win.prefs; label: "24-hour clock"; selected: win.prefs.clock24Hour; onActivated: win.prefs.clock24Hour = !win.prefs.clock24Hour }
                        Chip { prefs: win.prefs; label: "Dock"; selected: win.prefs.dockEnabled; onActivated: win.prefs.dockEnabled = !win.prefs.dockEnabled }
                        Chip { prefs: win.prefs; label: "Reduce effects"; selected: win.prefs.eco; onActivated: win.prefs.selectEnergyMode(win.prefs.eco ? "balanced" : "eco") }
                    }
                    Text { Layout.fillWidth: true; wrapMode: Text.WordWrap; text: "Appearance reset keeps pinned apps and energy preferences."; color: win.prefs.muted; font.pixelSize: 11 }
                }
            }
            Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: win.prefs.outline }
            RowLayout {
                Layout.fillWidth: true
                Text { Layout.fillWidth: true; text: win.prefs.settingsStatus; color: win.prefs.muted; elide: Text.ElideRight; font.pixelSize: 11 }
                Chip { prefs: win.prefs; label: "Reset appearance"; onActivated: { win.prefs.resetAppearance(); hex.text = ""; panelSize.value = win.prefs.panelHeight; dockSize.value = win.prefs.dockIconSize; } }
            }
        }
    }
}
