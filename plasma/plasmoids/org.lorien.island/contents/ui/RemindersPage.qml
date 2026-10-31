// The Reminders page, as Isle's pages/tasks.js, in dark mode: an orange title and count, a ring and a
// hairline per reminder, and a last row to add one; a ticked one is struck, lingers a moment (a second tap
// undoes it), then folds away. Click a title to rename it. The list lives in isled's todo store.
import QtQuick
import QtQuick.Layouts

Item {
    id: comp
    property var isle
    readonly property var tasks: isle.tasks || []
    readonly property var open: tasks.filter(t => !t.done).sort((a, b) => a.id - b.id)

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // "Reminders", the count of open ones, and +
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 24
            spacing: 4
            Text { renderType: Text.QtRendering;
                Layout.fillWidth: true
                text: "Reminders"
                color: "#ff9f0a"
                font { family: isle.font; pixelSize: 17; weight: Font.DemiBold; letterSpacing: -0.2 }
            }
            Text { renderType: Text.QtRendering;
                rightPadding: 2
                text: comp.open.length
                color: "#ff9f0a"
                font { family: isle.font; pixelSize: 17; weight: Font.DemiBold; letterSpacing: -0.2 }
                font.features: { "tnum": 1 }
            }
            IsleButton {
                Layout.rightMargin: -5
                padding: 5
                icon: "isle-plus-symbolic"
                iconSize: 12
                opacity: hovered ? 1 : 0.55
                onClicked: { newField.forceActiveFocus(); list.positionViewAtEnd(); }
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            Text { renderType: Text.QtRendering;
                anchors.horizontalCenter: parent.horizontalCenter
                y: 22 + 30
                visible: comp.open.length === 0
                text: comp.tasks.length > 0 ? "All done" : "No reminders"
                color: Qt.rgba(1, 1, 1, 0.55)
                font { family: isle.font; pixelSize: 13; weight: Font.DemiBold }
            }

            ListView {
                id: list
                anchors.fill: parent
                clip: true
                model: comp.open
                footer: newRow

                delegate: Item {
                    id: row
                    required property var modelData
                    property bool ticked: false
                    property bool renaming: false
                    width: ListView.view.width
                    height: folding.running || folded ? fold : content.implicitHeight
                    property real fold: content.implicitHeight
                    property bool folded: false
                    clip: true

                    HoverHandler { id: rowHover }

                    RowLayout {
                        id: content
                        width: parent.width
                        spacing: 10

                        // the tick box: an 18 px ring, and a dot that pops into it when ticked
                        Rectangle {
                            Layout.alignment: Qt.AlignTop
                            Layout.topMargin: 3
                            width: 18; height: 18; radius: 9
                            color: "transparent"
                            border.width: 1.5
                            border.color: row.ticked ? "#ff9f0a" : tickArea.containsMouse ? Qt.rgba(1, 1, 1, 0.6) : Qt.rgba(1, 1, 1, 0.32)
                            Behavior on border.color { ColorAnimation { duration: 160 } }
                            Rectangle {
                                anchors.centerIn: parent
                                width: 10; height: 10; radius: 5
                                color: "#ff9f0a"
                                scale: row.ticked ? 1 : 0
                                Behavior on scale { NumberAnimation { duration: 200; easing.type: row.ticked ? Easing.OutBack : Easing.OutQuad } }
                            }
                            MouseArea { id: tickArea; anchors.fill: parent; hoverEnabled: true; onClicked: row.tick() }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0
                            RowLayout {
                                Layout.fillWidth: true
                                Layout.rightMargin: 2
                                spacing: 6
                                Item {
                                    Layout.fillWidth: true
                                    implicitHeight: Math.max(title.implicitHeight, field.implicitHeight) + 6
                                    Text { renderType: Text.QtRendering;
                                        id: title
                                        y: 3
                                        width: parent.width
                                        visible: !row.renaming
                                        text: row.modelData.title
                                        wrapMode: Text.Wrap
                                        color: row.ticked ? Qt.rgba(1, 1, 1, 0.38) : "white"
                                        Behavior on color { ColorAnimation { duration: 200 } }
                                        font { family: isle.font; pixelSize: 14; letterSpacing: -0.1 }
                                        MouseArea {
                                            anchors.fill: parent
                                            onClicked: if (!row.ticked) { row.renaming = true; field.text = row.modelData.title; field.forceActiveFocus(); field.selectAll(); }
                                        }
                                    }
                                    // the strike across the title
                                    Rectangle {
                                        y: title.y + Math.min(title.implicitHeight, 18) / 2
                                        height: 1.5
                                        color: Qt.rgba(1, 1, 1, 0.45)
                                        width: row.ticked ? Math.min(title.contentWidth, parent.width) : 0
                                        Behavior on width { NumberAnimation { duration: 180; easing.type: Easing.OutQuad } }
                                    }
                                    TextInput { renderType: Text.QtRendering;
                                        id: field
                                        y: 3
                                        width: parent.width
                                        visible: row.renaming
                                        color: "white"
                                        selectionColor: Qt.rgba(1, 1, 1, 0.25)
                                        font { family: isle.font; pixelSize: 14; letterSpacing: -0.1 }
                                        onAccepted: row.finishRename(true)
                                        Keys.onEscapePressed: row.finishRename(false)
                                        onActiveFocusChanged: if (!activeFocus && row.renaming) row.finishRename(true)
                                    }
                                }
                                IsleButton {
                                    Layout.alignment: Qt.AlignVCenter
                                    padding: 3
                                    icon: "isle-close-symbolic"
                                    iconSize: 9
                                    opacity: rowHover.hovered ? (hovered ? 1 : 0.5) : 0
                                    Behavior on opacity { NumberAnimation { duration: 120 } }
                                    onClicked: isle.daemon.call("Todo1", "Remove", [row.modelData.id], "t")
                                }
                            }
                            // the hairline under the text, from the title to the edge
                            Rectangle { Layout.fillWidth: true; height: 1; color: Qt.rgba(1, 1, 1, 0.1) }
                        }
                    }

                    function tick() {
                        if (folded)
                            return;
                        ticked = !ticked;
                        if (ticked)
                            linger.restart();
                        else
                            linger.stop();
                    }
                    function finishRename(save) {
                        if (!renaming)
                            return;
                        renaming = false;
                        const text = field.text.trim();
                        if (save && text && text !== modelData.title)
                            isle.daemon.call("Todo1", "Rename", [modelData.id, text], "ts");
                    }
                    // a ticked one stays 900 ms, struck through, then fades and folds away
                    Timer { id: linger; interval: 900; onTriggered: { row.fold = content.implicitHeight; row.folded = true; folding.start(); } }
                    ParallelAnimation {
                        id: folding
                        NumberAnimation { target: row; property: "fold"; to: 0; duration: 260; easing.type: Easing.OutQuad }
                        NumberAnimation { target: row; property: "opacity"; to: 0; duration: 260; easing.type: Easing.OutQuad }
                        onFinished: isle.daemon.call("Todo1", "SetDone", [row.modelData.id, true], "tb")
                    }
                }
            }

            // the last row: a faint ring and a field; typing a title and Enter adds it
            Component {
                id: newRow
                RowLayout {
                    width: list.width
                    height: 24
                    spacing: 10
                    Rectangle {
                        width: 18; height: 18; radius: 9
                        color: "transparent"
                        border.width: 1.5
                        border.color: Qt.rgba(1, 1, 1, 0.14)
                    }
                    TextInput { renderType: Text.QtRendering;
                        id: field
                        Layout.fillWidth: true
                        color: "white"
                        font { family: isle.font; pixelSize: 14; letterSpacing: -0.1 }
                        Text { renderType: Text.QtRendering;
                            visible: !parent.text && !parent.activeFocus || !parent.text
                            text: "New reminder"
                            color: Qt.rgba(1, 1, 1, 0.45)
                            font: parent.font
                        }
                        onAccepted: {
                            const t = text.trim();
                            if (t)
                                isle.daemon.call("Todo1", "Add", [t], "s");
                            text = "";
                            Qt.callLater(() => list.positionViewAtEnd());
                        }
                        Keys.onEscapePressed: { text = ""; focus = false; }
                        Component.onCompleted: newField = field
                    }
                }
            }
        }
    }
    property Item newField: null
}
