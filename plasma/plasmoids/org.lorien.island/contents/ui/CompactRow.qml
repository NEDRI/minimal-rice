// ================================================================ the compact contents
import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Item {
    id: comp
    property var isle
    property bool inBar: true
    clip: true

    Item {
        id: left
        anchors { left: parent.left; leftMargin: 14; verticalCenter: parent.verticalCenter }
        width: 22; height: 22
        visible: isle.activity

        Kirigami.ShadowedImage {
            anchors.fill: parent
            visible: isle.hasMusic
            source: isle.hasMusic ? isle.player.artUrl : ""
            radius: 6
            color: "#2c2c2e"
            fillMode: Image.PreserveAspectCrop
        }
        TimerRing { isle: comp.isle;
            anchors.fill: parent
            visible: !isle.hasMusic && isle.hasTimer
            lineWidth: 3
        }
    }

    Text {
        anchors.centerIn: parent
        text: isle.clock(isle.now)
        color: "white"
        font { family: isle.font; pixelSize: 15; weight: Font.DemiBold; letterSpacing: -0.1 }
        font.features: { "tnum": 1 }
    }

    Item {
        anchors { right: parent.right; rightMargin: 14; verticalCenter: parent.verticalCenter }
        width: rightText.visible ? rightText.width : 22
        height: 22
        visible: isle.activity

        Bars {
            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
            visible: isle.hasMusic
            barHeight: 14
            playing: isle.playing && visible
        }
        Text {
            id: rightText
            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
            visible: !isle.hasMusic && isle.hasTimer
            text: isle.mmss(isle.timerLeft)
            color: isle.timerPhase === "break" ? isle.green : "white"
            font { family: isle.font; pixelSize: 15; weight: Font.DemiBold }
            font.features: { "tnum": 1 }
        }
    }
}
