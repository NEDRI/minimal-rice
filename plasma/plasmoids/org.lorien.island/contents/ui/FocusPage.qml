// ---------------------------------------------------------------- Focus
import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Item {
    id: comp
    property var isle
    RowLayout {
        anchors.fill: parent
        spacing: 24

        TimerRing { isle: comp.isle;
            Layout.preferredWidth: 104
            Layout.preferredHeight: 104
            lineWidth: 6
            Text {
                anchors.centerIn: parent
                text: isle.timerPhase === "break" ? "Break" : "Focus"
                color: isle.timerPhase === "break" ? isle.green : isle.dim
                font { family: isle.font; pixelSize: 13; weight: Font.DemiBold }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 6
            Text {
                text: isle.mmss(isle.timerLeft)
                color: isle.timerPhase === "break" ? isle.green : "white"
                font { family: isle.font; pixelSize: 44; weight: Font.DemiBold; letterSpacing: -1 }
                font.features: { "tnum": 1 }
            }
            RowLayout {
                spacing: 10
                IsleButton {
                    round: true
                    glyph: isle.timerRunning ? "\u{F03E4}" : "\u{F040A}"
                    onClicked: {
                        if (isle.timerPhase === "idle") {
                            isle.timerPhase = "focus";
                            isle.timerLeft = isle.focusMinutes * 60;
                        }
                        isle.timerRunning = !isle.timerRunning;
                    }
                }
                IsleButton {
                    round: true
                    glyph: "\u{F0450}"
                    onClicked: {
                        isle.timerRunning = false;
                        isle.timerPhase = "idle";
                        isle.timerLeft = isle.focusMinutes * 60;
                    }
                }
                Item { Layout.preferredWidth: 10 }
                // minutes stepper, as Isle's
                IsleButton {
                    glyph: "\u{F0374}"; glyphSize: 14
                    enabled: isle.timerPhase === "idle" && isle.focusMinutes > 5
                    opacity: enabled ? 1 : 0.4
                    onClicked: { isle.focusMinutes -= 5; isle.timerLeft = isle.focusMinutes * 60; }
                }
                Text {
                    text: isle.focusMinutes + " min"
                    color: "white"
                    font { family: isle.font; pixelSize: 13; weight: Font.DemiBold }
                    font.features: { "tnum": 1 }
                }
                IsleButton {
                    glyph: "\u{F0415}"; glyphSize: 14
                    enabled: isle.timerPhase === "idle" && isle.focusMinutes < 90
                    opacity: enabled ? 1 : 0.4
                    onClicked: { isle.focusMinutes += 5; isle.timerLeft = isle.focusMinutes * 60; }
                }
            }
        }
    }
}
