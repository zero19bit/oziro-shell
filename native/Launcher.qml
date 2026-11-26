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
    margins { top: 62; bottom: 62 }
    implicitWidth: Math.min(620, screen ? screen.width - 24 : 620)
    implicitHeight: Math.min(480, screen ? screen.height - 140 : 480)
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    color: "transparent"
    property var entries: {
        const query = search.text.trim().toLowerCase()
        return DesktopEntries.applications.values.filter(a => !a.noDisplay && !a.runInTerminal &&
            (!query || (a.name + " " + a.genericName + " " + a.keywords.join(" ")).toLowerCase().includes(query)))
            .sort((a,b) => a.name.localeCompare(b.name))
    }
    function launch(entry) {
        if (!entry) return
        entry.execute()
        win.dismiss()
    }
    Rectangle {
        anchors.fill: parent
        color: win.prefs.surfaceColor
        border.color: win.prefs.outline
        radius: 20
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 18
            spacing: 12
            RowLayout {
                Text { text: "OZIRO / FIND"; color: win.prefs.accent; font.bold: true; Layout.fillWidth: true }
                Chip { prefs: win.prefs; label: "Close"; onActivated: win.dismiss() }
            }
            TextField {
                id: search
                Layout.fillWidth: true
                placeholderText: "Search installed applications…"
                selectByMouse: true
                color: win.prefs.foreground
                placeholderTextColor: win.prefs.muted
                background: Rectangle { radius: 10; color: win.prefs.surfaceColor; border.color: win.prefs.accent }
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
                delegate: ItemDelegate {
                    id: app
                    required property var modelData
                    required property int index
                    width: results.width
                    height: 48
                    highlighted: ListView.isCurrentItem
                    onClicked: win.launch(modelData)
                    background: Rectangle { radius: 9; color: app.highlighted || app.hovered ? win.prefs.outline : "transparent" }
                    contentItem: RowLayout {
                        Image { Layout.preferredWidth: 30; Layout.preferredHeight: 30; source: Quickshell.iconPath(app.modelData.icon, "application-x-executable"); sourceSize.width: 32; sourceSize.height: 32 }
                        Text { text: app.modelData.name; color: win.prefs.foreground; font.pixelSize: 15; elide: Text.ElideRight; Layout.fillWidth: true }
                    }
                }
            }
            Text { text: win.entries.length ? win.entries.length + " applications · Enter to launch" : "No matching graphical applications"; color: win.prefs.muted; font.pixelSize: 12 }
        }
    }
}
