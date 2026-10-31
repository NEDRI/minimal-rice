// Isle's scrubber: a 4 px track, a white fill, and a 12 px knob that shows under the pointer.
import QtQuick

Item {
    id: comp
    property real value: 0
    signal released(real fraction)

    height: 16
    property real dragValue: -1
    readonly property real shown: dragValue >= 0 ? dragValue : Math.max(0, Math.min(1, value))

    Rectangle { y: (parent.height - 4) / 2; width: parent.width; height: 4; radius: 2; color: Qt.rgba(1, 1, 1, 0.2) }
    Rectangle { y: (parent.height - 4) / 2; width: Math.round(parent.width * comp.shown); height: 4; radius: 2; color: "white" }
    Rectangle {
        width: 12; height: 12; radius: 6
        x: Math.round(parent.width * comp.shown - 6); y: (parent.height - 12) / 2
        color: "white"
        opacity: area.containsMouse || area.pressed ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 120 } }
    }
    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        onPressed: mouse => comp.dragValue = Math.max(0, Math.min(1, mouse.x / width))
        onPositionChanged: mouse => { if (pressed) comp.dragValue = Math.max(0, Math.min(1, mouse.x / width)); }
        onReleased: { comp.released(comp.dragValue); comp.dragValue = -1; }
    }
}
