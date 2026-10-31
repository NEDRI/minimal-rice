// The closed island's contents, as Isle's compact.js inside the top bar: the first activity (music, else
// the focus timer) takes the left slot, music's bars the right; with both, the timer's time joins the bars.
import QtQuick
import org.kde.kirigami as Kirigami

Item {
    id: comp
    property var isle

    readonly property string primary: isle.hasTrack ? "music" : isle.hasTimer ? "timer" : ""
    readonly property bool second: primary === "music" && isle.hasTimer
    // how much wider than a slot the right side is while it holds the timer's time (balanced on the left)
    readonly property real secondExtra: second ? secondTime.implicitWidth + 8 : 0

    Item {
        anchors { left: parent.left; leftMargin: 14 + comp.secondExtra; verticalCenter: parent.verticalCenter }
        width: 22; height: 22

        Art {
            anchors.fill: parent
            visible: comp.primary === "music"
            source: isle.artUrl
            size: 22
            radius: 6
        }

        Ring {
            anchors.centerIn: parent
            visible: comp.primary === "timer"
            size: 18; lineWidth: 3
            progress: isle.timerProgress
            color: isle.timerColor
        }
    }

    // Do Not Disturb: a moon before the time
    Row {
        anchors.centerIn: parent
        spacing: 6
        IsleIcon { anchors.verticalCenter: parent.verticalCenter; visible: isle.dnd; name: "isle-moon"; size: 13; opacity: 0.85 }
        Text { renderType: Text.QtRendering;
            anchors.verticalCenter: parent.verticalCenter
            text: Qt.formatTime(isle.now, "HH:mm")
            color: "white"
            font { family: isle.font; pixelSize: 15; weight: Font.DemiBold; letterSpacing: -0.1 }
            font.features: { "tnum": 1 }
        }
    }

    Row {
        anchors { right: parent.right; rightMargin: 14; verticalCenter: parent.verticalCenter }
        spacing: 8
        visible: comp.primary === "music"

        Bars {
            anchors.verticalCenter: parent.verticalCenter
            barHeight: 14
            playing: isle.playing
        }
        Text { renderType: Text.QtRendering;
            id: secondTime
            visible: comp.second
            anchors.verticalCenter: parent.verticalCenter
            text: isle.mmss(isle.timerRemainingMs / 1000)
            color: isle.timerColor
            font { family: isle.font; pixelSize: 15; weight: Font.DemiBold; letterSpacing: -0.1 }
            font.features: { "tnum": 1 }
        }
    }
}
