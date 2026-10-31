// isled, Isle's own background service, over D-Bus: it watches the music, keeps the focus timer and
// reports power and network changes, for the island here as for Isle in GNOME. Properties hold JSON.
import QtQuick
import org.kde.plasma.workspace.dbus as DBus

Item {
    id: daemon

    readonly property string service: "io.github.zickrian.isle.Daemon"
    readonly property string path: "/io/github/zickrian/isle/Daemon"
    readonly property bool running: watcher.registered

    readonly property var nowPlaying: parse(media.properties.NowPlaying)
    readonly property var lyrics: parse(media.properties.Lyrics)
    readonly property var pomodoro: parse(pomodoroProps.properties.State)
    readonly property var pomodoroConfig: parse(pomodoroProps.properties.Config)
    readonly property var system: parse(systemProps.properties.State)
    readonly property var tasks: parse(todo.properties.Items)

    signal systemEvent(var event)
    signal phaseFinished(string finished, string next)

    function parse(v) {
        if (v === undefined || v === null)
            return null;
        try {
            return JSON.parse(v.value !== undefined ? v.value : v);
        } catch (e) {
            return null;
        }
    }

    // call("Media1", "PlayPause"), call("Media1", "SetPosition", [12000000], "x")
    function call(iface, member, args, signature) {
        DBus.SessionBus.asyncCall({
            service: daemon.service, path: daemon.path, iface: "io.github.zickrian.isle." + iface,
            member: member, arguments: args || [], signature: signature ? "(" + signature + ")" : "",
        });
    }

    DBus.DBusServiceWatcher {
        id: watcher
        busType: DBus.BusType.Session
        watchedService: daemon.service
    }

    component Props: DBus.Properties {
        busType: DBus.BusType.Session
        service: daemon.service
        path: daemon.path
    }
    Props { id: media; iface: "io.github.zickrian.isle.Media1" }
    Props { id: pomodoroProps; iface: "io.github.zickrian.isle.Pomodoro1" }
    Props { id: systemProps; iface: "io.github.zickrian.isle.System1" }
    Props { id: todo; iface: "io.github.zickrian.isle.Todo1" }

    DBus.SignalWatcher {
        busType: DBus.BusType.Session
        service: daemon.service
        path: daemon.path
        iface: "io.github.zickrian.isle.System1"
        function dbusEvent(event) { const e = daemon.parse(event); if (e) daemon.systemEvent(e); }
    }
    DBus.SignalWatcher {
        busType: DBus.BusType.Session
        service: daemon.service
        path: daemon.path
        iface: "io.github.zickrian.isle.Pomodoro1"
        function dbusPhaseFinished(finished, next) { daemon.phaseFinished(String(finished.value ?? finished), String(next.value ?? next)); }
    }

    // isled (re)started: read everything again, and ask for lyrics (Isle's lyrics-online, on by default)
    onRunningChanged: if (running) {
        media.updateAll(); pomodoroProps.updateAll(); systemProps.updateAll(); todo.updateAll();
        call("Media1", "SetLyrics", [true], "b");
    }
    Component.onCompleted: if (running) call("Media1", "SetLyrics", [true], "b")
}
