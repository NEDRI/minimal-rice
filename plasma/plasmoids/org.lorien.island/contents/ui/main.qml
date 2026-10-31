// Island: Isle's notch-style island (https://github.com/zickrian/isle, GPL-3.0-or-later) for KDE Plasma.
// Its look and behaviour follow Isle's own code, and its data comes from Isle's background service, isled,
// over D-Bus. Closed, it hangs from the top edge of the screen as deep as the bar, with small concave
// shoulders; hovered or clicked, it springs open into a 600 px card with pages; power changes make it peek.
//
// Plasma keeps its own windows below the panels, so the island is drawn in two parts that share the same
// springs and the same outline: the bar-high top in the panel (this widget), and the rest in a borderless
// window right under the bar. Together they read as one shape.
import QtQuick
import QtQuick.Layouts
import QtQuick.Window
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    // ---- Isle's sizes (CSS px), from controller.js, expanded.js, compact.js and peek.js ----
    readonly property int expandedWidth: 600
    readonly property int pageHeight: 150
    readonly property int bottomPadding: 14
    readonly property int compactWidth: 144        // the clock alone, inside the bar
    readonly property int activitiesWidth: 232     // with music or the timer
    readonly property var shapes: ({
        closed: { radius: 10, shoulder: 7 },
        open: { radius: 32, shoulder: 22 },
        peek: { radius: 28, shoulder: 13 },
    })
    readonly property int peekHeight: 32 + 2 * 12
    readonly property int hoverDelay: 120
    readonly property int collapseDelay: 300
    readonly property string font: Qt.fontFamilies().indexOf("Inter Variable") >= 0 ? "Inter Variable"
        : Qt.fontFamilies().indexOf("Inter") >= 0 ? "Inter" : Kirigami.Theme.defaultFont.family

    // ---- state ----
    property string mode: "closed"        // closed | open | peek
    property string page: "music"
    property var alert: null
    property date now: new Date()
    property real nowMs: Date.now()
    property int barHeight: 36
    readonly property color dim: Qt.rgba(1, 1, 1, 0.55)

    // ---- isled ----
    readonly property alias daemon: isled
    IsleDaemon { id: isled }

    readonly property var nowPlaying: isled.nowPlaying
    readonly property bool hasTrack: !!(nowPlaying && nowPlaying.available && nowPlaying.title)
    readonly property bool playing: hasTrack && nowPlaying.status === "Playing"
    readonly property string artUrl: hasTrack && nowPlaying.art_path ? "file://" + nowPlaying.art_path : ""
    readonly property real lengthMs: hasTrack ? nowPlaying.length_us / 1000 : 0
    readonly property real positionMs: {
        if (!hasTrack)
            return 0;
        let p = nowPlaying.position_us / 1000;
        if (playing)
            p += (nowMs - nowPlaying.sampled_at_ms) * (nowPlaying.rate || 1);
        return lengthMs > 0 ? Math.max(0, Math.min(p, lengthMs)) : Math.max(0, p);
    }

    readonly property var pomodoro: isled.pomodoro
    readonly property var pomodoroConfig: isled.pomodoroConfig
    readonly property bool hasTimer: !!(pomodoro && pomodoro.phase !== "idle")
    readonly property real timerRemainingMs: !pomodoro ? 25 * 60000
        : pomodoro.running ? Math.max(0, pomodoro.ends_at_ms - nowMs) : pomodoro.remaining_ms
    readonly property real timerProgress: pomodoro && pomodoro.duration_ms > 0 ? 1 - timerRemainingMs / pomodoro.duration_ms : 0
    // white while focusing, green on a break
    readonly property color timerColor: !pomodoro || pomodoro.phase === "focus" || pomodoro.phase === "idle" ? "white" : "#30d158"

    // the closed island's width: wider with an activity, wider still with the timer's time beside the bars
    TextMetrics { id: secondMetrics; font.family: root.font; font.pixelSize: 15; font.weight: Font.DemiBold; text: "00:00" }
    readonly property real closedWidth: (hasTrack || hasTimer ? activitiesWidth : compactWidth)
        + (hasTrack && hasTimer ? 2 * (secondMetrics.width + 8) : 0)

    function mmss(seconds) {
        const s = Math.max(0, Math.ceil(seconds - 0.001));
        const h = Math.floor(s / 3600), m = Math.floor(s % 3600 / 60), r = s % 60;
        return (h ? h + ":" + String(m).padStart(2, "0") : m) + ":" + String(r).padStart(2, "0");
    }

    Timer {
        // fast enough for the scrubber and the timer; a quiet tick otherwise
        interval: root.playing || (root.pomodoro && root.pomodoro.running) ? 250 : 1000
        repeat: true
        running: true
        onTriggered: { root.now = new Date(); root.nowMs = Date.now(); }
    }

    function open(p) {
        if (p)
            page = p;
        mode = "open";
        Qt.callLater(() => island.requestActivate());
    }
    function close() {
        expandTimer.stop();
        collapseTimer.stop();
        mode = alert && alertTimer.running ? "peek" : "closed";
    }

    // ---- hover: resting on the island opens it, leaving closes it (Isle's open-on: hover) ----
    readonly property bool hovered: (slotItem && slotItem.hovered) || islandHover.hovered
    onHoveredChanged: {
        if (hovered) {
            collapseTimer.stop();
            if (mode !== "open")
                expandTimer.restart();
        } else {
            expandTimer.stop();
            if (mode === "open")
                collapseTimer.restart();
        }
    }
    Timer { id: expandTimer; interval: root.hoverDelay; onTriggered: if (root.hovered) root.open() }
    Timer { id: collapseTimer; interval: root.collapseDelay; onTriggered: if (!root.hovered) root.close() }

    // ---- alerts, as Isle's alerts.js `system` ----
    Timer {
        id: alertTimer
        onTriggered: {
            if (root.mode === "peek")
                root.mode = "closed";
        }
    }
    function showAlert(a) {
        alert = a;
        alertTimer.interval = a.duration;
        alertTimer.restart();
        if (mode !== "open")
            mode = "peek";
    }
    Connections {
        target: isled
        function onSystemEvent(e) {
            const pct = Math.round(e.percent || 0) + "%";
            if (e.kind === "power")
                root.showAlert({ icon: e.plugged ? "isle-bolt" : e.percent <= 20 ? "isle-battery-low-symbolic" : "isle-battery-symbolic",
                    ring: e.percent / 100, title: e.plugged ? "Charging" : "On battery",
                    subtitle: e.plugged ? "Charger connected" : "Charger disconnected", value: pct,
                    tone: e.plugged ? "good" : e.percent <= 20 ? "bad" : "neutral", duration: 2600 });
            else if (e.kind === "battery_low")
                root.showAlert({ icon: "isle-battery-low-symbolic", ring: e.percent / 100, title: "Low battery",
                    subtitle: "Plug in your charger soon", value: pct, tone: "bad", duration: 8000 });
            else if (e.kind === "battery_full")
                root.showAlert({ icon: "isle-bolt", ring: 1, title: "Fully charged",
                    subtitle: "You can unplug your charger", value: "100%", tone: "good", duration: 2600 });
            else if (e.kind === "network" && !e.connected)
                root.showAlert({ icon: "isle-wifi-off-symbolic", title: "Offline",
                    subtitle: "The network connection was lost", tone: "bad", duration: 2600 });
        }
        function onPhaseFinished(finished, next) {
            const pause = next === "short_break" || next === "long_break";
            root.showAlert({ icon: "isle-timer-symbolic", title: pause ? "Time for a break" : "Back to focus",
                subtitle: pause ? "Focus session done" : "Break is over", tone: pause ? "good" : "neutral", duration: 8000 });
        }
    }

    // ---- the springs: Isle's island spring (~3.5 % overshoot) for size, a gentler one for the corners ----
    readonly property var target: mode === "open"
        ? { width: expandedWidth, height: barHeight + pageHeight + bottomPadding, radius: shapes.open.radius, shoulder: shapes.open.shoulder }
        : mode === "peek"
        ? { width: 2 * Math.round(Math.max(peekMeasure.preferredWidth, closedWidth) / 2), height: peekHeight, radius: shapes.peek.radius, shoulder: shapes.peek.shoulder }
        : { width: 2 * Math.round(closedWidth / 2), height: barHeight, radius: shapes.closed.radius, shoulder: shapes.closed.shoulder }
    Item {
        visible: false
        Spring { id: springW; target: root.target.width }
        Spring { id: springH; target: root.target.height }
        Spring { id: springR; damping: 25; target: root.target.radius }
        Spring { id: springS; damping: 25; target: root.target.shoulder }
        Peek { id: peekMeasure; isle: root; alert: root.alert }   // only measured
    }
    FrameAnimation {
        running: !(springW.settled && springH.settled && springR.settled && springS.settled)
        onTriggered: { springW.step(frameTime); springH.step(frameTime); springR.step(frameTime); springS.step(frameTime); }
    }

    preferredRepresentation: fullRepresentation
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground

    // ================================================================ the part in the bar
    fullRepresentation: Item {
        id: slot

        // room for the open island and its shoulders; the spacers on either side give way
        Layout.preferredWidth: root.expandedWidth + 2 * root.shapes.open.shoulder
        Layout.minimumWidth: Layout.preferredWidth
        Layout.fillHeight: true

        readonly property bool hovered: slotHover.hovered

        // the panel window's top in this item's coordinates, so the island hangs from the screen edge even
        // when the panel gives the widget a margin; the bar as drawn is 36 px of a slightly taller window
        property real winTop: 0
        readonly property real winHeight: Math.min(Window.height > 0 ? Window.height : height, 36)
        function measure() { winTop = -mapToItem(null, 0, 0).y; }
        onYChanged: Qt.callLater(measure)
        onHeightChanged: Qt.callLater(measure)
        Window.onHeightChanged: Qt.callLater(measure)
        Component.onCompleted: {
            Qt.callLater(measure);
            root.slotItem = slot;
            root.barHeight = Qt.binding(() => slot.winHeight);
        }

        Item {
            y: slot.winTop
            width: slot.width
            height: slot.winHeight

            IslandShape {
                anchors.fill: parent
                bodyWidth: springW.value; bodyHeight: springH.value; radius: springR.value; shoulder: springS.value
            }

            Item {
                x: (parent.width - springW.value) / 2
                width: springW.value
                height: parent.height
                clip: true

                HoverHandler { id: slotHover }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                    onClicked: mouse => {
                        if (mouse.button === Qt.MiddleButton && root.hasTrack)
                            isled.call("Media1", "PlayPause");
                        else
                            root.mode === "open" ? root.close() : root.open();
                    }
                }

                CompactRow {
                    isle: root
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 2 * Math.round(root.closedWidth / 2)
                    height: root.barHeight
                    opacity: root.mode === "closed" ? 1 : 0
                    visible: opacity > 0
                    Behavior on opacity { NumberAnimation { duration: root.mode === "closed" ? 320 : 160 } }
                }
                // .isle-header: 0 24 px 0 28 px
                Header {
                    isle: root
                    x: (parent.width - root.expandedWidth) / 2 + 28
                    width: root.expandedWidth - 28 - 24
                    height: root.barHeight
                    opacity: root.mode === "open" ? 1 : 0
                    visible: opacity > 0
                    Behavior on opacity { NumberAnimation { duration: root.mode === "open" ? 320 : 160 } }
                }
                Peek {
                    isle: root
                    alert: root.alert
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: root.target.width
                    height: root.peekHeight
                    opacity: root.mode === "peek" ? 1 : 0
                    visible: opacity > 0
                    Behavior on opacity { NumberAnimation { duration: root.mode === "peek" ? 320 : 160 } }
                }
            }
        }
    }

    property Item slotItem: null

    // ================================================================ the part below the bar
    PlasmaCore.Dialog {
        id: island

        readonly property int winWidth: root.expandedWidth + 2 * root.shapes.open.shoulder
        readonly property real depth: springH.value - root.barHeight
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

            Item {
                width: parent.width
                height: Math.max(0, island.depth) + 2
                clip: true

                // the same outline as in the bar, shifted up by the bar's height
                IslandShape {
                    y: -root.barHeight
                    width: parent.width
                    height: springH.value
                    bodyWidth: springW.value; bodyHeight: springH.value; radius: springR.value; shoulder: springS.value
                }

                Item {
                    x: (parent.width - springW.value) / 2
                    width: springW.value
                    height: Math.max(0, island.depth)
                    clip: true

                    HoverHandler { id: islandHover }
                    MouseArea { anchors.fill: parent }   // clicks on the island stay on it

                    Peek {
                        isle: root
                        alert: root.alert
                        y: -root.barHeight
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: root.target.width
                        height: root.peekHeight
                        opacity: root.mode === "peek" ? 1 : 0
                        visible: opacity > 0
                        Behavior on opacity { NumberAnimation { duration: root.mode === "peek" ? 320 : 160 } }
                    }

                    // the open page under the header (.isle-page: 6 px 28 px 0)
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
}
