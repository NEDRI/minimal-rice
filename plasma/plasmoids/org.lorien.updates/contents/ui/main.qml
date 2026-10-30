import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.plasma5support as Plasma5Support
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    readonly property string rice: "$HOME/.local/share/lorien-rice/"
    readonly property string checkCmd: "sh " + rice + "updates.sh"
    readonly property string updateCmd: "konsole --hold -e $HOME/.local/bin/updateall"
    readonly property string rebuildCmd: "konsole --hold -e sh " + rice + "rebuild-corners.sh"
    // packages listed first: the ones that matter most after an update
    readonly property var important: /^(kwin|plasma-|kf6|qt6-base|linux|mesa|nvidia|systemd)/

    property var repo: []
    property var aur: []
    property bool failed: false
    property bool cornersBroken: false
    property bool checking: true
    property date checkedAt
    readonly property int total: repo.length + aur.length
    readonly property bool kwinPending: repo.some(p => /^kwin /.test(p))

    preferredRepresentation: fullRepresentation
    toolTipMainText: total > 0 ? total + " " + plural(total) + " to update" : "System up to date"
    toolTipSubText: repo.concat(aur).slice(0, 8).map(p => p.split(" ")[0] + " " + p.split(" ")[3]).join("\n")
        + (total > 8 ? "\n…" : "")
        + (cornersBroken ? "\n\nWindow borders are not working: click the red text to rebuild them."
           : kwinPending ? "\n\nKWin is in this update: rebuild the window borders afterwards." : "")
        + (checkedAt.getTime() ? "\n\nchecked at " + Qt.formatTime(checkedAt, "HH:mm") + ", click to update" : "")

    function plural(n) {
        return n === 1 ? "package" : "packages";
    }

    function check() {
        checking = true;
        exec.connectSource(checkCmd);
    }

    function parse(out) {
        const parts = out.split(/^@@(?=AUR|CORNERS)/m);
        const lines = s => (s || "").split("\n").map(l => l.trim()).filter(l => / -> /.test(l));
        const repoPart = parts[0] || "";
        root.failed = /@@ERROR/.test(repoPart);
        root.repo = lines(repoPart).sort((a, b) => important.test(b) - important.test(a));
        root.aur = lines((parts[1] || "").replace(/^AUR/, ""));
        const fx = (parts[2] || "").replace(/^CORNERS/, "").trim().split("\n");
        root.cornersBroken = fx[0] === "true" && fx[1] !== "true";
        root.checkedAt = new Date();
        root.checking = false;
    }

    Plasma5Support.DataSource {
        id: exec
        engine: "executable"
        onNewData: (source, data) => {
            disconnectSource(source);
            if (source === root.checkCmd) root.parse(data["stdout"]);
            else root.check();   // the update or rebuild Konsole was closed
        }
    }

    // first check a bit after login, so the network is up, then every 30 minutes
    Timer {
        interval: root.checkedAt.getTime() ? 30 * 60000 : 20000
        running: true
        repeat: true
        onTriggered: root.check()
    }

    Plasmoid.contextualActions: [
        PlasmaCore.Action {
            text: "Check now"
            icon.name: "view-refresh"
            onTriggered: root.check()
        }
    ]

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

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: exec.connectSource(root.updateCmd)
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Kirigami.Units.smallSpacing
            spacing: Kirigami.Units.smallSpacing

            RowLayout {
                Caption { text: "updates" }
                Item { Layout.fillWidth: true }
                Caption {
                    visible: root.cornersBroken || root.kwinPending
                    text: root.cornersBroken ? "rebuild borders" : "kwin: rebuild borders after"
                    color: "#df7a9b"
                    opacity: 1
                    MouseArea {
                        anchors.fill: parent
                        enabled: root.cornersBroken
                        cursorShape: Qt.PointingHandCursor
                        onClicked: exec.connectSource(root.rebuildCmd)
                    }
                }
            }
            Item { Layout.fillHeight: true }
            RowLayout {
                spacing: Kirigami.Units.smallSpacing
                PlasmaComponents.Label {
                    text: root.checking && !root.checkedAt.getTime() ? "…" : root.total
                    font.family: "JetBrainsMono Nerd Font"
                    font.weight: Font.Bold
                    font.pixelSize: Kirigami.Units.gridUnit * 2
                    color: root.total > 0 ? Kirigami.Theme.textColor : Kirigami.Theme.highlightColor
                }
                Caption {
                    Layout.alignment: Qt.AlignBaseline
                    text: root.checking && !root.checkedAt.getTime() ? "checking"
                        : root.failed && root.total === 0 ? "offline"
                        : root.total > 0 ? root.plural(root.total) : "up to date"
                }
            }
        }
    }
}
