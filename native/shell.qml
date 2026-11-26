import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Pipewire

ShellRoot {
    id: shell
    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }
    PwObjectTracker {
        objects: Pipewire.defaultAudioSink ? [Pipewire.defaultAudioSink] : []
    }
    Variants {
        model: Quickshell.screens
        TopBar {
            required property var modelData
            screen: modelData
            clockText: Qt.formatDateTime(clock.date, "ddd, MMM d  ·  HH:mm")
        }
    }
}
