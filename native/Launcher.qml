import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: win
    required property var prefs
    signal dismiss()
    anchors { top: win.prefs.layoutMode !== "bottom"; bottom: win.prefs.layoutMode === "bottom" }
    margins { top: win.prefs.popupMargin; bottom: win.prefs.popupMargin }
    implicitWidth: Math.min(620, screen ? screen.width - 24 : 620)
    implicitHeight: Math.min(480, screen ? screen.height - 140 : 480)
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    color: "transparent"
    readonly property var catalog: DesktopEntries.applications.values.filter(a => !a.noDisplay && !a.runInTerminal)
        .sort((a,b) => a.name.localeCompare(b.name))
    readonly property var entries: {
        const query = search.text.trim().toLowerCase()
        return !query ? catalog : catalog.filter(a => (a.name + " " + a.genericName + " " + a.keywords.join(" ")).toLowerCase().includes(query))
    }
    function launch(entry) {
        if (!entry) return
        entry.execute()
        win.dismiss()
    }
    Rectangle {
        anchors.fill: parent
        color: win.prefs.popupColor
        border.color: win.prefs.outline
        radius: 20
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 18
            spacing: 12
            RowLayout {
                Text { text: "Applications"; color: win.prefs.accent; font.bold: true; Layout.fillWidth: true }
                Chip { prefs: win.prefs; label: "Close"; onActivated: win.dismiss() }
            }
            TextField {
                id: search
                Layout.fillWidth: true
                placeholderText: "Search applications…"
                implicitHeight: 44
                leftPadding: 12
                rightPadding: 12
                selectByMouse: true
                color: win.prefs.foreground
                placeholderTextColor: win.prefs.muted
                background: Rectangle { radius: 12; color: win.prefs.cardColor; border.color: search.activeFocus ? win.prefs.accent : win.prefs.outline }
                onTextChanged: results.currentIndex = 0
                Keys.onEscapePressed: win.dismiss()
                Keys.onDownPressed: results.incrementCurrentIndex()
                Keys.onUpPressed: results.decrementCurrentIndex()
                Keys.onReturnPressed: win.launch(win.entries[results.currentIndex])
                Component.onCompleted: forceActiveFocus()
            }
            ListView {
                id: results
                Layout.fillWidth: true
                Layout.fillHeight: true
                model: win.entries
                clip: true
                spacing: 4
                currentIndex: 0
                cacheBuffer: 0
                delegate: ItemDelegate {
                    id: app
                    required property var modelData
                    required property int index
                    width: results.width
                    height: 52
                    highlighted: ListView.isCurrentItem
                    onClicked: win.launch(modelData)
                    background: Rectangle { radius: 11; color: app.highlighted || app.hovered ? win.prefs.hoverColor : "transparent"; border.width: app.highlighted ? 1 : 0; border.color: win.prefs.accent }
                    contentItem: RowLayout {
                        Image { Layout.preferredWidth: 30; Layout.preferredHeight: 30; source: Quickshell.iconPath(app.modelData.icon, "application-x-executable"); sourceSize.width: 32; sourceSize.height: 32; cache: false }
                        Text { text: app.modelData.name; textFormat: Text.PlainText; color: win.prefs.foreground; font.pixelSize: 15; elide: Text.ElideRight; Layout.fillWidth: true }
                        Chip {
                            prefs: win.prefs
                            label: win.prefs.pinnedApps.includes(app.modelData.id) ? "−" : "+"
                            Accessible.name: (win.prefs.pinnedApps.includes(app.modelData.id) ? "Unpin " : "Pin ") + app.modelData.name
                            enabled: win.prefs.pinnedApps.includes(app.modelData.id) || win.prefs.pinnedApps.length < 12
                            selected: win.prefs.pinnedApps.includes(app.modelData.id)
                            onActivated: win.prefs.togglePin(app.modelData.id)
                        }
                    }
                }
            }
            Text { text: win.entries.length ? win.entries.length + " applications · Enter to launch" : "No matching graphical applications"; color: win.prefs.muted; font.pixelSize: 12 }
        }
    }
}
