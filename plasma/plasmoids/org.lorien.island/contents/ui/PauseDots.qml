// Three dots that breathe while the singing pauses (Isle's PauseDots).
import QtQuick

Row {
    id: comp
    property bool breathing: false
    property color dotColor: "white"
    spacing: 6
    Repeater {
        model: 3
        Rectangle {
            width: 7; height: 7; radius: 3.5
            color: comp.dotColor
            opacity: comp.breathing ? 110 / 255 : 1
            SequentialAnimation on scale {
                running: comp.breathing && comp.visible
                loops: Animation.Infinite
                PauseAnimation { duration: index * 180 }
                NumberAnimation { from: 1; to: 1.35; duration: 600; easing.type: Easing.InOutSine }
                NumberAnimation { from: 1.35; to: 1; duration: 600; easing.type: Easing.InOutSine }
                PauseAnimation { duration: (2 - index) * 180 }
            }
        }
    }
}
