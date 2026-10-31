// The Music page, as Isle's pages/media.js: cover on the left; title, artist, scrubber and controls beside
// it, with lyrics and output as small buttons at the right. Lyrics widen the island to 720 px with the
// player in a column beside synced lines; output shows the volume and the outputs to choose from.
// Music and lyrics come from isled; volume and outputs from Plasma's PulseAudio module.
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.private.volume

Item {
    id: comp
    property var isle
    readonly property var np: isle.nowPlaying
    readonly property string mode: isle.musicMode     // player | lyrics | audio

    function toggle(m) { isle.musicMode = isle.musicMode === m ? "player" : m; }

    // ---------------------------------------------------------------- pieces shared by the layouts
    component Texts: ColumnLayout {
        property int titleSize: 17
        property int titleWeight: Font.DemiBold
        property int artistSize: 13
        property real artistOpacity: 0.55
        spacing: 1
        Text {
            Layout.fillWidth: true
            text: comp.np ? comp.np.title : ""
            elide: Text.ElideRight
            color: "white"
            font { family: isle.font; pixelSize: parent.titleSize; weight: parent.titleWeight; letterSpacing: -0.2 }
        }
        Text {
            Layout.fillWidth: true
            text: comp.np ? (comp.np.artist || comp.np.identity || "") : ""
            elide: Text.ElideRight
            color: Qt.rgba(1, 1, 1, parent.artistOpacity)
            font { family: isle.font; pixelSize: parent.artistSize }
        }
    }
    component Progress: RowLayout {
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
    component Transport: Row {
        property int gap: 20
        spacing: gap
        IsleButton { anchors.verticalCenter: parent.verticalCenter; icon: "isle-backward-symbolic"; iconSize: 18
                     onClicked: isle.daemon.call("Media1", "Previous") }
        IsleButton { anchors.verticalCenter: parent.verticalCenter; icon: isle.playing ? "isle-pause-symbolic" : "isle-play-symbolic"; iconSize: 22
                     onClicked: isle.daemon.call("Media1", "PlayPause") }
        IsleButton { anchors.verticalCenter: parent.verticalCenter; icon: "isle-forward-symbolic"; iconSize: 18
                     onClicked: isle.daemon.call("Media1", "Next") }
    }
    // lit while its mode is shown, its icon filled in
    component ModeButton: IsleButton {
        property string forMode: ""
        readonly property bool on: comp.mode === forMode
        icon: (forMode === "lyrics" ? "isle-lyrics" : "isle-output") + (on ? "-fill" : "")
        iconSize: 18
        opacity: on ? 1 : 0.75
        lit: on
        onClicked: comp.toggle(forMode)
    }

    // ---------------------------------------------------------------- nothing playing
    Column {
        anchors.centerIn: parent
        visible: !isle.hasTrack && comp.mode !== "audio"
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

    // ---------------------------------------------------------------- the player
    RowLayout {
        anchors.fill: parent
        visible: isle.hasTrack && comp.mode === "player"
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

            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                Texts { Layout.fillWidth: true; Layout.alignment: Qt.AlignTop }
                Row {
                    Layout.alignment: Qt.AlignTop
                    Layout.rightMargin: -5
                    spacing: 2
                    ModeButton { forMode: "lyrics" }
                    ModeButton { forMode: "audio" }
                }
            }
            Progress { Layout.fillWidth: true; Layout.topMargin: 6 }
            Transport { Layout.alignment: Qt.AlignHCenter }
        }
    }

    // ---------------------------------------------------------------- lyrics: the player in a column beside the words
    RowLayout {
        anchors.fill: parent
        visible: isle.hasTrack && comp.mode === "lyrics"
        spacing: 26

        ColumnLayout {
            Layout.preferredWidth: 232
            Layout.maximumWidth: 232
            Layout.alignment: Qt.AlignVCenter
            spacing: 8
            RowLayout {
                spacing: 12
                Art { size: 64; radius: 12; source: isle.artUrl }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    Texts { Layout.fillWidth: true; titleSize: 15; titleWeight: Font.Bold; artistSize: 12; artistOpacity: 0.6 }
                    Bars { Layout.topMargin: 5; barHeight: 11; playing: isle.playing && comp.visible }
                }
            }
            Progress { Layout.fillWidth: true; Layout.topMargin: 2 }
            RowLayout {
                Layout.fillWidth: true
                spacing: 4
                ModeButton { forMode: "lyrics" }
                Item {
                    Layout.fillWidth: true
                    implicitHeight: transport.height
                    Transport { id: transport; gap: 14; anchors.centerIn: parent }
                }
                ModeButton { forMode: "audio" }
            }
        }
        LyricsPane { isle: comp.isle; Layout.fillWidth: true; Layout.fillHeight: true }
    }

    // ---------------------------------------------------------------- volume, then the outputs to choose from
    readonly property var sink: PreferredDevice.sink
    readonly property real volume: sink ? sink.volume / 65536 : 0
    ColumnLayout {
        anchors.fill: parent
        visible: comp.mode === "audio"
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            spacing: 10
            IsleButton {
                iconSize: 18
                icon: !comp.sink || comp.sink.muted || comp.volume <= 0 ? "isle-speaker-off-symbolic"
                    : comp.volume < 0.34 ? "isle-speaker-1-symbolic" : comp.volume < 0.67 ? "isle-speaker-2-symbolic" : "isle-speaker-3-symbolic"
                onClicked: if (comp.sink) comp.sink.muted = !comp.sink.muted
            }
            Slider {
                Layout.fillWidth: true
                value: comp.sink && !comp.sink.muted ? Math.min(1, comp.volume) : 0
                onReleased: fraction => { if (comp.sink) { comp.sink.muted = false; comp.sink.volume = Math.round(fraction * 65536); } }
            }
            Text {
                Layout.minimumWidth: 46
                horizontalAlignment: Text.AlignRight
                text: !comp.sink ? "" : comp.sink.muted ? "Muted" : Math.round(comp.volume * 100) + "%"
                color: Qt.rgba(1, 1, 1, 0.85)
                font { family: isle.font; pixelSize: 12; weight: Font.DemiBold }
                font.features: { "tnum": 1 }
            }
            ModeButton { forMode: "audio" }
        }

        ListView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 4
            model: SinkModel {}
            delegate: Rectangle {
                id: output
                required property var model
                width: ListView.view.width
                height: rowItem.implicitHeight + 12
                radius: 12
                color: model.Default || area.containsMouse ? "#1c1c1e" : "transparent"
                RowLayout {
                    id: rowItem
                    anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; leftMargin: 12; rightMargin: 12 }
                    spacing: 12
                    IsleIcon { name: "isle-speaker-device-symbolic"; size: 18 }
                    Text {
                        Layout.fillWidth: true
                        text: output.model.Description
                        elide: Text.ElideRight
                        color: "white"
                        font { family: isle.font; pixelSize: 13; weight: Font.DemiBold }
                    }
                    IsleIcon { name: "isle-check-symbolic"; size: 14; opacity: output.model.Default ? 1 : 0 }
                }
                MouseArea {
                    id: area
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: output.model.PulseObject.default = true
                }
            }
        }
    }
}
