import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.plasma5support as Plasma5Support
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    // Konsole profiles as [file, name], the default profile first
    readonly property string listCmd: "cd $HOME/.local/share/konsole && def=$(kreadconfig6 --file konsolerc --group 'Desktop Entry' --key DefaultProfile); "
        + "for f in *.profile; do printf '%s\\t%s\\t%s\\n' \"$([ \"$f\" = \"$def\" ] && echo 0 || echo 1)\" \"$f\" \"$(grep -m1 '^Name=' \"$f\" | cut -d= -f2-)\"; done | sort"
    property var profiles: []

    preferredRepresentation: fullRepresentation
    toolTipMainText: "Terminal"
    toolTipSubText: "Kliknij profil, żeby otworzyć Konsolę"

    Plasma5Support.DataSource {
        id: exec
        engine: "executable"
        onNewData: (source, data) => {
            disconnectSource(source);
            if (source === root.listCmd)
                root.profiles = data["stdout"].trim().split("\n").filter(l => l).map(l => l.split("\t").slice(1));
        }
    }

    Component.onCompleted: exec.connectSource(listCmd)

    fullRepresentation: Item {
        Layout.minimumWidth: Kirigami.Units.gridUnit * 5
        Layout.minimumHeight: Kirigami.Units.gridUnit * 4
        Layout.preferredWidth: Kirigami.Units.gridUnit * 20
        Layout.preferredHeight: Kirigami.Units.gridUnit * 10

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Kirigami.Units.smallSpacing
            spacing: 0

            PlasmaComponents.Label {
                Layout.bottomMargin: Kirigami.Units.smallSpacing
                text: "terminal"
                font.family: "JetBrainsMono Nerd Font"
                font.pointSize: Kirigami.Theme.smallFont.pointSize
                opacity: 0.5
            }
            Repeater {
                model: root.profiles
                PlasmaComponents.Label {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    verticalAlignment: Text.AlignVCenter
                    text: (hover.containsMouse ? "› " : "  ") + modelData[1].toLowerCase()
                    font.family: "JetBrainsMono Nerd Font"
                    color: hover.containsMouse ? Kirigami.Theme.highlightColor : Kirigami.Theme.textColor
                    opacity: hover.containsMouse ? 1 : 0.8
                    elide: Text.ElideRight

                    MouseArea {
                        id: hover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: exec.connectSource("setsid -f konsole --profile '" + modelData[0] + "'")
                    }
                }
            }
        }
    }
}
