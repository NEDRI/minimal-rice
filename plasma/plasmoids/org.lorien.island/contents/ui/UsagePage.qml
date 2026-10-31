// The Usage page, as Isle's pages/usage.js: how much of each AI plan's limits is used (Claude, ChatGPT as
// Codex saw it, Grok), a bar per limit, one provider at a time with dots to step through them. isled reads
// the numbers; the page asks for fresh ones when it opens. No tab without a provider.
import QtQuick
import QtQuick.Layouts

Item {
    id: comp
    property var isle
    readonly property var providers: isle.usage && isle.usage.providers ? isle.usage.providers : []
    property int index: 0
    readonly property var provider: providers.length ? providers[Math.min(index, providers.length - 1)] : null
    readonly property var marks: ({ warn: 80, critical: 95 })
    readonly property var accents: ({ claude: Qt.rgba(0.85, 0.47, 0.34, 1), codex: Qt.rgba(0.06, 0.64, 0.5, 1), grok: Qt.rgba(0.93, 0.94, 0.96, 1) })
    readonly property var logos: ({ claude: "isle-claude", codex: "isle-openai", grok: "isle-grok" })
    property real sweep: 1

    onVisibleChanged: if (visible) { isle.daemon.call("Usage1", "Refresh"); fill.restart(); }
    NumberAnimation { id: fill; target: comp; property: "sweep"; from: 0; to: 1; duration: 500; easing.type: Easing.OutCubic }

    // "resets in 1h 20m", "resets in 2d 5h", "resets in 12m"
    function resets(ms) {
        const minutes = Math.max(0, Math.round((ms - isle.nowMs) / 60000));
        if (minutes < 1) return "resets soon";
        const days = Math.floor(minutes / 1440), hours = Math.floor((minutes % 1440) / 60);
        if (days > 0) return hours ? "resets in " + days + "d " + hours + "h" : "resets in " + days + "d";
        if (hours > 0) return minutes % 60 ? "resets in " + hours + "h " + (minutes % 60) + "m" : "resets in " + hours + "h";
        return "resets in " + minutes + "m";
    }
    // "Updated 14:32", or "From Codex, 14:32"; on another day, with its name
    function updated(ms, fromCodex) {
        if (!ms) return "";
        const at = new Date(ms);
        const today = Qt.formatDate(at, "yyyy-MM-dd") === Qt.formatDate(new Date(isle.nowMs), "yyyy-MM-dd");
        const when = (today ? "" : Qt.formatDate(at, "ddd") + " ") + Qt.formatTime(at, "HH:mm");
        return (fromCodex ? "From Codex, " : "Updated ") + when;
    }

    // scrolled through like a widget stack
    WheelHandler { onWheel: e => { comp.index = Math.max(0, Math.min(comp.providers.length - 1, comp.index + (e.angleDelta.y < 0 ? 1 : -1))); fill.restart(); } }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            Layout.bottomMargin: 4
            spacing: 14
            visible: !!comp.provider

            // the provider, its plan, and how fresh the numbers are (or what is wrong)
            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                IsleIcon { name: comp.provider && comp.logos[comp.provider.id] ? comp.logos[comp.provider.id] : ""; size: 18
                           isMask: false; visible: name !== "" }
                Text { renderType: Text.QtRendering
                    text: comp.provider ? comp.provider.name : ""
                    color: "white"
                    font { family: isle.font; pixelSize: 15; weight: Font.Bold; letterSpacing: -0.2 }
                }
                Rectangle {
                    visible: !!(comp.provider && comp.provider.plan)
                    implicitWidth: planText.implicitWidth + 14
                    implicitHeight: planText.implicitHeight + 2
                    radius: height / 2
                    color: Qt.rgba(1, 1, 1, 0.1)
                    Text { renderType: Text.QtRendering; id: planText; anchors.centerIn: parent
                           text: comp.provider ? (comp.provider.plan || "") : ""; color: Qt.rgba(1, 1, 1, 0.7)
                           font { family: isle.font; pixelSize: 11; weight: Font.DemiBold } }
                }
                Text { renderType: Text.QtRendering
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignRight
                    elide: Text.ElideRight
                    readonly property bool fromCodex: !!(comp.provider && comp.provider.note && comp.provider.note.startsWith("As of"))
                    readonly property bool warning: !!(comp.provider && comp.provider.note) && !fromCodex
                    text: !comp.provider ? "" : warning ? comp.provider.note : comp.updated(comp.provider.updated_ms, fromCodex)
                    color: Qt.rgba(1, 1, 1, warning ? 0.8 : 0.55)
                    font { family: isle.font; pixelSize: 11 }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 11
                Text { renderType: Text.QtRendering
                    visible: !!comp.provider && comp.provider.windows.length === 0
                    text: comp.provider ? (comp.provider.empty || "No limits reported yet") : ""
                    color: Qt.rgba(1, 1, 1, 0.55)
                    font { family: isle.font; pixelSize: 12 }
                }
                Repeater {
                    model: comp.provider ? comp.provider.windows.slice(0, 3) : []
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 5
                        readonly property int shown: Math.round(Math.max(0, Math.min(100, modelData.percent)))
                        readonly property string level: shown >= comp.marks.critical ? "critical" : shown >= comp.marks.warn ? "warn" : "normal"
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10
                            Text { renderType: Text.QtRendering; Layout.fillWidth: true; elide: Text.ElideRight
                                   text: modelData.label; color: Qt.rgba(1, 1, 1, 0.9)
                                   font { family: isle.font; pixelSize: 13; weight: Font.DemiBold } }
                            Text { renderType: Text.QtRendering; visible: modelData.resets_at_ms > 0
                                   text: comp.resets(modelData.resets_at_ms); color: Qt.rgba(1, 1, 1, 0.55)
                                   font { family: isle.font; pixelSize: 11 } }
                            Text { renderType: Text.QtRendering; Layout.minimumWidth: 40; horizontalAlignment: Text.AlignRight
                                   text: parent.parent.shown + "%"; color: parent.parent.level === "critical" ? "#ff453a" : "white"
                                   font { family: isle.font; pixelSize: 13; weight: Font.Bold }
                                   font.features: { "tnum": 1 } }
                        }
                        Rectangle {
                            Layout.fillWidth: true
                            height: 5; radius: 3
                            color: Qt.rgba(1, 1, 1, 0.1)
                            Rectangle {
                                height: 5; radius: 3
                                readonly property real share: Math.max(0, Math.min(100, modelData.percent)) / 100
                                width: share > 0 ? Math.max(height, Math.round(parent.width * share * comp.sweep)) : 0
                                color: parent.parent.level === "critical" ? "#ff453a" : (comp.accents[comp.provider.id] || "#0a84ff")
                            }
                        }
                    }
                }
            }
        }

        // a dot per provider; the shown one is a tall pill
        Column {
            Layout.leftMargin: 14
            Layout.alignment: Qt.AlignVCenter
            visible: comp.providers.length > 1
            spacing: 6
            Repeater {
                model: comp.providers.length
                Rectangle {
                    width: 6; height: index === comp.index ? 16 : 6; radius: 3
                    color: index === comp.index ? "white" : dotArea.containsMouse ? Qt.rgba(1, 1, 1, 0.45) : Qt.rgba(1, 1, 1, 0.22)
                    Behavior on height { NumberAnimation { duration: 200 } }
                    MouseArea { id: dotArea; anchors.fill: parent; anchors.margins: -4; hoverEnabled: true
                                onClicked: { comp.index = index; fill.restart(); } }
                }
            }
        }
    }
}
