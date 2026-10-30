import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami
import org.kde.ksysguard.sensors as Sensors

PlasmoidItem {
    id: root

    readonly property int decimals: Plasmoid.configuration.decimals
    readonly property bool percent: Plasmoid.configuration.unit === "percent"
    readonly property string load: sensor.value === undefined ? "--"
        : percent ? Number(sensor.value).toFixed(decimals) + "%" : sensor.formattedValue

    preferredRepresentation: fullRepresentation
    toolTipMainText: Plasmoid.configuration.title
    toolTipSubText: load

    Sensors.Sensor {
        id: sensor
        sensorId: Plasmoid.configuration.sensorId
        updateRateLimit: 1500
    }

    fullRepresentation: Item {
        readonly property int padding: Kirigami.Units.smallSpacing * 2

        Layout.minimumWidth: row.implicitWidth + padding * 2
        Layout.preferredWidth: Layout.minimumWidth
        Layout.maximumWidth: Layout.minimumWidth
        Layout.fillHeight: true

        RowLayout {
            id: row
            anchors.verticalCenter: parent.verticalCenter
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Kirigami.Units.smallSpacing

            PlasmaComponents.Label {
                text: Plasmoid.configuration.icon
                color: Kirigami.Theme.highlightColor
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: Kirigami.Units.iconSizes.small
            }
            PlasmaComponents.Label {
                id: label
                text: root.load
                font.family: "JetBrainsMono Nerd Font"
                font.bold: true
                horizontalAlignment: Text.AlignRight
                Layout.minimumWidth: metrics.width

                TextMetrics {
                    id: metrics
                    font: label.font
                    text: !root.percent ? "000,0 KiB/s" : root.decimals > 0 ? "00." + "0".repeat(root.decimals) + "%" : "00%"
                }
            }
        }
    }
}
