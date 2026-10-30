import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.plasma5support as Plasma5Support
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    // UPower data for the laptop battery, the AC adapter and other battery devices (e.g. a headset)
    property var bat: ({})
    property bool acOnline: false
    property var extras: []

    readonly property real percent: Number(bat.percentage || 0)
    readonly property real energy: Number(bat.energy || 0)
    readonly property real energyFull: Number(bat["energy-full"] || 0)
    readonly property real energyDesign: Number(bat["energy-full-design"] || 0)
    readonly property real rate: Number(bat["energy-rate"] || 0)
    readonly property real limit: Number(bat["charge-end-threshold"] || 100)
    readonly property string state: bat.state || ""
    readonly property bool charging: state === "charging"
    readonly property string watts: rate.toFixed(1).replace(".", ",") + " W"
    readonly property string timeLeft: {
        if (rate <= 0.1) return "";
        const hours = charging ? Math.max(0, energyFull * limit / 100 - energy) / rate
            : state === "discharging" ? energy / rate : 0;
        if (hours <= 0) return "";
        const h = Math.floor(hours), m = Math.round((hours - h) * 60);
        return h + ":" + String(m).padStart(2, "0");
    }
    // one short line in the corner; the rest goes in the tooltip
    readonly property string aside: {
        switch (state) {
        case "charging": return "+" + watts + (timeLeft ? "  " + timeLeft : "");
        case "discharging": return timeLeft || "−" + watts;
        case "fully-charged": return "pełna";
        case "pending-charge": return "limit " + limit + "%";
        default: return "";
        }
    }

    preferredRepresentation: fullRepresentation
    toolTipMainText: "Bateria " + Math.round(percent) + "%"
    toolTipSubText: [
        { charging: "ładowanie " + watts, discharging: "na baterii, pobór " + watts, "fully-charged": "naładowana",
          "pending-charge": "na zasilaczu, ładowanie do " + limit + "%" }[state] || "",
        timeLeft ? (charging ? "do pełna " : "zostało ") + timeLeft : "",
        energyDesign > 0 ? "kondycja " + Math.round(energyFull / energyDesign * 100) + "%" : "",
    ].concat(extras.map(e => e.name + " " + e.percent + "%")).filter(s => s).join("\n")

    function parse(text) {
        let b = {}, ac = false, ex = [];
        for (const block of text.split(/\n(?=Device: )/)) {
            const kv = {};
            let kind = "";
            const head = block.split("\n")[0];
            for (const line of block.split("\n")) {
                const k = line.match(/^  (\S[^:]*)$/);   // the kind line, e.g. "  battery"
                if (k) kind = k[1];
                const m = line.match(/^ {2,4}([a-z][a-z -]*):\s+(.*)$/);
                if (m) kv[m[1].trim()] = m[2].replace(/^'|'$/g, "").replace(/\s*(Wh|W|V|%)$/, "").trim();
            }
            if (/battery_BAT/.test(head)) b = kv;
            else if (kind === "line-power") ac = kv.online === "yes";
            else if (kv.percentage !== undefined && !/missing/.test(kv["icon-name"] || "")
                     && kind !== "battery" && !/DisplayDevice/.test(head))
                ex.push({ name: kv.model || kind, percent: Number(kv.percentage) });
        }
        root.bat = b;
        root.acOnline = ac;
        root.extras = ex;
    }

    Plasma5Support.DataSource {
        id: exec
        engine: "executable"
        onNewData: (source, data) => {
            disconnectSource(source);
            root.parse(data["stdout"]);
        }
    }

    Timer {
        interval: 10000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: exec.connectSource("LC_ALL=C upower -d")
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
                Caption { text: "bateria" }
                Caption {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignRight
                    elide: Text.ElideRight
                    text: root.aside
                    color: root.charging ? Kirigami.Theme.highlightColor : Kirigami.Theme.textColor
                    opacity: root.charging ? 1 : 0.5
                }
            }
            Item { Layout.fillHeight: true }
            RowLayout {
                spacing: 2
                PlasmaComponents.Label {
                    text: Math.round(root.percent)
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
                    width: parent.width * root.percent / 100
                    color: root.percent <= 15 && !root.acOnline ? "#df7a9b" : Kirigami.Theme.highlightColor
                }
            }
        }
    }
}
