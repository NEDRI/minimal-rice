// The Apps page, as Isle's pages/apps.js: time in each application today, or over the last 7 or 30 days,
// most used first, with a bar against the most used one.
import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Item {
    id: comp
    property var isle
    property string period: "today"
    readonly property var periods: ({ today: { days: 1, total: "today" }, week: { days: 7, total: "in 7 days" },
                                      month: { days: 30, total: "in 30 days" } })
    readonly property var apps: { isle.nowMs; isle.appUsage.revision; return visible ? isle.appUsage.stats(periods[period].days) : []; }
    readonly property real total: apps.reduce((sum, a) => sum + a.ms, 0)
    readonly property real most: Math.max(1, ...apps.map(a => a.ms))

    // "1h 15m", "25m", "<1m" (Isle's Format.hoursMinutes)
    function hoursMinutes(ms) {
        if (ms < 60000) return ms > 0 ? "<1m" : "0m";
        const minutes = Math.round(ms / 60000), hours = Math.floor(minutes / 60);
        if (!hours) return minutes + "m";
        return minutes % 60 ? hours + "h " + (minutes % 60) + "m" : hours + "h";
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // the heading, the period's total, and today / 7 days / 30 days
        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 8
            Layout.rightMargin: 8
            Layout.bottomMargin: 6
            spacing: 10
            Text { renderType: Text.QtRendering;
                Layout.fillWidth: true
                text: "App Usage"
                color: Qt.rgba(1, 1, 1, 0.6)
                font { family: isle.font; pixelSize: 13; weight: Font.DemiBold }
            }
            Text { renderType: Text.QtRendering;
                text: comp.total > 0 ? comp.hoursMinutes(comp.total) + " " + comp.periods[comp.period].total : ""
                color: Qt.rgba(1, 1, 1, 0.45)
                font { family: isle.font; pixelSize: 11 }
            }
            Rectangle {
                implicitWidth: toggle.implicitWidth + 6
                implicitHeight: toggle.implicitHeight + 6
                radius: height / 2
                color: "#1c1c1e"
                Row {
                    id: toggle
                    x: 3; y: 3
                    spacing: 2
                    Repeater {
                        model: [ { name: "today", label: "Today" }, { name: "week", label: "7 days" }, { name: "month", label: "30 days" } ]
                        Rectangle {
                            readonly property bool checked: comp.period === modelData.name
                            implicitWidth: segText.implicitWidth + 18
                            implicitHeight: segText.implicitHeight + 6
                            radius: height / 2
                            gradient: Gradient {
                                GradientStop { position: 0; color: checked ? "#4a4a4d" : segArea.containsMouse ? Qt.rgba(1, 1, 1, 0.05) : "transparent" }
                                GradientStop { position: 1; color: checked ? "#3a3a3c" : segArea.containsMouse ? Qt.rgba(1, 1, 1, 0.05) : "transparent" }
                            }
                            Text { renderType: Text.QtRendering;
                                id: segText
                                anchors.centerIn: parent
                                text: modelData.label
                                color: parent.checked || segArea.containsMouse ? "white" : Qt.rgba(1, 1, 1, 0.6)
                                font { family: isle.font; pixelSize: 11; weight: Font.DemiBold }
                            }
                            MouseArea { id: segArea; anchors.fill: parent; hoverEnabled: true; onClicked: comp.period = modelData.name }
                        }
                    }
                }
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            Column {
                anchors.centerIn: parent
                visible: comp.apps.length === 0
                spacing: 4
                IsleIcon { anchors.horizontalCenter: parent.horizontalCenter; name: "isle-apps"; size: 24; opacity: 0.35 }
                Text { renderType: Text.QtRendering; anchors.horizontalCenter: parent.horizontalCenter; text: "No usage yet"; color: "white"
                       font { family: isle.font; pixelSize: 15; weight: Font.DemiBold; letterSpacing: -0.1 } }
                Text { renderType: Text.QtRendering; anchors.horizontalCenter: parent.horizontalCenter; text: "Time in the app in front shows up here"
                       color: Qt.rgba(1, 1, 1, 0.5); font { family: isle.font; pixelSize: 12 } }
            }

            ListView {
                anchors.fill: parent
                anchors.topMargin: 2
                visible: comp.apps.length > 0
                clip: true
                spacing: 8
                model: comp.apps
                delegate: RowLayout {
                    required property var modelData
                    width: ListView.view.width
                    spacing: 10
                    Kirigami.Icon { Layout.preferredWidth: 18; Layout.preferredHeight: 18; source: modelData.icon }
                    Text { renderType: Text.QtRendering;
                        Layout.fillWidth: true
                        text: modelData.name
                        elide: Text.ElideRight
                        color: Qt.rgba(1, 1, 1, 0.92)
                        font { family: isle.font; pixelSize: 13 }
                    }
                    Rectangle {
                        Layout.preferredWidth: 120
                        height: 4; radius: 2
                        color: Qt.rgba(1, 1, 1, 0.1)
                        Rectangle {
                            height: 4; radius: 2
                            color: Qt.rgba(1, 1, 1, 0.8)
                            width: modelData.ms > 0 ? Math.max(4, Math.round(parent.width * modelData.ms / comp.most)) : 0
                        }
                    }
                    Text { renderType: Text.QtRendering;
                        Layout.minimumWidth: 44
                        horizontalAlignment: Text.AlignRight
                        text: comp.hoursMinutes(modelData.ms)
                        color: Qt.rgba(1, 1, 1, 0.6)
                        font { family: isle.font; pixelSize: 12 }
                        font.features: { "tnum": 1 }
                    }
                }
            }
        }
    }
}
