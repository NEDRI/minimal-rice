// The Focus page, as Isle's pages/timer.js: a ring with the time left, the work and break lengths as
// steppers, and Start; the timer itself runs in isled, so it keeps going with the island closed.
import QtQuick
import QtQuick.Layouts

Item {
    id: comp
    property var isle
    readonly property var state: isle.pomodoro || { phase: "idle", running: false, remaining_ms: 1500000, duration_ms: 1500000 }
    readonly property bool idle: state.phase === "idle"
    property var asked: null      // stepper clicks isled has not answered yet

    RowLayout {
        anchors.fill: parent
        spacing: 0

        Ring {
            Layout.alignment: Qt.AlignVCenter
            size: 104; lineWidth: 5; trackOpacity: 0.14
            progress: comp.idle ? 0 : isle.timerProgress
            color: isle.timerColor
            Column {
                anchors.centerIn: parent
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: isle.mmss(isle.timerRemainingMs / 1000)
                    color: "white"
                    font { family: isle.font; pixelSize: 24; weight: Font.DemiBold; letterSpacing: -0.5 }
                    font.features: { "tnum": 1 }
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: ({ idle: "Focus", focus: "Focus", short_break: "Break", long_break: "Long break" })[comp.state.phase] || "Focus"
                    color: Qt.rgba(1, 1, 1, 0.55)
                    font { family: isle.font; pixelSize: 12; weight: Font.Medium }
                }
            }
        }
        Item { Layout.fillWidth: true }

        Column {
            Layout.alignment: Qt.AlignVCenter
            spacing: 8
            Repeater {
                model: [ { key: "focus_minutes", label: "Work", min: 1, max: 180 },
                         { key: "short_break_minutes", label: "Break", min: 1, max: 60 } ]
                Rectangle {
                    height: row.implicitHeight + 6
                    width: row.implicitWidth + 16
                    radius: height / 2
                    color: "#1c1c1e"
                    Row {
                        id: row
                        x: 12; anchors.verticalCenter: parent.verticalCenter
                        spacing: 4
                        Text {
                            width: 40; anchors.verticalCenter: parent.verticalCenter
                            text: modelData.label
                            color: Qt.rgba(1, 1, 1, 0.55)
                            font { family: isle.font; pixelSize: 12; weight: Font.Medium }
                        }
                        Text {
                            width: 32; anchors.verticalCenter: parent.verticalCenter
                            rightPadding: 6
                            horizontalAlignment: Text.AlignRight
                            text: { const c = comp.asked || isle.pomodoroConfig; return c && c[modelData.key] !== undefined ? c[modelData.key] : "–"; }
                            color: "white"
                            font { family: isle.font; pixelSize: 15; weight: Font.DemiBold; letterSpacing: -0.1 }
                            font.features: { "tnum": 1 }
                        }
                        IsleButton { anchors.verticalCenter: parent.verticalCenter; icon: "isle-minus-symbolic"; iconSize: 12; opacity: 0.8
                                     onClicked: comp.step(modelData.key, -1, modelData.min, modelData.max) }
                        IsleButton { anchors.verticalCenter: parent.verticalCenter; icon: "isle-plus-symbolic"; iconSize: 12; opacity: 0.8
                                     onClicked: comp.step(modelData.key, 1, modelData.min, modelData.max) }
                    }
                }
            }
        }
        Item { Layout.fillWidth: true }

        // Reset (once started) and Start, Pause or Resume, in a slot as wide as both
        Item {
            Layout.preferredWidth: 152
            Layout.fillHeight: true
            Row {
                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                spacing: 8
                IsleButton {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: !comp.idle
                    round: true; padding: 10
                    icon: "isle-reset"; iconSize: 14
                    onClicked: isle.daemon.call("Pomodoro1", "Stop")
                }
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    height: pill.implicitHeight + 16
                    width: pill.implicitWidth + 36
                    radius: height / 2
                    color: startArea.containsMouse ? "#3a3a3c" : "#2c2c2e"
                    Row {
                        id: pill
                        anchors.centerIn: parent
                        spacing: 7
                        IsleIcon { anchors.verticalCenter: parent.verticalCenter; size: 13
                                   name: comp.state.running ? "isle-pause-symbolic" : "isle-play-symbolic" }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: comp.state.running ? "Pause" : comp.idle ? "Start" : "Resume"
                            color: "white"
                            font { family: isle.font; pixelSize: 14; weight: Font.DemiBold }
                        }
                    }
                    MouseArea {
                        id: startArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: isle.daemon.call("Pomodoro1", comp.state.running ? "Pause" : "Start")
                    }
                }
            }
        }
    }

    function step(key, delta, min, max) {
        const config = asked || isle.pomodoroConfig;
        if (!config)
            return;
        const minutes = Math.min(max, Math.max(min, (config[key] || min) + delta));
        if (minutes === config[key])
            return;
        const next = Object.assign({}, config);
        next[key] = minutes;
        asked = next;
        isle.daemon.call("Pomodoro1", "SetConfig", [JSON.stringify(next)], "s");
    }
    Connections {
        target: isle
        function onPomodoroConfigChanged() { comp.asked = null; }
    }
}
