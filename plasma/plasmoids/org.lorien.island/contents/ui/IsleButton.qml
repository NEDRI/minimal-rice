// Isle's flat round icon button: white, a light disc under the pointer.
import QtQuick

Rectangle {
    id: comp
    property string icon: ""
    property int iconSize: 18
    property real padding: 6
    property bool round: false    // .isle-button-round: a grey disc
    signal clicked()

    width: iconSize + 2 * padding
    height: width
    radius: width / 2
    color: area.pressed ? Qt.rgba(1, 1, 1, 0.2) : area.containsMouse ? (round ? "#3a3a3c" : Qt.rgba(1, 1, 1, 0.12))
        : round ? "#2c2c2e" : "transparent"
    Behavior on color { ColorAnimation { duration: 120 } }

    IsleIcon { anchors.centerIn: parent; name: comp.icon; size: comp.iconSize }
    MouseArea { id: area; anchors.fill: parent; hoverEnabled: true; onClicked: comp.clicked() }
}
