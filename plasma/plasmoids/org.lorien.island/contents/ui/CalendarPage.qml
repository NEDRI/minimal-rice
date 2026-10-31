// ---------------------------------------------------------------- Calendar
import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Item {
    id: comp
    property var isle
    readonly property date first: new Date(isle.now.getFullYear(), isle.now.getMonth(), 1)
    // weeks start on Monday
    readonly property int lead: (first.getDay() + 6) % 7
    readonly property int days: new Date(isle.now.getFullYear(), isle.now.getMonth() + 1, 0).getDate()

    RowLayout {
        anchors.fill: parent
        spacing: 28

        ColumnLayout {
            Layout.preferredWidth: 140
            spacing: 0
            Text {
                text: Qt.formatDate(isle.now, "dddd")
                color: "#ff453a"
                font { family: isle.font; pixelSize: 13; weight: Font.DemiBold; capitalization: Font.AllUppercase }
            }
            Text {
                text: isle.now.getDate()
                color: "white"
                font { family: isle.font; pixelSize: 56; weight: Font.DemiBold; letterSpacing: -2 }
            }
            Text {
                text: Qt.formatDate(isle.now, "MMMM yyyy")
                color: isle.dim
                font { family: isle.font; pixelSize: 13 }
            }
        }

        GridLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignTop
            columns: 7
            rowSpacing: 0
            columnSpacing: 0

            Repeater {
                model: ["M", "T", "W", "T", "F", "S", "S"]
                Text {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: modelData
                    color: Qt.rgba(1, 1, 1, 0.4)
                    font { family: isle.font; pixelSize: 10; weight: Font.DemiBold }
                }
            }
            Repeater {
                model: comp.lead + comp.days
                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 19
                    readonly property int day: index - comp.lead + 1
                    readonly property bool today: day === isle.now.getDate()
                    Rectangle {
                        anchors.centerIn: parent
                        width: 19; height: 19; radius: 9.5
                        color: "white"
                        visible: parent.today
                    }
                    Text {
                        anchors.centerIn: parent
                        visible: parent.day > 0
                        text: parent.day
                        color: parent.today ? "black" : "white"
                        font { family: isle.font; pixelSize: 11; weight: parent.today ? Font.Bold : Font.Normal }
                        font.features: { "tnum": 1 }
                    }
                }
            }
        }
    }
}
