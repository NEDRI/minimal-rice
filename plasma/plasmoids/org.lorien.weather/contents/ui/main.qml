import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.plasma5support as Plasma5Support
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    // a BBC Weather station, set by install.sh from the city the user gives it
    readonly property string station: Plasmoid.configuration.station
    readonly property var wx: weather.data[station] || {}
    readonly property bool ready: wx["Temperature"] !== undefined
    // "Short Forecast Day N" = "day|icon|condition|high|low|precipitation"; day 0 is the rest of today
    readonly property var forecast: [1, 2, 3].map(i => (wx["Short Forecast Day " + i] || "").split("|"))
        .filter(f => f.length >= 5)

    preferredRepresentation: fullRepresentation
    toolTipMainText: wx["Place"] || "Pogoda"
    toolTipSubText: ready ? [
        wx["Current Conditions"] + ", " + Math.round(wx["Temperature"]) + " °C",
        "wilgotność " + wx["Humidity"] + "%",
        "wiatr " + wx["Wind Speed"] + " km/h " + (wx["Wind Direction"] || ""),
        "ciśnienie " + wx["Pressure"] + " hPa",
        wx["Credit"] || "",
    ].join("\n") : "Ładuję pogodę…"

    Plasma5Support.DataSource {
        id: weather
        engine: "weather"
        connectedSources: [root.station]
        interval: 30 * 60 * 1000
    }

    component Caption: PlasmaComponents.Label {
        font.family: "JetBrainsMono Nerd Font"
        font.pointSize: Kirigami.Theme.smallFont.pointSize
        opacity: 0.5
    }

    fullRepresentation: Item {
        Layout.minimumWidth: Kirigami.Units.gridUnit * 5
        Layout.minimumHeight: Kirigami.Units.gridUnit * 4
        Layout.preferredWidth: Kirigami.Units.gridUnit * 14
        Layout.preferredHeight: Kirigami.Units.gridUnit * 9

        MouseArea {
            anchors.fill: parent
            enabled: !!root.wx["Credit Url"]
            cursorShape: Qt.PointingHandCursor
            onClicked: Qt.openUrlExternally(root.wx["Credit Url"])
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Kirigami.Units.smallSpacing
            spacing: Kirigami.Units.smallSpacing

            RowLayout {
                Caption { text: (root.wx["Station"] || "pogoda").toLowerCase() }
                Caption {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignRight
                    elide: Text.ElideRight
                    text: (root.wx["Current Conditions"] || "").toLowerCase()
                }
            }

            RowLayout {
                Layout.fillHeight: true
                PlasmaComponents.Label {
                    Layout.fillWidth: true
                    text: root.ready ? Math.round(root.wx["Temperature"]) + "°" : "…"
                    font.family: "JetBrainsMono Nerd Font"
                    font.weight: Font.Bold
                    font.pixelSize: Kirigami.Units.gridUnit * 2
                }
                Kirigami.Icon {
                    Layout.preferredWidth: Kirigami.Units.iconSizes.medium
                    Layout.preferredHeight: Kirigami.Units.iconSizes.medium
                    source: root.wx["Condition Icon"] || "weather-none-available"
                    isMask: true
                    color: Kirigami.Theme.highlightColor
                }
            }

            // the next three days: name, then high / low
            RowLayout {
                visible: root.forecast.length > 0
                spacing: Kirigami.Units.smallSpacing
                Repeater {
                    model: root.forecast
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        Caption { text: modelData[0].replace(".", "") }
                        PlasmaComponents.Label {
                            text: (modelData[3] !== "" ? modelData[3] + "°" : "") + (modelData[4] !== "" ? "/" + modelData[4] + "°" : "")
                            font.family: "JetBrainsMono Nerd Font"
                            font.pointSize: Kirigami.Theme.smallFont.pointSize
                            opacity: 0.8
                        }
                    }
                }
            }
        }
    }
}
