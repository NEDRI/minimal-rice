// The Music page, as Isle's pages/media.js: cover on the left; title, artist, scrubber and controls
// beside it. Everything comes from isled, which follows the active MPRIS player.
import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Item {
    id: comp
    property var isle
    readonly property var np: isle.nowPlaying

    // nothing playing: Isle's empty state
    Column {
        anchors.centerIn: parent
        visible: !isle.hasTrack
        spacing: 4
        IsleIcon { anchors.horizontalCenter: parent.horizontalCenter; name: "isle-music"; size: 28; opacity: 0.35 }
        Item { width: 1; height: 4 }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Nothing playing"
            color: "white"
            font { family: isle.font; pixelSize: 15; weight: Font.DemiBold; letterSpacing: -0.1 }
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Play something in Spotify or on YouTube"
            color: Qt.rgba(1, 1, 1, 0.5)
            font { family: isle.font; pixelSize: 12 }
        }
    }

    RowLayout {
        anchors.fill: parent
        visible: isle.hasTrack
        spacing: 20

        Art {
            Layout.preferredWidth: 104
            Layout.preferredHeight: 104
            Layout.alignment: Qt.AlignVCenter
            size: 104
            radius: 16
            source: isle.artUrl
            IsleIcon { anchors.centerIn: parent; name: "isle-music"; size: 32; opacity: 0.4; visible: !isle.artUrl }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 4

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1
                Text {
                    Layout.fillWidth: true
                    text: comp.np ? comp.np.title : ""
                    elide: Text.ElideRight
                    color: "white"
                    font { family: isle.font; pixelSize: 17; weight: Font.DemiBold; letterSpacing: -0.2 }
                }
                Text {
                    Layout.fillWidth: true
                    text: comp.np ? (comp.np.artist || comp.np.identity || "") : ""
                    elide: Text.ElideRight
                    color: Qt.rgba(1, 1, 1, 0.55)
                    font { family: isle.font; pixelSize: 13 }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 6
                spacing: 10
                Text {
                    Layout.minimumWidth: 34
                    text: isle.mmss(isle.positionMs / 1000)
                    color: Qt.rgba(1, 1, 1, 0.6)
                    font { family: isle.font; pixelSize: 12; weight: Font.Medium }
                    font.features: { "tnum": 1 }
                }
                Slider {
                    Layout.fillWidth: true
                    value: isle.lengthMs > 0 ? isle.positionMs / isle.lengthMs : 0
                    onReleased: fraction => {
                        if (comp.np && comp.np.length_us > 0)
                            isle.daemon.call("Media1", "SetPosition", [Math.round(fraction * comp.np.length_us)], "x");
                    }
                }
                Text {
                    Layout.minimumWidth: 34
                    horizontalAlignment: Text.AlignRight
                    text: "−" + isle.mmss(Math.max(0, isle.lengthMs - isle.positionMs) / 1000)
                    color: Qt.rgba(1, 1, 1, 0.6)
                    font { family: isle.font; pixelSize: 12; weight: Font.Medium }
                    font.features: { "tnum": 1 }
                }
            }

            Row {
                Layout.alignment: Qt.AlignHCenter
                spacing: 20
                IsleButton { anchors.verticalCenter: parent.verticalCenter; icon: "isle-backward-symbolic"; iconSize: 18
                             onClicked: isle.daemon.call("Media1", "Previous") }
                IsleButton { anchors.verticalCenter: parent.verticalCenter; icon: isle.playing ? "isle-pause-symbolic" : "isle-play-symbolic"; iconSize: 22
                             onClicked: isle.daemon.call("Media1", "PlayPause") }
                IsleButton { anchors.verticalCenter: parent.verticalCenter; icon: "isle-forward-symbolic"; iconSize: 18
                             onClicked: isle.daemon.call("Media1", "Next") }
            }
        }
    }
}
