import QtQuick
import QtQuick.Controls

Slider {
    id: slider
    required property var prefs
    implicitHeight: 30
    leftPadding: 9
    rightPadding: 9
    background: Rectangle {
        x: slider.leftPadding
        y: slider.topPadding + (slider.availableHeight-height)/2
        width: slider.availableWidth
        height: 7
        radius: 4
        color: slider.prefs.outline
        opacity: slider.enabled ? 1 : 0.5
        Rectangle {
            width: parent.width * slider.visualPosition
            height: parent.height
            radius: 4
            color: slider.prefs.accent
        }
    }
    handle: Rectangle {
        x: slider.leftPadding + slider.visualPosition * slider.availableWidth - width/2
        y: slider.topPadding + (slider.availableHeight-height)/2
        width: 18
        height: 18
        radius: 9
        color: slider.prefs.accent
        border.color: slider.prefs.selectedText
        border.width: slider.activeFocus ? 2 : 1
        opacity: slider.enabled ? 1 : 0.5
    }
}
