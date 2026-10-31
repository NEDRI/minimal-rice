// The open island's header, as Isle's: tabs on the left (the open one with its name), date and time on the right.
import QtQuick
import QtQuick.Layouts

RowLayout {
    id: comp
    property var isle
        spacing: 2

    Repeater {
        model: [
            { id: "music", glyph: "\u{F075A}", label: "Music" },
            { id: "focus", glyph: "\u{F13AB}", label: "Focus" },
            { id: "calendar", glyph: "\u{F00ED}", label: "Calendar" },
        ]
        Rectangle {
            readonly property bool checked: isle.page === modelData.id
            Layout.preferredHeight: 26
            Layout.preferredWidth: tabRow.implicitWidth + 16
            radius: 13
            color: checked ? Qt.rgba(1, 1, 1, 0.09) : tabArea.containsMouse ? Qt.rgba(1, 1, 1, 0.05) : "transparent"
            Behavior on Layout.preferredWidth { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
            Row {
                id: tabRow
                anchors.centerIn: parent
                spacing: 6
                Text {
                    text: modelData.glyph
                    color: "white"
                    opacity: parent.parent.checked ? 1 : tabArea.containsMouse ? 200 / 255 : 140 / 255
                    font { family: "JetBrainsMono Nerd Font"; pixelSize: 15 }
                    anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                    visible: parent.parent.checked
                    text: modelData.label
                    color: "white"
                    font { family: isle.font; pixelSize: 13; weight: Font.DemiBold }
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
            MouseArea {
                id: tabArea
                anchors.fill: parent
                hoverEnabled: true
                onClicked: isle.page = modelData.id
            }
        }
    }
    Item { Layout.fillWidth: true }
    Text {
        text: Qt.formatDate(isle.now, "ddd d MMM")
        color: Qt.rgba(1, 1, 1, 0.9)
        font { family: isle.font; pixelSize: 13 }
    }
    Item { Layout.preferredWidth: 8 }
    Text {
        text: isle.clock(isle.now)
        color: "white"
        font { family: isle.font; pixelSize: 13; weight: Font.DemiBold }
        font.features: { "tnum": 1 }
    }
}
