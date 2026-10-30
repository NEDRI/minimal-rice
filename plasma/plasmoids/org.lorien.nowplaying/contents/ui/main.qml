import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami
import org.kde.plasma.private.mpris as Mpris

PlasmoidItem {
    id: root

    readonly property var player: mpris.currentPlayer
    readonly property bool active: player !== null && player.track !== ""
        && player.playbackStatus !== Mpris.PlaybackStatus.Stopped
    readonly property bool playing: active && player.playbackStatus === Mpris.PlaybackStatus.Playing

    preferredRepresentation: fullRepresentation
    toolTipMainText: active ? player.track : "Nic teraz nie gra"
    toolTipSubText: active ? player.artist : ""

    Mpris.Mpris2Model {
        id: mpris
    }

    // MPRIS only reports the position on demand, so poll it while playing
    Timer {
        interval: 1000
        repeat: true
        running: root.playing
        onTriggered: root.player.updatePosition()
    }

    fullRepresentation: Item {
        Layout.minimumWidth: Kirigami.Units.gridUnit * 5
        Layout.minimumHeight: Kirigami.Units.gridUnit * 4
        Layout.preferredWidth: Kirigami.Units.gridUnit * 20
        Layout.preferredHeight: Kirigami.Units.gridUnit * 7

        // nothing playing: a quiet placeholder instead of a big stop icon
        RowLayout {
            anchors.centerIn: parent
            visible: !root.active
            spacing: Kirigami.Units.largeSpacing

            PlasmaComponents.Label {
                text: "\u{F075A}" // nf-md-music_note
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: Kirigami.Units.iconSizes.large
                color: Kirigami.Theme.highlightColor
                opacity: 0.8
            }
            ColumnLayout {
                spacing: 0
                PlasmaComponents.Label {
                    text: "Nic teraz nie gra"
                    font.bold: true
                }
                PlasmaComponents.Label {
                    text: "Włącz muzykę, a pojawi się tutaj"
                    opacity: 0.5
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                }
            }
        }

        RowLayout {
            anchors.fill: parent
            visible: root.active
            spacing: Kirigami.Units.largeSpacing

            Kirigami.ShadowedImage {
                Layout.fillHeight: true
                Layout.preferredWidth: height
                source: root.active ? root.player.artUrl : ""
                fillMode: Image.PreserveAspectCrop
                radius: Kirigami.Units.cornerRadius * 2
                color: Qt.rgba(1, 1, 1, 0.06)

                PlasmaComponents.Label {
                    anchors.centerIn: parent
                    visible: parent.status !== Image.Ready
                    text: "\u{F075A}"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: Kirigami.Units.iconSizes.large
                    color: Kirigami.Theme.highlightColor
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.player.Raise()
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: Kirigami.Units.smallSpacing

                Item { Layout.fillHeight: true }
                PlasmaComponents.Label {
                    Layout.fillWidth: true
                    text: root.active ? root.player.track : ""
                    font.bold: true
                    elide: Text.ElideRight
                }
                PlasmaComponents.Label {
                    Layout.fillWidth: true
                    text: root.active ? root.player.artist : ""
                    color: Kirigami.Theme.highlightColor
                    elide: Text.ElideRight
                }

                // progress
                Rectangle {
                    Layout.fillWidth: true
                    Layout.topMargin: Kirigami.Units.smallSpacing
                    implicitHeight: 3
                    radius: 1.5
                    color: Qt.rgba(1, 1, 1, 0.12)
                    visible: root.active && root.player.length > 0

                    Rectangle {
                        height: parent.height
                        radius: parent.radius
                        color: Kirigami.Theme.highlightColor
                        width: root.active && root.player.length > 0
                            ? parent.width * Math.min(1, root.player.position / root.player.length) : 0
                    }
                }

                RowLayout {
                    spacing: 0
                    PlasmaComponents.ToolButton {
                        icon.name: "media-skip-backward"
                        enabled: root.active && root.player.canGoPrevious
                        onClicked: root.player.Previous()
                    }
                    PlasmaComponents.ToolButton {
                        icon.name: root.playing ? "media-playback-pause" : "media-playback-start"
                        enabled: root.active && root.player.canControl
                        onClicked: root.player.PlayPause()
                    }
                    PlasmaComponents.ToolButton {
                        icon.name: "media-skip-forward"
                        enabled: root.active && root.player.canGoNext
                        onClicked: root.player.Next()
                    }
                }
                Item { Layout.fillHeight: true }
            }
        }
    }
}
