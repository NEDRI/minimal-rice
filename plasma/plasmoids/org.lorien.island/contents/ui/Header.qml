// The open island's header, as Isle's expanded.js: a tab per page on the left (the open one lit, with its
// name sliding out), and on the right the music bars, the focus ring, the date and the time.
import QtQuick
import QtQuick.Layouts

Item {
    id: comp
    property var isle
    readonly property var tabs: [
        { id: "music", icon: "isle-music", label: "Music" },
        { id: "notifications", icon: "isle-bell", label: "Notifications" },
        { id: "focus", icon: "isle-timer", label: "Focus" },
        { id: "reminders", icon: "isle-tasks", label: "Reminders" },
        { id: "calendar", icon: "isle-calendar", label: "Calendar" },
    ]

    Row {
        anchors { left: parent.left; verticalCenter: parent.verticalCenter }
        spacing: 2

        Repeater {
            model: comp.tabs
            Rectangle {
                id: tab
                readonly property bool open: isle.page === modelData.id
                height: 26
                width: 10 + 16 + nameClip.width + 10
                radius: height / 2
                color: open ? Qt.rgba(1, 1, 1, 0.09) : area.containsMouse ? Qt.rgba(1, 1, 1, 0.05) : "transparent"
                Behavior on color { ColorAnimation { duration: 150 } }

                IsleIcon {
                    id: glyph
                    x: 10
                    anchors.verticalCenter: parent.verticalCenter
                    name: modelData.icon + (tab.open ? "-fill" : "")
                    size: 16
                    opacity: tab.open ? 1 : area.containsMouse ? 200 / 255 : 140 / 255
                }
                // the name opens and closes by width, so the tabs beside it slide over
                Item {
                    id: nameClip
                    anchors { left: glyph.right; verticalCenter: parent.verticalCenter }
                    height: name.implicitHeight
                    width: tab.open ? name.implicitWidth + 6 : 0
                    clip: true
                    Behavior on width { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                    Text {
                        id: name
                        x: 6
                        text: modelData.label
                        color: "white"
                        font { family: isle.font; pixelSize: 13; weight: Font.DemiBold }
                    }
                }
                MouseArea {
                    id: area
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: isle.page = modelData.id
                }
            }
        }
    }

    Row {
        anchors { right: parent.right; verticalCenter: parent.verticalCenter }
        spacing: 10

        Bars {
            anchors.verticalCenter: parent.verticalCenter
            visible: isle.hasTrack
            barHeight: 14
            playing: isle.playing && isle.mode === "open"
        }
        Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8
            Ring {
                anchors.verticalCenter: parent.verticalCenter
                visible: isle.hasTimer
                size: 15; lineWidth: 2.5
                progress: isle.timerProgress
                color: isle.timerColor
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: Qt.formatDate(isle.now, "ddd d MMM")
                color: Qt.rgba(1, 1, 1, 0.9)
                font { family: isle.font; pixelSize: 13 }
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: Qt.formatTime(isle.now, "HH:mm")
                color: "white"
                font { family: isle.font; pixelSize: 13; weight: Font.DemiBold }
                font.features: { "tnum": 1 }
            }
        }
    }
}
