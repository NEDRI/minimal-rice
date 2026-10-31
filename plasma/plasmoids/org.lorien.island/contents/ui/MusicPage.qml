// ---------------------------------------------------------------- Music
import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Item {
    id: comp
    property var isle
    // nothing playing: Isle's empty state
    Column {
        anchors.centerIn: parent
        visible: !isle.hasMusic
        spacing: 4
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "\u{F075A}"
            color: Qt.rgba(1, 1, 1, 0.35)
            font { family: "JetBrainsMono Nerd Font"; pixelSize: 28 }
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Nothing playing"
            color: "white"
            font { family: isle.font; pixelSize: 15; weight: Font.DemiBold }
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Play some music and it shows up here"
            color: Qt.rgba(1, 1, 1, 0.5)
            font { family: isle.font; pixelSize: 12 }
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.bottomMargin: 4
        visible: isle.hasMusic
        spacing: 20

        Kirigami.ShadowedImage {
            Layout.preferredWidth: 112
            Layout.preferredHeight: 112
            Layout.alignment: Qt.AlignVCenter
            source: isle.hasMusic ? isle.player.artUrl : ""
            radius: 14
            color: "#2c2c2e"
            fillMode: Image.PreserveAspectCrop
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 4

            RowLayout {
                spacing: 14
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1
                    Text {
                        Layout.fillWidth: true
                        text: isle.hasMusic ? isle.player.track : ""
                        elide: Text.ElideRight
                        color: "white"
                        font { family: isle.font; pixelSize: 17; weight: Font.DemiBold; letterSpacing: -0.2 }
                    }
                    Text {
                        Layout.fillWidth: true
                        text: isle.hasMusic ? (isle.player.artist || isle.player.identity) : ""
                        elide: Text.ElideRight
                        color: isle.dim
                        font { family: isle.font; pixelSize: 13 }
                    }
                }
                Bars { barHeight: 18; playing: isle.playing && isle.mode === "open" && isle.page === "music" }
            }

            // progress
            RowLayout {
                Layout.topMargin: 6
                spacing: 10
                readonly property real len: isle.hasMusic ? isle.player.length / 1e6 : 0
                readonly property real pos: isle.hasMusic ? isle.player.position / 1e6 : 0
                Text {
                    text: isle.mmss(parent.pos)
                    color: isle.dim
                    font { family: isle.font; pixelSize: 11; weight: Font.DemiBold }
                    font.features: { "tnum": 1 }
                }
                Rectangle {
                    Layout.fillWidth: true
                    height: 4
                    radius: 2
                    color: Qt.rgba(1, 1, 1, 0.2)
                    Rectangle {
                        height: parent.height
                        radius: 2
                        color: "white"
                        width: parent.parent.len > 0 ? parent.width * Math.min(1, parent.parent.pos / parent.parent.len) : 0
                    }
                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -6
                        enabled: isle.hasMusic && isle.player.canSeek
                        onClicked: mouse => isle.player.position = Math.max(0, Math.min(1, (mouse.x - 6) / parent.width)) * isle.player.length
                    }
                }
                Text {
                    text: parent.len > 0 ? "-" + isle.mmss(parent.len - parent.pos) : ""
                    color: isle.dim
                    font { family: isle.font; pixelSize: 11; weight: Font.DemiBold }
                    font.features: { "tnum": 1 }
                }
            }

            // controls
            Row {
                Layout.alignment: Qt.AlignHCenter
                spacing: 18
                IsleButton { glyph: "\u{F04AE}"; glyphSize: 20; onClicked: isle.player.Previous() }
                IsleButton { glyph: isle.playing ? "\u{F03E4}" : "\u{F040A}"; glyphSize: 24; onClicked: isle.player.PlayPause() }
                IsleButton { glyph: "\u{F04AD}"; glyphSize: 20; onClicked: isle.player.Next() }
            }
        }
    }
}
