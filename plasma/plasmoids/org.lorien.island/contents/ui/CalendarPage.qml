// The Calendar page, as Isle's pages/calendar.js: the month on the left (today in red, a dot under days with
// events), the chosen day's events on the right with a field to add one ("Dentist tomorrow 10:00"). The
// events are Isle's own, kept in isled; it reads the time and date out of the line typed.
import QtQuick
import QtQuick.Layouts

Item {
    id: comp
    property var isle

    readonly property date today: new Date(isle.now.getFullYear(), isle.now.getMonth(), isle.now.getDate())
    property date month: new Date(today.getFullYear(), today.getMonth(), 1)
    property date selected: today
    readonly property var events: isle.events || []

    function key(d) { return Qt.formatDate(d, "yyyy-MM-dd"); }
    function sameDay(a, b) { return a.getFullYear() === b.getFullYear() && a.getMonth() === b.getMonth() && a.getDate() === b.getDate(); }
    function goToToday() { month = new Date(today.getFullYear(), today.getMonth(), 1); selected = today; }
    readonly property var dayEvents: events.filter(e => e.date === key(selected))
        .sort((a, b) => (!b.start - !a.start) || String(a.start || "").localeCompare(String(b.start || "")))
    readonly property var busyDays: { const s = {}; events.forEach(e => s[e.date] = true); return s; }

    RowLayout {
        anchors.fill: parent
        spacing: 24

        // ---------------------------------------------------------------- the month
        ColumnLayout {
            Layout.preferredWidth: 196
            Layout.maximumWidth: 196
            Layout.alignment: Qt.AlignVCenter
            spacing: 2

            RowLayout {
                Layout.fillWidth: true
                Layout.bottomMargin: 2
                spacing: 0
                Rectangle {
                    Layout.leftMargin: -4
                    implicitWidth: monthTitle.implicitWidth + 8
                    implicitHeight: monthTitle.implicitHeight + 2
                    radius: 6
                    color: titleArea.containsMouse ? Qt.rgba(1, 1, 1, 0.06) : "transparent"
                    Row {
                        id: monthTitle
                        anchors.centerIn: parent
                        spacing: 5
                        Text { renderType: Text.QtRendering; text: Qt.formatDate(comp.month, "MMMM").toUpperCase(); color: "#ff453a"
                               font { family: isle.font; pixelSize: 12; weight: Font.Bold } }
                        Text { renderType: Text.QtRendering; text: comp.month.getFullYear(); color: Qt.rgba(1, 1, 1, 0.5)
                               font { family: isle.font; pixelSize: 12; weight: Font.DemiBold } }
                    }
                    MouseArea { id: titleArea; anchors.fill: parent; hoverEnabled: true; onClicked: comp.goToToday() }
                }
                Item { Layout.fillWidth: true }
                IsleButton { padding: 4; icon: "isle-chevron-left-symbolic"; iconSize: 11; opacity: 0.75
                             onClicked: comp.month = new Date(comp.month.getFullYear(), comp.month.getMonth() - 1, 1) }
                IsleButton { padding: 4; icon: "isle-chevron-right-symbolic"; iconSize: 11; opacity: 0.75
                             onClicked: comp.month = new Date(comp.month.getFullYear(), comp.month.getMonth() + 1, 1) }
            }

            // weekdays, Monday first; weekends dimmer
            Row {
                Repeater {
                    model: ["M", "T", "W", "T", "F", "S", "S"]
                    Text { renderType: Text.QtRendering;
                        width: 28
                        horizontalAlignment: Text.AlignHCenter
                        text: modelData
                        color: Qt.rgba(1, 1, 1, index >= 5 ? 0.5 : 0.55)
                        font { family: isle.font; pixelSize: 10; weight: Font.DemiBold }
                    }
                }
            }

            Grid {
                id: grid
                columns: 7
                readonly property int lead: (new Date(comp.month.getFullYear(), comp.month.getMonth(), 1).getDay() + 6) % 7
                readonly property int days: new Date(comp.month.getFullYear(), comp.month.getMonth() + 1, 0).getDate()
                readonly property int rows: Math.ceil((lead + days) / 7)
                Repeater {
                    model: grid.rows * 7
                    Item {
                        id: cell
                        readonly property int day: index - grid.lead + 1
                        readonly property date date: new Date(comp.month.getFullYear(), comp.month.getMonth(), day)
                        readonly property bool inMonth: day >= 1 && day <= grid.days
                        readonly property bool isToday: inMonth && comp.sameDay(date, comp.today)
                        readonly property bool isSelected: inMonth && comp.sameDay(date, comp.selected)
                        width: 28
                        height: Math.min(21, 108 / grid.rows)
                        Rectangle {
                            anchors.centerIn: parent
                            width: 19; height: 19; radius: 10
                            visible: cell.inMonth
                            color: cell.isToday ? (dayArea.containsMouse ? "#ff5f55" : "#ff453a")
                                : cell.isSelected ? Qt.rgba(1, 1, 1, 0.22) : dayArea.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : "transparent"
                            Text { renderType: Text.QtRendering;
                                anchors.centerIn: parent
                                text: cell.day
                                color: cell.isToday ? "white" : Qt.rgba(1, 1, 1, index % 7 >= 5 ? 0.55 : 1)
                                font { family: isle.font; pixelSize: 11; weight: cell.isToday ? Font.Bold : Font.DemiBold }
                                font.features: { "tnum": 1 }
                            }
                            // a day with events: a dot just under its number
                            Rectangle {
                                anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 1 }
                                width: 3; height: 3; radius: 1.5
                                visible: !!comp.busyDays[comp.key(cell.date)]
                                color: cell.isToday ? "white" : Qt.rgba(1, 1, 1, 0.55)
                            }
                            MouseArea { id: dayArea; anchors.fill: parent; hoverEnabled: true; onClicked: comp.selected = cell.date }
                        }
                    }
                }
            }
        }

        // ---------------------------------------------------------------- the day's events
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 5

            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                Text { renderType: Text.QtRendering;
                    Layout.fillWidth: true
                    readonly property int offset: Math.round((comp.selected - comp.today) / 86400000)
                    readonly property var names: ({ "-1": "Yesterday", "0": "Today", "1": "Tomorrow" })
                    text: names[offset] !== undefined ? names[offset] + ", " + Qt.formatDate(comp.selected, "d MMMM")
                        : Qt.formatDate(comp.selected, "dddd, d MMMM")
                    elide: Text.ElideRight
                    color: "white"
                    font { family: isle.font; pixelSize: 14; weight: Font.DemiBold; letterSpacing: -0.1 }
                }
                Rectangle {
                    visible: !comp.sameDay(comp.selected, comp.today) || comp.month.getMonth() !== comp.today.getMonth()
                    implicitWidth: todayText.implicitWidth + 18
                    implicitHeight: todayText.implicitHeight + 4
                    radius: height / 2
                    color: todayArea.containsMouse ? "#3a3a3c" : "#2c2c2e"
                    Text { renderType: Text.QtRendering; id: todayText; anchors.centerIn: parent; text: "Today"; color: "white"
                           font { family: isle.font; pixelSize: 11; weight: Font.DemiBold } }
                    MouseArea { id: todayArea; anchors.fill: parent; hoverEnabled: true; onClicked: comp.goToToday() }
                }
            }

            // the add field
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 30
                radius: height / 2
                color: field.activeFocus ? "#2c2c2e" : "#1c1c1e"
                IsleIcon { id: plus; x: 12; anchors.verticalCenter: parent.verticalCenter; name: "isle-plus-symbolic"; size: 13; opacity: 0.55 }
                TextInput { renderType: Text.QtRendering; TapHandler { onTapped: isle.wantKeyboard() }
                    id: field
                    anchors { left: plus.right; leftMargin: 8; right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter }
                    color: "white"
                    clip: true
                    font { family: isle.font; pixelSize: 13 }
                    Text { renderType: Text.QtRendering; visible: !parent.text; text: "Add an event, e.g. Lunch 13:00"; color: Qt.rgba(1, 1, 1, 0.45); font: parent.font }
                    onAccepted: {
                        const t = text.trim();
                        if (t)
                            isle.daemon.call("Calendar1", "Add", [comp.key(comp.selected), t], "ss");
                        text = "";
                    }
                    Keys.onEscapePressed: { text = ""; focus = false; }
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Text { renderType: Text.QtRendering;
                    anchors.centerIn: parent
                    visible: comp.dayEvents.length === 0
                    text: "No events"
                    color: Qt.rgba(1, 1, 1, 0.55)
                    font { family: isle.font; pixelSize: 13; weight: Font.DemiBold }
                }
                ListView {
                    anchors.fill: parent
                    clip: true
                    spacing: 3
                    model: comp.dayEvents
                    delegate: Rectangle {
                        id: ev
                        required property var modelData
                        width: ListView.view.width
                        height: 26
                        radius: 7
                        color: Qt.rgba(1, 1, 1, 0.07)
                        HoverHandler { id: evHover }
                        RowLayout {
                            anchors { fill: parent; leftMargin: 10; rightMargin: 8 }
                            spacing: 8
                            Rectangle { width: 7; height: 7; radius: 3.5; color: "#ff9f0a" }
                            Text { renderType: Text.QtRendering;
                                Layout.fillWidth: true
                                text: ev.modelData.title
                                elide: Text.ElideRight
                                color: "white"
                                font { family: isle.font; pixelSize: 13; weight: Font.DemiBold }
                            }
                            Text { renderType: Text.QtRendering;
                                visible: !evHover.hovered
                                text: ev.modelData.start ? ev.modelData.start + (ev.modelData.end ? " – " + ev.modelData.end : "") : "All day"
                                color: Qt.rgba(1, 1, 1, 0.65)
                                font { family: isle.font; pixelSize: 11; weight: Font.Medium }
                                font.features: { "tnum": 1 }
                            }
                            IsleButton {
                                visible: evHover.hovered
                                padding: 3; icon: "isle-close-symbolic"; iconSize: 10; opacity: hovered ? 1 : 0.7
                                onClicked: isle.daemon.call("Calendar1", "Remove", [ev.modelData.id], "t")
                            }
                        }
                    }
                }
            }
        }
    }
}
