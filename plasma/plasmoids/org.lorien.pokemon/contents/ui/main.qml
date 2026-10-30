import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.plasma5support as Plasma5Support
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    readonly property string script: "python3 -I $HOME/.local/share/lorien-rice/pokemon-day.py"
    property var mon: null
    property string day: ""

    preferredRepresentation: fullRepresentation
    toolTipMainText: mon ? mon.name + "  #" + String(mon.id).padStart(3, "0") + (mon.shiny ? "  ✦ shiny" : "") : "Pokémon dnia"
    toolTipSubText: "Kliknij, żeby wylosować innego"

    function load(arg) {
        exec.connectSource(script + (arg ? " " + arg : ""));
    }

    Plasma5Support.DataSource {
        id: exec
        engine: "executable"
        onNewData: (source, data) => {
            disconnectSource(source);
            try {
                root.mon = JSON.parse(data["stdout"]);
            } catch (e) {
                console.warn("lorien.pokemon:", data["stderr"]);
            }
        }
    }

    // a new Pokémon at midnight
    Timer {
        interval: 60000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            const today = new Date().toDateString();
            if (today !== root.day) {
                root.day = today;
                root.load("");
            }
        }
    }

    fullRepresentation: Item {
        Layout.minimumWidth: Kirigami.Units.gridUnit * 5
        Layout.minimumHeight: Kirigami.Units.gridUnit * 4
        Layout.preferredWidth: Kirigami.Units.gridUnit * 20
        Layout.preferredHeight: Kirigami.Units.gridUnit * 10

        // the sprite fills the tile, the name sits under it; the number is in the tooltip
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Kirigami.Units.smallSpacing
            spacing: 0

            Canvas {
                id: canvas
                Layout.fillWidth: true
                Layout.fillHeight: true
                renderStrategy: Canvas.Cooperative

                onPaint: {
                    const ctx = getContext("2d");
                    ctx.reset();
                    const m = root.mon;
                    if (!m) return;
                    const s = Math.max(1, Math.floor(Math.min(width / m.w, height / m.h)));
                    const ox = Math.floor((width - m.w * s) / 2);
                    const oy = Math.floor((height - m.h * s) / 2);
                    for (let y = 0; y < m.h; y++) {
                        for (let x = 0; x < m.w; x++) {
                            const c = m.px[y * m.w + x];
                            if (!c) continue;
                            ctx.fillStyle = c;
                            ctx.fillRect(ox + x * s, oy + y * s, s, s);
                        }
                    }
                }
                onWidthChanged: requestPaint()
                onHeightChanged: requestPaint()
                Connections {
                    target: root
                    function onMonChanged() { canvas.requestPaint() }
                }
            }

            PlasmaComponents.Label {
                Layout.fillWidth: true
                text: root.mon ? root.mon.name.toLowerCase() : "…"
                font.family: "JetBrainsMono Nerd Font"
                font.weight: Font.Bold
                font.pointSize: Kirigami.Theme.smallFont.pointSize
                color: root.mon && root.mon.shiny ? "#e8c3f0" : Kirigami.Theme.textColor
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.load("random")
        }
    }
}
