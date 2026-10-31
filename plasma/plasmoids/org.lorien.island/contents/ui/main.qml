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
import org.kde.plasma.plasma5support as Plasma5Support
import org.kde.plasma.workspace.dbus as DBus
import org.kde.plasma.private.volume as Vol
import org.kde.plasma.private.keyboardindicator as KeyboardIndicator
import org.kde.notificationmanager as NotificationManager

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
    property string mode: "closed"        // closed | open | peek | assistant
    property string page: "music"
    property string musicMode: "player"     // player | lyrics | audio, on the Music page
    // the open island is 600 px, 720 with the lyrics beside the player
    readonly property int openWidth: page === "music" && musicMode === "lyrics" && hasTrack ? 720 : expandedWidth
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

    readonly property var lyrics: isled.lyrics
    readonly property var tasks: isled.tasks
    readonly property var clipboard: isled.clipboard
    readonly property var shelf: isled.shelf
    readonly property var events: isled.events
    readonly property var usage: isled.usage
    readonly property bool hasUsage: !!(usage && usage.providers && usage.providers.length)
    readonly property alias appUsage: appUsageTracker
    AppUsage { id: appUsageTracker }
    function copyText(text) { isled.copyText(text); }
    // copies a clipboard card again and moves it to the front
    function copyClip(item) {
        if (item.kind === "files" && item.uris && item.uris.length)
            isled.copyText(item.uris.join("\n"));
        else
            isled.copyText(item.preview || "");
        isled.call("Clipboard1", "Touch", [item.id], "t");
    }

    // Do Not Disturb is Plasma's own: until a date, here one far off (on until turned off)
    NotificationManager.Settings { id: notificationSettings }
    readonly property bool dnd: notificationSettings.notificationsInhibitedUntil > now
    function toggleDnd() {
        const until = new Date();
        if (!dnd)
            until.setFullYear(until.getFullYear() + 100);
        notificationSettings.notificationsInhibitedUntil = until;
        notificationSettings.save();
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
    // the assistant: from the header's sparkle, or Super+I (the widget's shortcut)
    function openAssistant() {
        alertTimer.stop();
        mode = "assistant";
        Qt.callLater(() => { island.requestActivate(); assistantView.focusField(); });
    }
    Plasmoid.onActivated: mode === "assistant" ? close() : openAssistant()
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
            if (mode !== "open" && mode !== "assistant" && !alertHoldsHover)
                expandTimer.restart();
        } else {
            expandTimer.stop();
            if (mode === "open")
                collapseTimer.restart();
        }
    }
    Timer { id: expandTimer; interval: root.hoverDelay; onTriggered: if (root.hovered) root.open() }
    Timer { id: collapseTimer; interval: root.collapseDelay; onTriggered: if (!root.hovered) root.close() }

    // ---- alerts, as Isle's alerts.js: one at a time, the newest replacing the one shown ----
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
    function dismissAlert() {
        alertTimer.stop();
        if (mode === "peek")
            mode = "closed";
    }
    // a click on an alert: what it is about (a notification opens), else its page
    function activateAlert() {
        const a = alert;
        dismissAlert();
        if (a && a.onActivate)
            a.onActivate();
        else if (a && a.page)
            open(a.page);
    }
    // an alert with buttons or a ×: the pointer goes there to press them, not to open the island
    readonly property bool alertHoldsHover: mode === "peek" && !!alert && (!!alert.closable || !!(alert.actions && alert.actions.length))

    Connections {
        target: isled
        function onSystemEvent(e) {
            const pct = Math.round(e.percent || 0) + "%";
            if (e.kind === "power")
                root.showAlert({ key: "power", icon: e.plugged ? "isle-bolt" : e.percent <= 20 ? "isle-battery-low-symbolic" : "isle-battery-symbolic",
                    ring: e.percent / 100, ringIconSize: e.plugged ? 12 : 14, title: e.plugged ? "Charging" : "On battery",
                    subtitle: e.plugged ? "Charger connected" : "Charger disconnected", value: pct,
                    tone: e.plugged ? "good" : e.percent <= 20 ? "bad" : "neutral", duration: 2600 });
            else if (e.kind === "battery_low")
                root.showAlert({ key: "power", icon: "isle-battery-low-symbolic", ring: e.percent / 100, ringIconSize: 14, title: "Low battery",
                    subtitle: "Plug in your charger soon", value: pct, tone: "bad", duration: 8000 });
            else if (e.kind === "battery_full")
                root.showAlert({ key: "power", icon: "isle-bolt", ring: 1, title: "Fully charged",
                    subtitle: "You can unplug your charger", value: "100%", tone: "good", duration: 2600 });
            else if (e.kind === "network" && !e.connected)
                root.showAlert({ key: "network", icon: "isle-wifi-off-symbolic", title: "Offline",
                    subtitle: "The network connection was lost", tone: "bad", duration: 2600 });
            else if (e.kind === "bluetooth" && e.device) {
                const battery = e.connected && e.device.battery !== undefined && e.device.battery !== null ? e.device.battery : null;
                root.showAlert({ key: "bluetooth:" + e.device.path, icon: "isle-bluetooth-symbolic",
                    ring: battery !== null ? battery / 100 : null, title: e.device.name,
                    subtitle: e.connected ? "Connected" : "Disconnected", value: battery !== null ? Math.round(battery) + "%" : "",
                    tone: !e.connected ? "neutral" : battery !== null && battery < 20 ? "bad" : "good", duration: 2600 });
            }
        }
        // a phase ended; when the next one waits to be started, a button starts it
        // an AI plan limit nears its end: the provider's logo in a ring of the share
        function onUsageAlert(provider, window, percent, resetsAt) {
            const name = provider.toLowerCase();
            const [span, model] = window.split(" · ");
            const limit = window === "5 hours" ? "5-hour limit" : ((span === "Week" ? "Weekly" : span) + (model ? " " + model : "") + " limit");
            const at = new Date(resetsAt);
            const when = resetsAt - Date.now() < 20 * 3600e3 ? Qt.formatTime(at, "HH:mm") : Qt.formatDate(at, "ddd") + " " + Qt.formatTime(at, "HH:mm");
            root.showAlert({ key: "usage:" + provider + ":" + window,
                icon: name.indexOf("claude") >= 0 ? "isle-claude" : name.indexOf("grok") >= 0 ? "isle-grok"
                    : name.indexOf("gpt") >= 0 || name.indexOf("codex") >= 0 ? "isle-openai" : "isle-gauge",
                ring: Math.min(1, percent / 100), title: provider,
                subtitle: resetsAt > 0 ? limit + " · resets " + when : limit, value: Math.round(percent) + "%",
                tone: Math.round(percent) >= 95 ? "bad" : name.indexOf("claude") >= 0 ? "claude" : name.indexOf("grok") >= 0 ? "grok"
                    : name.indexOf("gpt") >= 0 || name.indexOf("codex") >= 0 ? "codex" : "neutral",
                duration: 8000, page: "usage" });
        }
        function onPhaseFinished(finished, next) {
            const state = root.pomodoro;
            const waiting = !state || !state.running;
            const minutes = state ? Math.round(state.duration_ms / 60000) : 0;
            const start = { label: finished === "focus" ? "Start break" : "Start focus", callback: () => { isled.call("Pomodoro1", "Start"); root.dismissAlert(); } };
            if (finished === "focus")
                root.showAlert({ key: "pomodoro", icon: "isle-timer-symbolic", title: "Focus session done",
                    subtitle: waiting ? "Take a break when you’re ready" : "Enjoy a " + minutes + "-minute break",
                    tone: "good", actions: waiting ? [start] : [], duration: 8000, page: "focus" });
            else
                root.showAlert({ key: "pomodoro", icon: "isle-timer-symbolic",
                    title: next === "focus" ? "Break is over" : next === "long_break" ? "Long break" : "Break",
                    subtitle: waiting ? "Ready for another focus session?" : minutes + " minutes of focus",
                    tone: "focus", actions: waiting ? [start] : [], duration: 8000, page: "focus" });
        }
    }

    // ---- Usage: isled reads Claude Code's sign-in, which lasts 8 hours; `claude auth status` renews it
    // without using the plan, then isled is asked again ----
    property real usageRenewedAt: 0
    onUsageChanged: {
        const stale = usage && usage.providers && usage.providers.some(p => (p.note || "").indexOf("refresh its sign-in") >= 0);
        if (stale && Date.now() - usageRenewedAt > 10 * 60000) {
            usageRenewedAt = Date.now();
            renewSignIn.connectSource("\"$HOME/.local/bin/claude\" auth status >/dev/null 2>&1; echo renewed");
        }
    }
    Plasma5Support.DataSource {
        id: renewSignIn
        engine: "executable"
        onNewData: (source) => { disconnectSource(source); isled.call("Usage1", "Refresh"); }
    }

    // ---- Plasma's on-screen displays (volume, brightness, toggles) come to the island instead ----
    readonly property var osdKinds: [
        ["audio-volume", "Volume"], ["microphone-sensitivity-muted", "Microphone", "Muted"], ["microphone", "Microphone"],
        ["input-keyboard-brightness", "Keyboard light"], ["keyboard-brightness", "Keyboard light"],
        ["video-display-brightness", "Brightness"], ["display-brightness", "Brightness"],
        ["input-touchpad-off", "Touchpad", "Off"], ["touchpad-disabled", "Touchpad", "Off"], ["input-touchpad", "Touchpad", "On"],
        ["airplane-mode-disabled", "Airplane mode", "Off"], ["airplane-mode", "Airplane mode", "On"],
        ["network-wireless-off", "Wi-Fi", "Off"], ["network-wireless-disabled", "Wi-Fi", "Off"], ["network-wireless", "Wi-Fi", "On"],
        ["preferences-system-bluetooth-inactive", "Bluetooth", "Off"], ["bluetooth-disabled", "Bluetooth", "Off"],
        ["preferences-system-bluetooth", "Bluetooth", "On"], ["bluetooth", "Bluetooth", "On"],
    ]
    function osdAlert(icon, text, percent, max) {
        const found = osdKinds.find(k => icon.startsWith(k[0]));
        const kind = found ? found[1] : "";
        const hasLevel = percent !== undefined && percent !== null;
        // KDE says "Touchpad On": the kind as the title, the state as a pill
        const onOff = /^(.*)\s+(On|Off)$/.exec(text || "");
        const level = hasLevel ? percent / (max || 100) : null;
        const muted = icon.indexOf("muted") >= 0;
        const sinkName = kind === "Volume" && osdSink.sink ? osdSink.sink.description : "";
        const volumeIcon = muted || level === 0 ? "isle-speaker-off-symbolic" : level < 0.34 ? "isle-speaker-1-symbolic"
            : level < 0.67 ? "isle-speaker-2-symbolic" : "isle-speaker-3-symbolic";
        showAlert({ key: "osd",
            icon: kind === "Volume" ? volumeIcon : kind === "Brightness" ? "isle-sun-symbolic" : kind === "Keyboard light" ? "isle-keyboard-symbolic"
                : kind === "Touchpad" ? (found[2] === "Off" ? "isle-touchpad-off-symbolic" : "isle-touchpad-symbolic")
                : kind === "Wi-Fi" ? (found[2] === "Off" ? "isle-wifi-off-symbolic" : "isle-wifi-symbolic")
                : kind === "Bluetooth" ? (found[2] === "Off" ? "isle-bluetooth-off-symbolic" : "isle-bluetooth-symbolic")
                : kind === "Airplane mode" ? "isle-airplane-symbolic" : kind === "Microphone" ? (muted ? "isle-mic-off-symbolic" : "isle-mic-symbolic")
                : icon,
            title: kind || (onOff ? onOff[1] : text) || icon,
            subtitle: hasLevel ? (kind === "Volume" ? (muted ? "Muted" : sinkName) : kind === "Brightness" ? "Built-in Display"
                : kind === "Keyboard light" ? "Keyboard" : (text || "")) : "",
            status: hasLevel ? "" : (found && found[2]) || (onOff ? onOff[2] : ""),
            level: hasLevel ? Math.min(1, level) : null,
            levelText: hasLevel ? Math.round(percent) + "%" : "",
            tone: "neutral", duration: 1500 });
        // Plasma shows its own OSD for the same change: put it away once it is up
        osdHide.restart();
    }
    Timer {
        id: osdHide
        interval: 60
        property int round: 0
        onTriggered: {
            DBus.SessionBus.asyncCall({ service: "org.kde.plasmashell", path: "/org/kde/osdService", iface: "org.kde.osdService",
                member: "hide", arguments: [], signature: "" });
            if (++round < 3)
                restart();
            else
                round = 0;
        }
    }

    // Plasma does not hear its own OSD signals, and the island lives inside Plasma: the island watches what
    // the OSDs are about itself. Volume and microphone from PulseAudio, brightness from powerdevil.
    QtObject { id: osdSink; readonly property var sink: Vol.PreferredDevice.sink; readonly property var source: Vol.PreferredDevice.source }
    property var watchedSink: null
    property bool osdReady: false
    Timer { interval: 3000; running: true; onTriggered: { root.watchedSink = osdSink.sink; root.osdReady = true; } }
    Connections {
        target: osdSink.sink
        ignoreUnknownSignals: true
        function onVolumeChanged() { root.volumeOsd(); }
        function onMutedChanged() { root.volumeOsd(); }
    }
    function volumeOsd() {
        const sink = osdSink.sink;
        if (!osdReady || !sink || sink !== watchedSink) {
            watchedSink = sink;     // another output: no alert for the switch itself
            return;
        }
        osdAlert(sink.muted ? "audio-volume-muted" : "audio-volume-high", "", Math.round(sink.volume / 65536 * 100), 100);
    }
    Connections {
        target: osdSink.source
        ignoreUnknownSignals: true
        function onMutedChanged() {
            if (root.osdReady && osdSink.source)
                root.osdAlert(osdSink.source.muted ? "microphone-sensitivity-muted" : "microphone-sensitivity-high",
                    osdSink.source.muted ? "Microphone Off" : "Microphone On", null, null);
        }
    }
    DBus.SignalWatcher {
        busType: DBus.BusType.Session
        service: "org.kde.ScreenBrightness"
        path: "/org/kde/ScreenBrightness"
        iface: "org.kde.ScreenBrightness"
        function dbusBrightnessChanged(display, brightness) {
            const b = Number(brightness.value ?? brightness);
            const reply = DBus.SessionBus.asyncCall({ service: "org.kde.ScreenBrightness", path: "/org/kde/ScreenBrightness/" + String(display.value ?? display),
                iface: "org.freedesktop.DBus.Properties", member: "Get", arguments: ["org.kde.ScreenBrightness.Display", "MaxBrightness"], signature: "(ss)" });
            reply.finished.connect(() => {
                const v = reply.values[0];
                const max = Number(v && v.value !== undefined ? (v.value.value ?? v.value) : v) || 100;
                root.osdAlert("display-brightness", "", Math.round(b / max * 100), 100);
            });
        }
    }
    DBus.SignalWatcher {
        busType: DBus.BusType.Session
        service: "org.kde.Solid.PowerManagement"
        path: "/org/kde/Solid/PowerManagement/Actions/KeyboardBrightnessControl"
        iface: "org.kde.Solid.PowerManagement.Actions.KeyboardBrightnessControl"
        function dbusKeyboardBrightnessChanged(value) {
            const v = Number(value.value ?? value);
            const reply = DBus.SessionBus.asyncCall({ service: "org.kde.Solid.PowerManagement",
                path: "/org/kde/Solid/PowerManagement/Actions/KeyboardBrightnessControl",
                iface: "org.kde.Solid.PowerManagement.Actions.KeyboardBrightnessControl", member: "keyboardBrightnessMax", arguments: [], signature: "" });
            reply.finished.connect(() => {
                const m = reply.values[0];
                const max = Number(m && m.value !== undefined ? m.value : m) || 1;
                root.osdAlert("keyboard-brightness", "", Math.round(v / max * 100), 100);
            });
        }
    }

    // ---- Caps Lock: it rises only when turned on ----
    KeyboardIndicator.KeyState {
        id: capsLock
        key: Qt.Key_CapsLock
        property bool ready: false
        onLockedChanged: if (ready) root.showAlert({ key: "keyboard", icon: "isle-capslock-symbolic", title: "Caps Lock",
            status: locked ? "On" : "Off", tone: "neutral", duration: 1500 })
        Component.onCompleted: Qt.callLater(() => ready = true)
    }

    // ---- a new song that starts playing peeks in: its cover, with the player's icon ----
    property string lastTrack: ""
    readonly property string trackKey: hasTrack ? nowPlaying.title + "\u001f" + nowPlaying.artist : ""
    onTrackKeyChanged: {
        const changed = trackKey !== lastTrack;
        const first = lastTrack === "" && !trackStarted;
        lastTrack = trackKey;
        trackStarted = true;
        if (changed && trackKey && playing && !first && !dnd && !(mode === "open" && page === "music"))
            showAlert({ key: "track", art: nowPlaying.art_path, artBadge: nowPlaying.desktop_entry || "",
                title: nowPlaying.title, subtitle: nowPlaying.artist || nowPlaying.identity, duration: 2600, page: "music" });
    }
    property bool trackStarted: false

    // ---- notifications pop up in the island instead of Plasma's banners (Isle's gnome-banners: off) ----
    NotificationManager.Notifications {
        id: popups
        showExpired: false
        showDismissed: false
        showJobs: false
        groupMode: NotificationManager.Notifications.GroupDisabled
        sortMode: NotificationManager.Notifications.SortByDate
        sortOrder: Qt.DescendingOrder
        property bool ready: false
        onRowsInserted: (parent, first, last) => {
            if (!ready)
                return;
            for (let i = first; i <= last; i++)
                root.notificationAlert(index(i, 0));
        }
        Component.onCompleted: Qt.callLater(() => ready = true)
    }
    // the same list with the expired ones, to act on a notification after its banner was put away
    NotificationManager.Notifications {
        id: allNotifications
        showExpired: true
        showDismissed: true
        showJobs: false
        groupMode: NotificationManager.Notifications.GroupDisabled
    }
    function findNotification(id) {
        for (let i = 0; i < allNotifications.count; i++) {
            const idx = allNotifications.index(i, 0);
            if (allNotifications.data(idx, NotificationManager.Notifications.IdRole) === id)
                return idx;
        }
        return null;
    }
    function notificationAlert(idx) {
        const N = NotificationManager.Notifications;
        if (popups.data(idx, N.TypeRole) !== N.NotificationType)
            return;
        const urgent = popups.data(idx, N.UrgencyRole) === N.CriticalUrgency;
        if (dnd && !urgent)
            return;
        const id = popups.data(idx, N.IdRole);
        const names = popups.data(idx, N.ActionNamesRole) || [];
        const labels = popups.data(idx, N.ActionLabelsRole) || [];
        const image = popups.data(idx, N.ImageRole);
        const body = String(popups.data(idx, N.BodyRole) || "").replace(/<[^>]*>/g, "").replace(/\s+/g, " ").trim();
        const act = name => () => { const i = findNotification(id); if (i) allNotifications.invokeAction(i, name, N.Close); root.dismissAlert(); };
        const buttons = names.slice(0, 3).map((name, k) => ({ label: labels[k] || name, primary: k === Math.min(names.length, 3) - 1, callback: act(name) }));
        const appIcon = popups.data(idx, N.ApplicationIconNameRole) || popups.data(idx, N.IconNameRole) || "dialog-information";
        const title = String(popups.data(idx, Qt.DisplayRole) || popups.data(idx, N.ApplicationNameRole) || "").replace(/\s+/g, " ").trim();
        const transient = !!popups.data(idx, N.TransientRole);
        // its banner from Plasma goes; the notification stays in the list (read everything first: it leaves this model)
        popups.expire(idx);
        showAlert({ key: "notification:" + id, kind: "notification", closable: true,
            appIcon: appIcon, title: title,
            subtitle: body, subtitleLines: 2,
            actions: buttons, tone: urgent ? "bad" : "neutral",
            duration: urgent ? 20000 : transient ? 2500 : 4000, page: "notifications",
            onActivate: () => { const i = findNotification(id); if (i && allNotifications.data(i, N.HasDefaultActionRole))
                allNotifications.invokeDefaultAction(i, N.Close); else root.open("notifications"); } });
    }

    // ---- the springs: Isle's island spring (~3.5 % overshoot) for size, a gentler one for the corners ----
    readonly property var target: mode === "assistant"
        ? { width: expandedWidth, height: barHeight + assistantView.contentHeight, radius: 26, shoulder: 13 }
        : mode === "open"
        ? { width: openWidth, height: barHeight + pageHeight + bottomPadding, radius: shapes.open.radius, shoulder: shapes.open.shoulder }
        : mode === "peek"
        ? { width: 2 * Math.round(Math.max(peekMeasure.preferredWidth, closedWidth) / 2), height: peekMeasure.preferredHeight, radius: shapes.peek.radius, shoulder: shapes.peek.shoulder }
        : { width: 2 * Math.round(closedWidth / 2), height: barHeight, radius: shapes.closed.radius, shoulder: shapes.closed.shoulder }
    Item {
        visible: false
        Spring { id: springW; target: root.target.width }
        Spring { id: springH; target: root.target.height }
        Spring { id: springR; damping: 25; target: root.target.radius }
        Spring { id: springS; damping: 25; target: root.target.shoulder }
    }
    // a copy of the alert that is only measured: laid out (so its words wrap) but never seen
    Peek { id: peekMeasure; isle: root; alert: root.alert; opacity: 0; enabled: false; width: root.mode === "peek" ? root.target.width : 380; height: 1 }
    FrameAnimation {
        running: !(springW.settled && springH.settled && springR.settled && springS.settled)
        onTriggered: { springW.step(frameTime); springH.step(frameTime); springR.step(frameTime); springS.step(frameTime); }
    }

    preferredRepresentation: fullRepresentation
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground

    // ================================================================ the part in the bar
    fullRepresentation: Item {
        id: slot

        // as wide as the closed island; open, it reaches over the empty spacers on either side
        Layout.preferredWidth: 2 * Math.round(root.closedWidth / 2) + 2 * root.shapes.closed.shoulder
        Layout.minimumWidth: Layout.preferredWidth
        Layout.fillHeight: true

        readonly property bool hovered: slotHover.hovered

        // the panel window's top in this item's coordinates, so the island hangs from the screen edge even
        // when the panel gives the widget a margin; the bar as drawn is 36 px of a slightly taller window
        property real winTop: 0
        readonly property real winHeight: Math.min(Window.height > 0 ? Window.height : height, 36)
        function measure() { winTop = -mapToItem(null, 0, 0).y; }
        onYChanged: Qt.callLater(measure)
        Timer { interval: 2000; running: true; repeat: true; onTriggered: slot.measure() }
        onHeightChanged: Qt.callLater(measure)
        Window.onHeightChanged: Qt.callLater(measure)
        // open, the island reaches over its neighbours in the bar: lift this applet above them
        function raise() {
            for (let p = slot; p && p.parent; p = p.parent)
                p.z = 1000;
        }
        Component.onCompleted: {
            Qt.callLater(measure);
            Qt.callLater(raise);
            root.slotItem = slot;
            root.barHeight = Qt.binding(() => slot.winHeight);
        }

        Item {
            y: slot.winTop
            x: (slot.width - width) / 2
            width: 720 + 2 * root.shapes.open.shoulder
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
                        else if (root.mode === "peek")
                            root.activateAlert();
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
                    x: 28
                    width: parent.width - 28 - 24
                    height: root.barHeight
                    opacity: root.mode === "open" ? 1 : 0
                    visible: opacity > 0
                    Behavior on opacity { NumberAnimation { duration: root.mode === "open" ? 320 : 160 } }
                }
                // the assistant's header: its name, and a new chat
                Item {
                    x: 16
                    width: parent.width - 32
                    height: root.barHeight
                    opacity: root.mode === "assistant" ? 1 : 0
                    visible: opacity > 0
                    Behavior on opacity { NumberAnimation { duration: root.mode === "assistant" ? 320 : 160 } }
                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 6
                        IsleIcon { anchors.verticalCenter: parent.verticalCenter; name: "isle-sparkle-symbolic"; size: 13; opacity: 0.6 }
                        Text { renderType: Text.QtRendering; anchors.verticalCenter: parent.verticalCenter
                               text: assistantView.messages.length ? "Chat" : "Assistant"; color: Qt.rgba(1, 1, 1, 0.45)
                               font { family: root.font; pixelSize: 12; weight: Font.DemiBold } }
                    }
                    IsleButton {
                        anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                        visible: assistantView.messages.length > 0
                        padding: 5; icon: "isle-plus-symbolic"; iconSize: 12
                        color: hovered ? Qt.rgba(1, 1, 1, 0.16) : Qt.rgba(1, 1, 1, 0.08)
                        onClicked: assistantView.newChat()
                    }
                }
                Peek {
                    isle: root
                    alert: root.alert
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: root.target.width
                    height: peekMeasure.preferredHeight
                    onCloseRequested: root.dismissAlert()
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

        readonly property int winWidth: 720 + 2 * root.shapes.open.shoulder
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
            // the panel may have moved the widget since (its margins come later): measure again
            root.slotItem.measure();
            const p = root.slotItem.mapToGlobal(root.slotItem.width / 2, root.slotItem.winTop + root.barHeight);
            origin = Qt.point(Math.round(p.x - winWidth / 2), Math.round(p.y));
        }
        onVisibleChanged: if (visible) place()
        onActiveChanged: if (!active && (root.mode === "open" || root.mode === "assistant")) root.close()

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
                    // clicks on the island stay on it; on an alert they open what it is about
                    MouseArea { anchors.fill: parent; onClicked: if (root.mode === "peek") root.activateAlert() }

                    Peek {
                        isle: root
                        alert: root.alert
                        y: -root.barHeight
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: root.target.width
                        height: peekMeasure.preferredHeight
                    onCloseRequested: root.dismissAlert()
                        opacity: root.mode === "peek" ? 1 : 0
                        visible: opacity > 0
                        Behavior on opacity { NumberAnimation { duration: root.mode === "peek" ? 320 : 160 } }
                    }

                    // the open page under the header (.isle-page: 6 px 28 px 0)
                    Item {
                        anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: 6 }
                        width: root.openWidth - 56
                        height: root.pageHeight - 6
                        opacity: root.mode === "open" ? 1 : 0
                        visible: opacity > 0
                        Behavior on opacity { NumberAnimation { duration: root.mode === "open" ? 320 : 160 } }

                        MusicPage { isle: root; anchors.fill: parent; visible: root.page === "music" }
                        NotificationsPage { isle: root; anchors.fill: parent; visible: root.page === "notifications" }
                        FocusPage { isle: root; anchors.fill: parent; visible: root.page === "focus" }
                        RemindersPage { isle: root; anchors.fill: parent; visible: root.page === "reminders" }
                        ShelfPage { isle: root; anchors.fill: parent; visible: root.page === "shelf" }
                        CalendarPage { isle: root; anchors.fill: parent; visible: root.page === "calendar" }
                        AppsPage { isle: root; anchors.fill: parent; visible: root.page === "apps" }
                        UsagePage { isle: root; anchors.fill: parent; visible: root.page === "usage" }
                    }

                    // the assistant, under its header in the bar; kept while closed, so the chat stays
                    AssistantView {
                        id: assistantView
                        isle: root
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: root.expandedWidth
                        height: contentHeight
                        opacity: root.mode === "assistant" ? 1 : 0
                        visible: opacity > 0
                        Behavior on opacity { NumberAnimation { duration: root.mode === "assistant" ? 320 : 160 } }
                    }
                }
            }
        }
    }
}
