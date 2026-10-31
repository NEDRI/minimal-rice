// Island: a KDE port of Isle's notch-style island (https://github.com/zickrian/isle, GPL-3.0-or-later).
// In the top bar it is a black pill with the clock, the album art and dancing bars while music plays,
// or the focus timer. A click springs it open into a 600 px card that hangs from the top of the screen,
// with Music, Focus and Calendar pages; plugging in the charger makes it peek with the battery level.
// The open island lives in its own borderless window over the bar, starting from the pill's place and
// size and springing back into it, so the two read as one shape.
import QtQuick
import QtQuick.Layouts
import QtQuick.Window
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasma5support as Plasma5Support
import org.kde.kirigami as Kirigami
import org.kde.plasma.private.mpris as Mpris

PlasmoidItem {
    id: root

    // ---- Isle's sizes (CSS px) ----
    readonly property int expandedWidth: 600
    readonly property int pageHeight: 150
    readonly property int bottomPadding: 14
    readonly property int expandedRadius: 32
    readonly property int peekRadius: 28
    readonly property int pillRadius: 10
    readonly property int idleWidth: 144
    readonly property int activityWidth: 232
    readonly property string font: Qt.fontFamilies().indexOf("Inter Variable") >= 0 ? "Inter Variable"
        : Qt.fontFamilies().indexOf("Inter") >= 0 ? "Inter" : Kirigami.Theme.defaultFont.family
    readonly property color dim: Qt.rgba(1, 1, 1, 0.55)
    readonly property color green: "#30d158"

    // ---- state ----
    property string mode: "closed"        // closed | open | peek
    property string page: "music"         // music | focus | calendar
    property date now: new Date()

    readonly property var player: mpris.currentPlayer
    readonly property bool hasMusic: player !== null && player.track !== ""
        && player.playbackStatus !== Mpris.PlaybackStatus.Stopped
    readonly property bool playing: hasMusic && player.playbackStatus === Mpris.PlaybackStatus.Playing

    // focus timer (Isle's Focus page): 25 min of focus, then a 5 min break
    property int focusMinutes: 25
    property int breakMinutes: 5
    property string timerPhase: "idle"     // idle | focus | break
    property bool timerRunning: false
    property int timerLeft: focusMinutes * 60
    readonly property int timerTotal: (timerPhase === "break" ? breakMinutes : focusMinutes) * 60
    readonly property bool hasTimer: timerPhase !== "idle"

    readonly property bool activity: hasMusic || hasTimer
    readonly property int pillWidth: activity ? activityWidth : idleWidth

    preferredRepresentation: fullRepresentation
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    toolTipMainText: ""
    toolTipSubText: ""

    function clock(d) { return Qt.formatTime(d, "HH:mm"); }
    function mmss(s) {
        s = Math.max(0, Math.round(s));
        return Math.floor(s / 60) + ":" + String(s % 60).padStart(2, "0");
    }

    function open(p) {
        if (p)
            page = p;
        mode = "open";
        Qt.callLater(() => island.requestActivate());
    }
    function close() { mode = "closed"; }

    Mpris.Mpris2Model { id: mpris }

    Timer {
        interval: 1000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: {
            root.now = new Date();
            if (root.playing)
                root.player.updatePosition();
            if (root.timerRunning) {
                root.timerLeft -= 1;
                if (root.timerLeft <= 0) {
                    // focus done: a break; break done: back to idle
                    if (root.timerPhase === "focus") {
                        root.timerPhase = "break";
                        root.timerLeft = root.breakMinutes * 60;
                    } else {
                        root.timerPhase = "idle";
                        root.timerRunning = false;
                        root.timerLeft = root.focusMinutes * 60;
                    }
                    root.peekText = root.timerPhase === "break" ? "Break" : "Focus done";
                    root.peekSub = root.timerPhase === "break" ? root.breakMinutes + " min" : "Well done";
                    root.peekValue = "";
                    root.peekIcon = "\u{F13AB}";
                    root.peek();
                }
            }
        }
    }

    // ---- charging peek, as Isle's alerts ----
    property string peekIcon: ""
    property string peekText: ""
    property string peekSub: ""
    property string peekValue: ""

    function peek() {
        if (mode === "open")
            return;
        mode = "peek";
        peekTimer.restart();
    }
    Timer {
        id: peekTimer
        interval: 3000
        onTriggered: if (root.mode === "peek") root.close()
    }

    Plasma5Support.DataSource {
        id: power
        engine: "powermanagement"
        connectedSources: ["Battery", "AC Adapter"]
        property bool plugged: data["AC Adapter"] ? !!data["AC Adapter"]["Plugged in"] : false
        property int percent: data["Battery"] ? Number(data["Battery"]["Percent"] || 0) : 0
        property bool ready: false
        onPluggedChanged: {
            if (!ready)
                return;
            root.peekIcon = plugged ? "\u{F0084}" : "\u{F0079}";
            root.peekText = plugged ? "Charging" : "On battery";
            root.peekSub = plugged ? "Plugged in" : "Charger unplugged";
            root.peekValue = percent + "%";
            root.peek();
        }
        Component.onCompleted: Qt.callLater(() => ready = true)
    }

    // ================================================================ one shape, two windows
    // Plasma keeps its own windows below the panel, so the island is drawn in two parts that share
    // the same springs: the bar-high top in the panel (the pill, which grows into the header) and the
    // rest in a borderless window right under the panel. Together they hang from the screen's top edge.
    Item {
        visible: false
        // width of the whole island, its total height from the top of the screen, bottom radius,
        // and how open it is (0 = the pill, 1 = hanging from the screen edge)
        Spring { id: w; target: root.mode === "open" ? root.expandedWidth : root.mode === "peek" ? 320 : root.pillWidth }
        Spring { id: h; target: root.mode === "open" ? root.barHeight + root.pageHeight + root.bottomPadding
                                : root.mode === "peek" ? root.barHeight + 52 : root.barHeight }
        Spring { id: r; damping: 25
                 target: root.mode === "open" ? root.expandedRadius : root.mode === "peek" ? root.peekRadius : root.pillRadius }
        Spring { id: o; damping: 25; precision: 0.002; target: root.mode === "closed" ? 0 : 1 }
    }
    readonly property bool moving: !(w.settled && h.settled && r.settled && o.settled)
    property int barHeight: 36

    FrameAnimation {
        running: root.moving
        onTriggered: { w.step(frameTime); h.step(frameTime); r.step(frameTime); o.step(frameTime); }
    }

    // ---------------------------------------------------------------- the part in the bar
    fullRepresentation: Item {
        id: slot

        // as wide as the open island, so it can grow in place; the spacers on both sides give way
        Layout.preferredWidth: root.expandedWidth
        Layout.minimumWidth: root.expandedWidth
        Layout.fillHeight: true

        // the panel window's top and height, in this item's coordinates: the island reaches to the
        // screen edge even when the panel gives the widget a margin
        property real winTop: 0
        function measure() { winTop = -mapToItem(null, 0, 0).y; }
        onYChanged: Qt.callLater(measure)
        onHeightChanged: Qt.callLater(measure)
        Window.onHeightChanged: Qt.callLater(measure)
        // the bar as drawn: the panel window is a little taller than the bar (36 px in the Lorien layout)
        readonly property real winHeight: Math.min(Window.height > 0 ? Window.height : height, 36)

        Component.onCompleted: {
            Qt.callLater(measure);
            root.slotItem = slot;
            root.barHeight = Qt.binding(() => slot.winHeight);
        }

        Rectangle {
            id: pill

            readonly property real pillHeight: Math.min(slot.winHeight - 8, 28)
            readonly property real pillY: slot.winTop + (slot.winHeight - pillHeight) / 2
            x: (slot.width - width) / 2
            width: w.value
            // from the pill in the bar's middle to the full bar height at the screen edge
            y: pillY + (slot.winTop - pillY) * o.value
            height: pillHeight + (slot.winHeight - pillHeight) * o.value
            color: "black"
            topLeftRadius: root.pillRadius * (1 - o.value)
            topRightRadius: root.pillRadius * (1 - o.value)
            bottomLeftRadius: root.pillRadius * (1 - o.value)
            bottomRightRadius: root.pillRadius * (1 - o.value)
            clip: true

            CompactRow {
                isle: root
                width: parent.width
                height: pill.pillHeight
                anchors.verticalCenter: parent.verticalCenter
                opacity: root.mode === "closed" ? 1 : 0
                visible: opacity > 0
                Behavior on opacity { NumberAnimation { duration: root.mode === "closed" ? 320 : 160 } }
            }

            Header {
                isle: root
                anchors { fill: parent; leftMargin: 28; rightMargin: 24 }
                opacity: root.mode === "open" ? 1 : 0
                visible: opacity > 0
                Behavior on opacity { NumberAnimation { duration: root.mode === "open" ? 320 : 160 } }
            }

            MouseArea {
                anchors.fill: parent
                z: -1
                cursorShape: Qt.PointingHandCursor
                acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                onClicked: mouse => {
                    if (mouse.button === Qt.MiddleButton && root.hasMusic)
                        root.player.PlayPause();
                    else
                        root.mode === "open" ? root.close() : root.open();
                }
            }
        }
    }

    property Item slotItem: null

    // ---------------------------------------------------------------- the part below the bar
    PlasmaCore.Dialog {
        id: island

        readonly property int winWidth: root.expandedWidth + 40
        readonly property real depth: h.value - root.barHeight   // how far it reaches below the bar
        property point origin: Qt.point(0, 0)

        type: PlasmaCore.Dialog.AppletPopup
        location: PlasmaCore.Types.Floating
        backgroundHints: PlasmaCore.Dialog.NoBackground
        flags: Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint
        hideOnWindowDeactivate: false
        visible: root.mode !== "closed" || depth > 0.5
        x: origin.x
        y: origin.y

        function place() {
            if (!root.slotItem)
                return;
            const p = root.slotItem.mapToGlobal(root.slotItem.width / 2, root.slotItem.winTop + root.barHeight);
            origin = Qt.point(Math.round(p.x - winWidth / 2), Math.round(p.y));
        }
        onVisibleChanged: if (visible) place()
        onActiveChanged: if (!active && root.mode === "open") root.close()

        mainItem: Item {
            width: island.winWidth
            height: root.pageHeight + root.bottomPadding + 20
            focus: true
            Keys.onEscapePressed: root.close()

            // a click beside the island closes it
            MouseArea {
                anchors.fill: parent
                onClicked: root.close()
            }

            Rectangle {
                id: shape
                x: (parent.width - width) / 2
                width: w.value
                height: Math.max(0, island.depth)
                color: "black"
                clip: true
                bottomLeftRadius: Math.min(r.value, height)
                bottomRightRadius: Math.min(r.value, height)

                MouseArea { anchors.fill: parent }   // clicks on the island stay on it

                // peek: charging and timer alerts
                RowLayout {
                    anchors { left: parent.left; right: parent.right; top: parent.top; leftMargin: 14; rightMargin: 18; topMargin: 4 }
                    height: 40
                    spacing: 10
                    opacity: root.mode === "peek" ? 1 : 0
                    visible: opacity > 0
                    Behavior on opacity { NumberAnimation { duration: root.mode === "peek" ? 320 : 160 } }

                    Rectangle {
                        Layout.preferredWidth: 36; Layout.preferredHeight: 36
                        radius: 18
                        color: "#1c1c1e"
                        Text {
                            anchors.centerIn: parent
                            text: root.peekIcon
                            color: root.peekText === "Charging" || root.peekText === "Break" ? root.green : "white"
                            font { family: "JetBrainsMono Nerd Font"; pixelSize: 18 }
                        }
                    }
                    ColumnLayout {
                        spacing: 0
                        Layout.fillWidth: true
                        Text { text: root.peekText; color: "white"; font { family: root.font; pixelSize: 14; weight: Font.DemiBold } }
                        Text { text: root.peekSub; color: Qt.rgba(1, 1, 1, 0.5); font { family: root.font; pixelSize: 12 } }
                    }
                    Text {
                        text: root.peekValue
                        color: "white"
                        font { family: root.font; pixelSize: 20; weight: Font.DemiBold; letterSpacing: -0.5 }
                        font.features: { "tnum": 1 }
                    }
                }

                // open: the page under the header
                Item {
                    anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: 6 }
                    width: root.expandedWidth - 56
                    height: root.pageHeight - 6
                    opacity: root.mode === "open" ? 1 : 0
                    visible: opacity > 0
                    Behavior on opacity { NumberAnimation { duration: root.mode === "open" ? 320 : 160 } }

                    MusicPage { isle: root; anchors.fill: parent; visible: root.page === "music" }
                    FocusPage { isle: root; anchors.fill: parent; visible: root.page === "focus" }
                    CalendarPage { isle: root; anchors.fill: parent; visible: root.page === "calendar" }
                }
            }
        }
    }
}
