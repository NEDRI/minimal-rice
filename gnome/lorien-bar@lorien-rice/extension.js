// Lorien Bar: the GNOME counterpart of the KDE rice's top bar. The panel becomes transparent and
// every panel button an island with a dark fill and an accent-coloured border; the dock gets the
// same border. The accent comes from ~/.cache/lorien-accent-GNOME, which
// ~/.local/share/lorien-rice/accent-from-wallpaper.py rewrites whenever the wallpaper changes,
// so the bar follows the wallpaper.
import Gio from 'gi://Gio';
import GLib from 'gi://GLib';
import Meta from 'gi://Meta';
import St from 'gi://St';
import {Extension, InjectionManager} from 'resource:///org/gnome/shell/extensions/extension.js';
import * as Main from 'resource:///org/gnome/shell/ui/main.js';

const FALLBACK = '#b589d6';
// Waywallen draws the live wallpaper in a monitor-sized window of its own; with nothing else open
// GNOME takes it for a fullscreen app and hides the top bar, the dock and Isle.
const RENDERER_ID = 'io.github.waywallen.WaywallenRenderer';
const ACCENT_FILE = GLib.build_filenamev([GLib.get_user_cache_dir(), 'lorien-accent-GNOME']);

function readAccent() {
    try {
        const [, bytes] = GLib.file_get_contents(ACCENT_FILE);
        const hex = new TextDecoder().decode(bytes).trim();
        if (/^#[0-9a-fA-F]{6}$/.test(hex))
            return hex;
    } catch (e) {
        // no accent yet: the watcher hasn't run in this session
    }
    return FALLBACK;
}

// The styles live in style-template.css next to this file and are read on every accent change, so
// they can be tweaked without logging out. @ACCENT@ is the accent as #rrggbb, @R@ @G@ @B@ its
// channels (for rgba()).
function css(dir, hex) {
    const [, bytes] = GLib.file_get_contents(GLib.build_filenamev([dir, 'style-template.css']));
    return new TextDecoder().decode(bytes)
        .replaceAll('@ACCENT@', hex)
        .replaceAll('@R@', String(parseInt(hex.slice(1, 3), 16)))
        .replaceAll('@G@', String(parseInt(hex.slice(3, 5), 16)))
        .replaceAll('@B@', String(parseInt(hex.slice(5, 7), 16)));
}

export default class LorienBar extends Extension {
    enable() {
        // a monitor counts as fullscreen only when a real window on it is fullscreen
        this._injection = new InjectionManager();
        this._injection.overrideMethod(Meta.Display.prototype, 'get_monitor_in_fullscreen',
            original => function (monitor) {
                if (!original.call(this, monitor))
                    return false;
                const workspace = global.workspace_manager.get_active_workspace();
                return this.list_all_windows().some(w =>
                    w.get_monitor() === monitor && w.is_fullscreen() && !w.minimized &&
                    w.located_on_workspace(workspace) && !w.title?.includes(RENDERER_ID));
            });
        // Mutter only announces a fullscreen change when its own answer changes, so the shell can
        // keep a "fullscreen" state taken before this extension loaded, or when the wallpaper window
        // appears after the last app closed. Ask the bar, the dock and Isle to look again whenever
        // windows come and go.
        this._signals = [];
        const wm = global.window_manager;
        for (const sig of ['map', 'destroy', 'minimize', 'unminimize'])
            this._signals.push([wm, wm.connect(sig, () => this._recheckFullscreen())]);
        const ws = global.workspace_manager;
        this._signals.push([ws, ws.connect('active-workspace-changed', () => this._recheckFullscreen())]);
        this._signals.push([Main.layoutManager,
            Main.layoutManager.connect('startup-complete', () => this._recheckFullscreen())]);
        this._recheckFullscreen();
        this._theme = St.ThemeContext.get_for_stage(global.stage).get_theme();
        this._file = null;
        this._apply();
        // the accent file is rewritten on every wallpaper change, the template when restyling
        this._monitors = [ACCENT_FILE, GLib.build_filenamev([this.path, 'style-template.css'])].map(p => {
            const monitor = Gio.File.new_for_path(p).monitor_file(Gio.FileMonitorFlags.NONE, null);
            monitor.connect('changed', (_m, _f, _o, event) => {
                // files are rewritten in place: wait until the write is done
                if (event === Gio.FileMonitorEvent.CHANGES_DONE_HINT || event === Gio.FileMonitorEvent.CREATED)
                    this._apply();
            });
            return monitor;
        });
    }

    disable() {
        this._signals?.forEach(([obj, id]) => obj.disconnect(id));
        this._signals = null;
        if (this._recheckId)
            GLib.source_remove(this._recheckId);
        this._recheckId = 0;
        this._injection?.clear();
        this._injection = null;
        global.display.emit('in-fullscreen-changed');
        this._monitors?.forEach(m => m.cancel());
        this._monitors = null;
        this._unload();
        this._theme = null;
    }

    _recheckFullscreen() {
        // after the window animations, when the window stack has settled
        if (this._recheckId)
            GLib.source_remove(this._recheckId);
        this._recheckId = GLib.timeout_add(GLib.PRIORITY_DEFAULT, 400, () => {
            this._recheckId = 0;
            global.display.emit('in-fullscreen-changed');
            return GLib.SOURCE_REMOVE;
        });
    }

    _apply() {
        const hex = readAccent();
        let text;
        try {
            text = css(this.path, hex);
        } catch (e) {
            logError(e, 'lorien-bar: cannot read style-template.css');
            return;
        }
        this._unload();
        // a new file each time: St caches stylesheets by file
        this._serial = (this._serial ?? 0) + 1;
        const path = GLib.build_filenamev([GLib.get_user_runtime_dir(), `lorien-bar-${this._serial}.css`]);
        GLib.file_set_contents(path, text);
        this._file = Gio.File.new_for_path(path);
        this._theme.load_stylesheet(this._file);
    }

    _unload() {
        if (!this._file)
            return;
        this._theme.unload_stylesheet(this._file);
        try {
            this._file.delete(null);
        } catch (e) {
            // already gone
        }
        this._file = null;
    }
}
