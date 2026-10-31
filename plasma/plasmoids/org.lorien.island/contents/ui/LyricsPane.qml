// Synced lyrics, as Isle's pages/lyrics.js: the sung line large and bright at 36 % of the view, those to
// come dimmer by distance, those sung dimmest; pauses as breathing dots. Click a line to jump there.
import QtQuick

Item {
    id: comp
    property var isle
    readonly property var lyrics: isle.lyrics
    readonly property bool synced: !!lyrics && lyrics.status === "synced"
    readonly property var lines: {
        const l = lyrics && lyrics.lines ? lyrics.lines.slice() : [];
        // a long intro opens with the pause dots
        if (synced && l.length && l[0].time_ms > 3000)
            l.unshift({ time_ms: 0, text: "" });
        return l;
    }
    readonly property int current: {
        if (!synced || !lines.length)
            return -1;
        let lo = 0, hi = lines.length - 1, found = -1;
        while (lo <= hi) {
            const mid = (lo + hi) >> 1;
            if (lines[mid].time_ms <= isle.positionMs) { found = mid; lo = mid + 1; } else hi = mid - 1;
        }
        return found;
    }
    property real manualUntil: 0

    // no lines: loading, not found, instrumental, or the service unreachable
    readonly property var states: ({
        loading: { dots: true, title: "Looking for lyrics" },
        not_found: { icon: "isle-lyrics", title: "No lyrics for this song", hint: "Lyrics come from LRCLIB" },
        instrumental: { icon: "isle-music", title: "Instrumental", hint: "Nothing to sing along to" },
        off: { icon: "isle-lyrics", title: "Lyrics are off", hint: "Turn them on in Isle’s settings" },
        error: { icon: "isle-lyrics", title: "Can’t reach the lyrics", hint: "Check your connection · trying again soon" },
        unavailable: { icon: "isle-lyrics", title: "Lyrics are busy right now", hint: "Trying again in a moment" },
    })
    readonly property var stateShown: !lines.length ? (states[lyrics ? lyrics.status : "loading"] || states.loading) : null

    Column {
        anchors.centerIn: parent
        visible: !!comp.stateShown
        spacing: 3
        IsleIcon { anchors.horizontalCenter: parent.horizontalCenter; visible: !!(comp.stateShown && comp.stateShown.icon)
                   name: comp.stateShown && comp.stateShown.icon ? comp.stateShown.icon : ""; size: 22; opacity: 0.4 }
        PauseDots { anchors.horizontalCenter: parent.horizontalCenter; visible: !!(comp.stateShown && comp.stateShown.dots)
                    breathing: visible; dotColor: Qt.rgba(1, 1, 1, 0.6) }
        Text { renderType: Text.QtRendering; anchors.horizontalCenter: parent.horizontalCenter; text: comp.stateShown ? comp.stateShown.title : ""
               color: Qt.rgba(1, 1, 1, 0.85); font { family: isle.font; pixelSize: 14; weight: Font.DemiBold } }
        Text { renderType: Text.QtRendering; anchors.horizontalCenter: parent.horizontalCenter; visible: text !== ""
               text: comp.stateShown && comp.stateShown.hint ? comp.stateShown.hint : ""
               color: Qt.rgba(1, 1, 1, 0.55); font { family: isle.font; pixelSize: 12 } }
    }

    Flickable {
        id: flick
        anchors.fill: parent
        visible: comp.lines.length > 0
        clip: true
        contentWidth: width
        contentHeight: column.height + 72
        boundsBehavior: Flickable.StopAtBounds
        onMovementStarted: comp.manualUntil = Date.now() + 4000

        Behavior on contentY { enabled: Date.now() > comp.manualUntil; NumberAnimation { duration: 520; easing.type: Easing.OutCubic } }

        Column {
            id: column
            width: flick.width
            spacing: 2
            Repeater {
                id: rows
                model: comp.lines
                Item {
                    id: row
                    readonly property int distance: index - comp.current
                    readonly property bool isCurrent: distance === 0
                    readonly property string words: (modelData.text || "").trim()
                    width: column.width
                    height: comp.synced && !words ? 25 : line.implicitHeight + 4
                    opacity: !comp.synced ? 1 : isCurrent ? 1 : distance < 0 ? 75 / 255
                        : [150, 115, 90][Math.min(distance - 1, 2)] / 255
                    scale: !comp.synced || isCurrent ? 1 : 0.93
                    transformOrigin: Item.Left
                    Behavior on opacity { NumberAnimation { duration: 380 } }
                    Behavior on scale { NumberAnimation { duration: 380 } }

                    Text { renderType: Text.QtRendering;
                        id: line
                        visible: !(comp.synced && !row.words)
                        width: parent.width
                        wrapMode: Text.Wrap
                        text: row.words || "♪"
                        color: "white"
                        font { family: isle.font; pixelSize: comp.synced ? 18 : 14; weight: comp.synced ? Font.Bold : Font.Medium
                               letterSpacing: comp.synced ? -0.3 : 0 }
                    }
                    PauseDots { visible: comp.synced && !row.words; y: 9; breathing: row.isCurrent && isle.playing }
                    MouseArea {
                        anchors.fill: parent
                        enabled: comp.synced
                        cursorShape: Qt.PointingHandCursor
                        onClicked: isle.daemon.call("Media1", "SetPosition", [modelData.time_ms * 1000], "x")
                    }
                }
            }
        }
    }

    // the sung line glides to 36 % of the view
    function follow() {
        if (current < 0 || Date.now() < manualUntil || !rows.itemAt(current))
            return;
        const item = rows.itemAt(current);
        const middle = item.y + item.height / 2;
        flick.contentY = Math.max(0, Math.min(flick.contentHeight - flick.height, middle - flick.height * 0.36));
    }
    onCurrentChanged: Qt.callLater(follow)
    onVisibleChanged: if (visible) Qt.callLater(follow)
    onLinesChanged: { flick.contentY = 0; Qt.callLater(follow); }
}
