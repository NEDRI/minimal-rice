// App usage, as Isle's appUsage.js: the app in front is timed, and the time is kept per day. isled keeps
// it for Isle in GNOME but takes reports only from GNOME Shell, so here the island keeps it itself, in its
// own settings, and adds what it timed every minute.
import QtQuick
import org.kde.plasma.plasmoid
import org.kde.taskmanager as TaskManager
import org.kde.plasma.plasma5support as Plasma5Support

Item {
    id: usage

    property var store: { try { return JSON.parse(Plasmoid.configuration.appUsage || "{}"); } catch (e) { return {}; } }
    property string current: ""
    property real since: Date.now()
    property int revision: 0          // bumps when the store changes, for views to re-read

    TaskManager.TasksModel { id: tasks }
    readonly property var active: tasks.activeTask

    function appOf(index) {
        if (!index || !index.valid)
            return null;
        const id = tasks.data(index, TaskManager.AbstractTasksModel.AppId) || "";
        if (!id)
            return null;
        const launcher = String(tasks.data(index, TaskManager.AbstractTasksModel.LauncherUrlWithoutIcon) || "");
        return { id: id, name: tasks.data(index, TaskManager.AbstractTasksModel.AppName) || id,
                 desktop: launcher.replace(/^applications:/, "").replace(/^file:\/\/.*\//, "") };
    }

    function dayKey(ms) { return Qt.formatDate(new Date(ms), "yyyy-MM-dd"); }

    // adds the time since `since` to the app in front, split at midnight
    function flush() {
        const now = Date.now();
        if (current && now > since) {
            const s = store;
            s.days = s.days || {};
            let from = since;
            while (from < now) {
                const midnight = new Date(from); midnight.setHours(24, 0, 0, 0);
                const to = Math.min(now, midnight.getTime());
                const day = dayKey(from);
                s.days[day] = s.days[day] || {};
                s.days[day][current] = (s.days[day][current] || 0) + (to - from);
                from = to;
            }
            // keep 30 days
            const oldest = dayKey(now - 31 * 86400000);
            for (const d in s.days)
                if (d < oldest)
                    delete s.days[d];
            store = s;
            Plasmoid.configuration.appUsage = JSON.stringify(s);
            revision++;
        }
        since = now;
    }

    onActiveChanged: {
        flush();
        const app = appOf(active);
        current = app ? app.id : "";
        if (app) {
            const s = store;
            s.apps = s.apps || {};
            const known = s.apps[app.id];
            s.apps[app.id] = [app.name, Array.isArray(known) ? known[1] : ""];
            store = s;
            if (!Array.isArray(known) || !known[1])
                findIcon(app.id, app.desktop || app.id + ".desktop");
        }
    }
    Timer { interval: 60000; running: true; repeat: true; onTriggered: usage.flush() }

    // the app's icon, from its .desktop file
    function findIcon(id, desktop) {
        const file = desktop.endsWith(".desktop") ? desktop : desktop + ".desktop";
        iconLookup.connectSource("for d in \"$HOME/.local/share/applications\" /usr/share/applications /var/lib/flatpak/exports/share/applications "
            + "\"$HOME/.local/share/flatpak/exports/share/applications\" \"$HOME/.nix-profile/share/applications\"; do "
            + "[ -f \"$d/" + file.replace(/[^A-Za-z0-9._-]/g, "") + "\" ] && sed -n 's/^Icon=//p' \"$d/" + file.replace(/[^A-Za-z0-9._-]/g, "")
            + "\" | head -1 && break; done; echo '#" + id.replace(/[^A-Za-z0-9._-]/g, "") + "'");
    }
    Plasma5Support.DataSource {
        id: iconLookup
        engine: "executable"
        onNewData: (source, data) => {
            const lines = (data.stdout || "").trim().split("\n");
            const id = (lines.pop() || "").replace(/^#/, "");
            const icon = lines[0] || "";
            const s = usage.store;
            if (s.apps && s.apps[id]) {
                s.apps[id] = [s.apps[id][0], icon || id];
                usage.store = s;
                Plasmoid.configuration.appUsage = JSON.stringify(s);
                usage.revision++;
            }
            disconnectSource(source);
        }
    }

    // [{id, name, ms}] for the last `days` days, most used first
    function stats(days) {
        revision;   // re-read when it changes
        const out = {};
        const s = store.days || {};
        const first = dayKey(Date.now() - (days - 1) * 86400000);
        for (const d in s)
            if (d >= first)
                for (const id in s[d])
                    out[id] = (out[id] || 0) + s[d][id];
        // the app in front now counts too
        if (current)
            out[current] = (out[current] || 0) + (Date.now() - since);
        const apps = store.apps || {};
        const info = id => Array.isArray(apps[id]) ? apps[id] : [apps[id] || id, ""];
        return Object.keys(out).map(id => ({ id: id, name: info(id)[0], icon: info(id)[1] || id, ms: out[id] }))
            .filter(a => a.ms > 0).sort((a, b) => b.ms - a.ms);
    }
}
