import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami
import org.kde.ksysguard.sensors as Sensors

PlasmoidItem {
    id: root

    readonly property int samples: 60
    property var history: []

    preferredRepresentation: fullRepresentation
    toolTipMainText: "System"
    toolTipSubText: "CPU " + Math.round(Number(cpu.value) || 0) + "%, RAM " + (ramUsed.formattedValue || "–")
        + " of " + (ramTotal.formattedValue || "–") + "\nCPU temperature " + Math.round(Number(temp.value) || 0) + " °C"

    Sensors.Sensor { id: cpu; sensorId: "cpu/all/usage"; updateRateLimit: 1000 }
    Sensors.Sensor { id: ram; sensorId: "memory/physical/usedPercent"; updateRateLimit: 2000 }
    Sensors.Sensor { id: ramUsed; sensorId: "memory/physical/used"; updateRateLimit: 2000 }
    Sensors.Sensor { id: ramTotal; sensorId: "memory/physical/total"; updateRateLimit: 60000 }
    Sensors.Sensor { id: temp; sensorId: "cpu/all/maximumTemperature"; updateRateLimit: 2000 }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.history = root.history.concat([Number(cpu.value) || 0]).slice(-root.samples)
    }

    component Caption: PlasmaComponents.Label {
        font.family: "JetBrainsMono Nerd Font"
        font.pointSize: Kirigami.Theme.smallFont.pointSize
        opacity: 0.5
    }
    // shrinks to fit when the tile is narrow
    component Value: PlasmaComponents.Label {
        Layout.fillWidth: true
        font.family: "JetBrainsMono Nerd Font"
        font.weight: Font.Bold
        font.pixelSize: Kirigami.Units.gridUnit * 1.6
        fontSizeMode: Text.HorizontalFit
        minimumPixelSize: Kirigami.Units.gridUnit * 0.7
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
                Caption { text: "cpu" }
                Item { Layout.fillWidth: true }
                Caption { text: "ram " + Math.round(Number(ram.value) || 0) + "%" }
            }

            // CPU load over the last minute, a bare line on a fixed 0-100 % scale
            Canvas {
                id: graph
                Layout.fillWidth: true
                Layout.fillHeight: true
                renderStrategy: Canvas.Cooperative
                onPaint: {
                    const ctx = getContext("2d");
                    ctx.reset();
                    const data = root.history;
                    if (data.length < 2) return;
                    const step = width / (root.samples - 1), x0 = width - (data.length - 1) * step;
                    ctx.beginPath();
                    data.forEach((v, i) => {
                        const x = x0 + i * step, y = height - 1 - (height - 2) * Math.min(v, 100) / 100;
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
                    function onHistoryChanged() { graph.requestPaint() }
                }
            }

            Value { text: Math.round(Number(cpu.value) || 0) + "%" }
        }
    }
}
