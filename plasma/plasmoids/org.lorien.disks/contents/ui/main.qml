import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami
import org.kde.ksysguard.sensors as Sensors

PlasmoidItem {
    id: root

    readonly property real usedPercent: Number(usedPct.value) || 0

    preferredRepresentation: fullRepresentation
    toolTipMainText: "Disk / " + Math.round(usedPercent) + "% used"
    toolTipSubText: (used.formattedValue || "") + " of " + (total.formattedValue || "")
        + "\nread " + (rd.formattedValue || "–") + ", write " + (wr.formattedValue || "–")

    Sensors.Sensor { id: used; sensorId: "disk/all/used"; updateRateLimit: 10000 }
    Sensors.Sensor { id: total; sensorId: "disk/all/total"; updateRateLimit: 60000 }
    Sensors.Sensor { id: free; sensorId: "disk/all/free"; updateRateLimit: 10000 }
    Sensors.Sensor { id: usedPct; sensorId: "disk/all/usedPercent"; updateRateLimit: 10000 }
    Sensors.Sensor { id: rd; sensorId: "disk/all/read"; updateRateLimit: 2000 }
    Sensors.Sensor { id: wr; sensorId: "disk/all/write"; updateRateLimit: 2000 }

    component Caption: PlasmaComponents.Label {
        font.family: "JetBrainsMono Nerd Font"
        font.pointSize: Kirigami.Theme.smallFont.pointSize
        opacity: 0.5
    }

    fullRepresentation: Item {
        Layout.minimumWidth: Kirigami.Units.gridUnit * 5
        Layout.minimumHeight: Kirigami.Units.gridUnit * 4
        Layout.preferredWidth: Kirigami.Units.gridUnit * 20
        Layout.preferredHeight: Kirigami.Units.gridUnit * 10

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Kirigami.Units.smallSpacing
            spacing: Kirigami.Units.smallSpacing

            RowLayout {
                Caption { text: "disk" }
                Caption {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignRight
                    elide: Text.ElideRight
                    text: (free.formattedValue || "–") + " free"
                }
            }
            Item { Layout.fillHeight: true }
            RowLayout {
                spacing: 2
                PlasmaComponents.Label {
                    text: Math.round(root.usedPercent)
                    font.family: "JetBrainsMono Nerd Font"
                    font.weight: Font.Bold
                    font.pixelSize: Kirigami.Units.gridUnit * 2
                }
                Caption {
                    Layout.alignment: Qt.AlignBaseline
                    text: "%"
                }
            }
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 4
                radius: 2
                color: Qt.rgba(1, 1, 1, 0.08)
                Rectangle {
                    height: parent.height
                    radius: parent.radius
                    width: parent.width * root.usedPercent / 100
                    color: root.usedPercent >= 90 ? "#df7a9b" : Kirigami.Theme.highlightColor
                }
            }
        }
    }
}
