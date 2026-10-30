import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    property date now: new Date()

    preferredRepresentation: fullRepresentation
    toolTipMainText: Qt.formatDate(now, "dddd, d MMMM")

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.now = new Date()
    }

    fullRepresentation: Item {
        Layout.minimumWidth: Kirigami.Units.gridUnit * 5
        Layout.minimumHeight: Kirigami.Units.gridUnit * 4
        Layout.preferredWidth: Kirigami.Units.gridUnit * 9
        Layout.preferredHeight: Kirigami.Units.gridUnit * 9

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 0

            PlasmaComponents.Label {
                Layout.alignment: Qt.AlignHCenter
                text: Qt.formatTime(root.now, "HH:mm")
                font.family: "JetBrainsMono Nerd Font"
                font.weight: Font.Bold
                // fit both a square tile and a wide, low one
                font.pixelSize: Math.round(Math.min(parent.parent.width * 0.27, parent.parent.height * 0.5))
            }
            PlasmaComponents.Label {
                Layout.alignment: Qt.AlignHCenter
                text: Qt.formatDate(root.now, "ddd d MMM")
                font.family: "JetBrainsMono Nerd Font"
                color: Kirigami.Theme.highlightColor
            }
        }
    }
}
