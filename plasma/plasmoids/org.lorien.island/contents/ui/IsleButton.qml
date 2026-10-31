// small round text button in Isle's style
import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Rectangle {
    id: comp
    property string glyph: ""
    property int glyphSize: 18
    property bool round: false
    signal clicked()
    width: glyphSize + 16; height: width
    radius: width / 2
    color: area.pressed ? Qt.rgba(1, 1, 1, 0.2) : area.containsMouse ? Qt.rgba(1, 1, 1, 0.12)
        : round ? "#2c2c2e" : "transparent"
    Text {
        anchors.centerIn: parent
        text: comp.glyph
        color: "white"
        font { family: "JetBrainsMono Nerd Font"; pixelSize: comp.glyphSize }
    }
    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        onClicked: comp.clicked()
    }
}
