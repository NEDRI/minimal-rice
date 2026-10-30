import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami
import org.kde.ksysguard.sensors as Sensors

PlasmoidItem {
    id: root

    readonly property string iface: "wlan0"
    readonly property int samples: 60
    property var down: []

    preferredRepresentation: fullRepresentation
    toolTipMainText: ssid.value || "Sieć"
    toolTipSubText: ["↓ " + (dl.formattedValue || "–") + "   ↑ " + (ul.formattedValue || "–"),
                     ip.value ? "IP " + ip.value : "",
                     signal.value !== undefined ? "sygnał " + Math.round(Number(signal.value) || 0) + "%" : "",
                     totalDl.formattedValue ? "od startu pobrano " + totalDl.formattedValue : ""].filter(s => s).join("\n")

    Sensors.Sensor { id: ssid; sensorId: "network/" + root.iface + "/network" }
    Sensors.Sensor { id: ip; sensorId: "network/" + root.iface + "/ipv4address" }
    Sensors.Sensor { id: signal; sensorId: "network/" + root.iface + "/signal" }
    Sensors.Sensor { id: dl; sensorId: "network/all/download"; updateRateLimit: 1000 }
    Sensors.Sensor { id: ul; sensorId: "network/all/upload"; updateRateLimit: 1000 }
    Sensors.Sensor { id: totalDl; sensorId: "network/all/totalDownload" }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.down = root.down.concat([Number(dl.value) || 0]).slice(-root.samples)
    }

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
                Caption { text: "sieć" }
                Caption {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignRight
                    text: ssid.value || "offline"
                    elide: Text.ElideRight
                }
            }

            // download over the last minute, a bare line
            Canvas {
                id: graph
                Layout.fillWidth: true
                Layout.fillHeight: true
                renderStrategy: Canvas.Cooperative
                onPaint: {
                    const ctx = getContext("2d");
                    ctx.reset();
                    const data = root.down;
                    if (data.length < 2) return;
                    const max = Math.max(64 * 1024, ...data) * 1.1;
                    const step = width / (root.samples - 1), x0 = width - (data.length - 1) * step;
                    ctx.beginPath();
                    data.forEach((v, i) => {
                        const x = x0 + i * step, y = height - 1 - (height - 2) * v / max;
                        i ? ctx.lineTo(x, y) : ctx.moveTo(x, y);
                    });
                    ctx.strokeStyle = Kirigami.Theme.highlightColor;
                    ctx.globalAlpha = 0.7;
                    ctx.lineWidth = 1.5;
                    ctx.lineJoin = "round";
                    ctx.stroke();
                }
                Connections {
                    target: root
                    function onDownChanged() { graph.requestPaint() }
                }
            }

            // download only; upload is in the tooltip
            PlasmaComponents.Label {
                Layout.fillWidth: true
                text: dl.formattedValue || "–"
                font.family: "JetBrainsMono Nerd Font"
                font.weight: Font.Bold
                font.pixelSize: Kirigami.Units.gridUnit * 1.6
                fontSizeMode: Text.HorizontalFit
                minimumPixelSize: Kirigami.Units.gridUnit * 0.7
            }
        }
    }
}
