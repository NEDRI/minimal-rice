// The assistant, as Isle's voice.js and chat.js look, typed only: the conversation above (what you asked in
// bubbles, the answers as plain text, the time between turns that are far apart), and a row with the face,
// "Ask anything…" and send. isled's assistant answers only GNOME Shell, so in KDE the island asks Claude Code
// itself (`claude -p`), in a folder of its own, with no tools that change anything.
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasma5support as Plasma5Support

Item {
    id: comp
    property var isle
    property var messages: []          // {role: "user"|"assistant"|"error", text, at}
    property bool busy: false
    property bool started: false       // a conversation is under way: later turns continue it
    readonly property real contentHeight: Math.min(260, (messages.length ? Math.min(list.contentHeight + 10, 190) : 0) + 64)

    function ask(text) {
        text = text.trim();
        if (!text || busy)
            return;
        messages = messages.concat([{ role: "user", text: text, at: Date.now() }]);
        busy = true;
        // the question goes in on stdin, so nothing typed is ever read as an option
        const quoted = "'" + text.replace(/'/g, "'\\''") + "'";
        const system = "You are the assistant in a notch-style island on the KDE Plasma desktop of the user. "
            + "Answer briefly, in one to three sentences, in the language the user writes in. You cannot run commands or change files.";
        const cmd = "dir=\"${XDG_CACHE_HOME:-$HOME/.cache}/lorien-island-chat\"; mkdir -p \"$dir\" && cd \"$dir\" && "
            + "printf '%s' " + quoted + " | \"$HOME/.local/bin/claude\" -p " + (started ? "--continue " : "") + "--model sonnet "
            + "--disallowedTools 'Bash,Edit,Write,NotebookEdit,WebFetch,WebSearch,Task' "
            + "--append-system-prompt '" + system + "' 2>&1; printf '\\n#exit:%s\\n' $?";
        runner.connectSource(cmd);
        started = true;
    }
    function newChat() {
        messages = [];
        started = false;
    }

    Plasma5Support.DataSource {
        id: runner
        engine: "executable"
        onNewData: (source, data) => {
            const out = String(data.stdout || "");
            const m = /\n#exit:(\d+)\s*$/.exec(out);
            const text = out.replace(/\n#exit:\d+\s*$/, "").trim();
            const ok = m && m[1] === "0";
            comp.messages = comp.messages.concat([{ role: ok ? "assistant" : "error",
                text: ok ? text : (text || "Claude Code did not answer").split("\n").slice(-3).join(" "), at: Date.now() }]);
            comp.busy = false;
            disconnectSource(source);
            Qt.callLater(() => list.positionViewAtEnd());
        }
    }

    // the conversation
    ListView {
        id: list
        anchors { left: parent.left; right: parent.right; top: parent.top; bottom: row.top; leftMargin: 16; rightMargin: 16; topMargin: 10 }
        visible: comp.messages.length > 0
        clip: true
        spacing: 10
        model: comp.messages
        delegate: Item {
            required property var modelData
            required property int index
            readonly property bool gap: index > 0 && modelData.at - comp.messages[index - 1].at > 5 * 60000
            width: ListView.view.width
            height: (gap ? stamp.height + 6 : 0) + (modelData.role === "user" ? bubble.height : reply.implicitHeight)
            Text { renderType: Text.QtRendering
                id: stamp
                visible: parent.gap
                anchors.horizontalCenter: parent.horizontalCenter
                text: Qt.formatTime(new Date(modelData.at), "HH:mm")
                color: Qt.rgba(1, 1, 1, 0.35)
                font { family: isle.font; pixelSize: 11; weight: Font.DemiBold }
            }
            // what you asked, in a bubble on the right
            Rectangle {
                id: bubble
                visible: modelData.role === "user"
                anchors.right: parent.right
                y: parent.gap ? stamp.height + 6 : 0
                width: Math.min(420, userText.implicitWidth + 24)
                height: userText.implicitHeight + 12
                radius: 15
                color: Qt.rgba(1, 1, 1, 0.12)
                Text { renderType: Text.QtRendering
                    id: userText
                    anchors { fill: parent; leftMargin: 12; rightMargin: 12; topMargin: 6; bottomMargin: 6 }
                    text: modelData.text
                    wrapMode: Text.Wrap
                    color: "white"
                    font { family: isle.font; pixelSize: 13 }
                }
            }
            // its answer, as plain text
            Text { renderType: Text.QtRendering
                id: reply
                visible: modelData.role !== "user"
                y: parent.gap ? stamp.height + 6 : 0
                width: parent.width
                text: modelData.text
                wrapMode: Text.Wrap
                textFormat: Text.MarkdownText
                color: modelData.role === "error" ? "#ff453a" : Qt.rgba(1, 1, 1, 0.9)
                font { family: isle.font; pixelSize: 13 }
                onLinkActivated: link => Qt.openUrlExternally(link)
            }
        }
    }

    // the face, the field and send
    RowLayout {
        id: row
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom; leftMargin: 16; rightMargin: 16; bottomMargin: 14 }
        spacing: 12

        // Isle's assistant: a round "cloud" face that blinks, and looks busy while thinking
        Item {
            Layout.preferredWidth: 36
            Layout.preferredHeight: 36
            Rectangle {
                anchors.fill: parent
                radius: 18
                gradient: Gradient {
                    GradientStop { position: 0; color: "#f4f6fb" }
                    GradientStop { position: 1; color: "#c9d2e3" }
                }
                scale: comp.busy ? 0.94 : 1
                SequentialAnimation on scale {
                    running: comp.busy
                    loops: Animation.Infinite
                    NumberAnimation { to: 1.0; duration: 500; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 0.92; duration: 500; easing.type: Easing.InOutSine }
                }
                Row {
                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: -1
                    spacing: 8
                    Repeater {
                        model: 2
                        Rectangle {
                            id: eye
                            width: 4; height: 7; radius: 2
                            color: "#1c1c1e"
                            SequentialAnimation on height {
                                loops: Animation.Infinite
                                PauseAnimation { duration: 3200 + index * 30 }
                                NumberAnimation { to: 1; duration: 70 }
                                NumberAnimation { to: 7; duration: 90 }
                            }
                        }
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 34
            radius: height / 2
            color: field.activeFocus ? "#2c2c2e" : "#1c1c1e"
            border.width: field.activeFocus ? 1 : 0
            border.color: Qt.rgba(1, 1, 1, 0.16)
            TextInput { renderType: Text.QtRendering
                id: field
                anchors { left: parent.left; leftMargin: 14; right: send.left; rightMargin: 8; verticalCenter: parent.verticalCenter }
                color: "white"
                clip: true
                enabled: !comp.busy
                font { family: isle.font; pixelSize: 14 }
                Text { renderType: Text.QtRendering
                    visible: !parent.text
                    text: comp.busy ? "Thinking…" : "Ask anything…"
                    color: Qt.rgba(1, 1, 1, 0.45)
                    font: parent.font
                }
                onAccepted: { comp.ask(text); text = ""; }
                Keys.onEscapePressed: isle.close()
            }
            // a white round send button
            Rectangle {
                id: send
                anchors { right: parent.right; rightMargin: 4; verticalCenter: parent.verticalCenter }
                width: 26; height: 26; radius: 13
                color: field.text ? (sendArea.containsMouse ? Qt.rgba(1, 1, 1, 0.86) : "white") : Qt.rgba(1, 1, 1, 0.14)
                Behavior on color { ColorAnimation { duration: 150 } }
                IsleIcon { anchors.centerIn: parent; name: "isle-send-symbolic"; size: 13; color: field.text ? "black" : "white" }
                MouseArea { id: sendArea; anchors.fill: parent; hoverEnabled: true; onClicked: { comp.ask(field.text); field.text = ""; } }
            }
        }
    }

    function focusField() { field.forceActiveFocus(); }
}
