// The Notifications page, as Isle's pages/notifications.js: a heading with Do Not Disturb and Clear (and,
// while it is on, what still gets through), over a list of one-line rows, newest first. Click one to open
// it; × under the pointer dismisses it. In KDE the list is Plasma's notification history.
import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.notificationmanager as NotificationManager

Item {
    id: comp
    property var isle
    readonly property alias model: history
    readonly property bool dnd: isle.dnd

    NotificationManager.Notifications {
        id: history
        showExpired: true
        showDismissed: true
        showJobs: false
        groupMode: NotificationManager.Notifications.GroupDisabled
        sortMode: NotificationManager.Notifications.SortByDate
        sortOrder: Qt.DescendingOrder
    }

    // "now", "5m", "3h", a weekday within the week, else "12 Oct" (Isle's Format.ago)
    function ago(date) {
        const minutes = Math.floor((isle.nowMs - date.getTime()) / 60000);
        if (minutes < 1) return "now";
        if (minutes < 60) return minutes + "m";
        if (minutes < 24 * 60) return Math.floor(minutes / 60) + "h";
        return Qt.formatDate(date, minutes < 6 * 24 * 60 ? "ddd" : "d MMM");
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.leftMargin: -8      // .isle-page.isle-notifications: 20 px instead of 28 at the sides
        anchors.rightMargin: -8
        spacing: 0

        // How many there are, then Do Not Disturb and Clear as small round buttons
        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 10
            Layout.rightMargin: 10
            Layout.bottomMargin: 6
            spacing: 6
            Text { renderType: Text.QtRendering;
                Layout.fillWidth: true
                text: "Notifications"
                color: Qt.rgba(1, 1, 1, 0.6)
                font { family: isle.font; pixelSize: 13; weight: Font.DemiBold }
            }
            IsleButton {
                padding: 6
                icon: comp.dnd ? "isle-moon" : "isle-bell"
                iconSize: 13
                opacity: comp.dnd ? 1 : 0.6
                color: comp.dnd ? (hovered ? "#6e6cf0" : "#5e5ce6") : hovered ? Qt.rgba(1, 1, 1, 0.12) : "transparent"
                onClicked: isle.toggleDnd()
            }
            Rectangle {
                visible: history.count > 0
                implicitWidth: clearText.implicitWidth + 24
                implicitHeight: clearText.implicitHeight + 10
                radius: height / 2
                color: clearArea.pressed ? "#48484a" : clearArea.containsMouse ? "#3a3a3c" : "#2c2c2e"
                Text { renderType: Text.QtRendering;
                    id: clearText
                    anchors.centerIn: parent
                    text: "Clear"
                    color: "white"
                    font { family: isle.font; pixelSize: 12; weight: Font.DemiBold }
                }
                MouseArea {
                    id: clearArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        for (let i = history.count - 1; i >= 0; i--) {
                            const idx = history.index(i, 0);
                            if (!history.data(idx, NotificationManager.Notifications.ResidentRole))
                                history.close(idx);
                        }
                        history.clear(NotificationManager.Notifications.ClearExpired);
                    }
                }
            }
        }

        // While Do Not Disturb is on, what it does
        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 10
            Layout.rightMargin: 10
            Layout.bottomMargin: 8
            visible: comp.dnd
            spacing: 6
            IsleIcon { name: "isle-moon"; size: 10; opacity: 130 / 255 }
            Text { renderType: Text.QtRendering;
                Layout.fillWidth: true
                text: "Do Not Disturb: new ones wait here; urgent ones still show"
                elide: Text.ElideRight
                color: Qt.rgba(1, 1, 1, 0.5)
                font { family: isle.font; pixelSize: 12 }
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            Column {
                anchors.centerIn: parent
                visible: history.count === 0
                spacing: 4
                IsleIcon { anchors.horizontalCenter: parent.horizontalCenter; name: "isle-bell"; size: 24; opacity: 0.35 }
                Item { width: 1; height: 4 }
                Text { renderType: Text.QtRendering; anchors.horizontalCenter: parent.horizontalCenter; text: "No notifications"; color: "white"
                       font { family: isle.font; pixelSize: 15; weight: Font.DemiBold; letterSpacing: -0.1 } }
                Text { renderType: Text.QtRendering; anchors.horizontalCenter: parent.horizontalCenter; text: "You’re all caught up"; color: Qt.rgba(1, 1, 1, 0.5)
                       font { family: isle.font; pixelSize: 12 } }
            }

            ListView {
                id: list
                anchors.fill: parent
                visible: history.count > 0
                clip: true
                spacing: 6
                model: history
                footer: Item { width: 1; height: 8 }

                delegate: Rectangle {
                    id: row
                    required property int index
                    required property var model
                    readonly property var actions: (model.actionNames || []).slice(0, 3)
                    width: ListView.view.width
                    height: content.implicitHeight + 16
                    radius: 12
                    color: rowArea.containsMouse ? Qt.rgba(1, 1, 1, 0.09) : Qt.rgba(1, 1, 1, 0.05)
                    Behavior on color { ColorAnimation { duration: 120 } }

                    MouseArea {
                        id: rowArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            const idx = history.index(row.index, 0);
                            if (row.model.hasDefaultAction)
                                history.invokeDefaultAction(idx, NotificationManager.Notifications.Close);
                            else
                                history.expire(idx);
                            isle.close();
                        }
                    }

                    RowLayout {
                        id: content
                        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 10; topMargin: 8 }
                        spacing: 10

                        // the app's icon: a colour one as is
                        Kirigami.Icon {
                            Layout.preferredWidth: 20
                            Layout.preferredHeight: 20
                            Layout.alignment: row.actions.length ? Qt.AlignTop : Qt.AlignVCenter
                            source: row.model.image ? row.model.image : (row.model.applicationIconName || row.model.iconName || "dialog-information")
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8
                                Text { renderType: Text.QtRendering;
                                    Layout.maximumWidth: implicitWidth
                                    Layout.fillWidth: true
                                    text: (row.model.summary || row.model.applicationName || "").replace(/\s+/g, " ").trim()
                                    elide: Text.ElideRight
                                    color: "white"
                                    font { family: isle.font; pixelSize: 13; weight: Font.DemiBold }
                                }
                                Text { renderType: Text.QtRendering;
                                    Layout.fillWidth: true
                                    visible: text.length > 0
                                    text: (row.model.body || "").replace(/<[^>]*>/g, "").replace(/\s+/g, " ").trim()
                                    elide: Text.ElideRight
                                    color: Qt.rgba(1, 1, 1, 0.55)
                                    font { family: isle.font; pixelSize: 13 }
                                }
                            }
                            // its buttons, on a line of their own
                            Flow {
                                Layout.fillWidth: true
                                Layout.topMargin: 6
                                visible: row.actions.length > 0
                                spacing: 6
                                Repeater {
                                    model: row.actions
                                    Rectangle {
                                        width: actionText.implicitWidth + 20
                                        height: actionText.implicitHeight + 6
                                        radius: height / 2
                                        color: actionArea.containsMouse ? "#3a3a3c" : "#2c2c2e"
                                        Text { renderType: Text.QtRendering;
                                            id: actionText
                                            anchors.centerIn: parent
                                            text: (row.model.actionLabels || [])[index] || modelData
                                            color: "white"
                                            font { family: isle.font; pixelSize: 11 }
                                        }
                                        MouseArea {
                                            id: actionArea
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            onClicked: {
                                                history.invokeAction(history.index(row.index, 0), modelData, NotificationManager.Notifications.Close);
                                                isle.close();
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        // the time, and in its place under the pointer the ×
                        Item {
                            Layout.alignment: row.actions.length ? Qt.AlignTop : Qt.AlignVCenter
                            implicitWidth: Math.max(time.implicitWidth, 18)
                            implicitHeight: Math.max(time.implicitHeight, 18)
                            Text { renderType: Text.QtRendering;
                                id: time
                                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                                leftPadding: 8
                                text: row.model.created ? comp.ago(row.model.created) : ""
                                color: Qt.rgba(1, 1, 1, 0.45)
                                opacity: rowArea.containsMouse && !row.model.resident ? 0 : 1
                                Behavior on opacity { NumberAnimation { duration: 120 } }
                                font { family: isle.font; pixelSize: 12 }
                            }
                            IsleButton {
                                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                                visible: !row.model.resident
                                opacity: rowArea.containsMouse || hovered ? 1 : 0
                                Behavior on opacity { NumberAnimation { duration: 120 } }
                                padding: 4
                                icon: "isle-close-symbolic"
                                iconSize: 10
                                color: "#3a3a3c"
                                onClicked: history.close(history.index(row.index, 0))
                            }
                        }
                    }
                }
            }
        }
    }
}
