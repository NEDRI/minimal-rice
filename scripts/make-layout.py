#!/usr/bin/env python3
"""Generate the Plasma layout script (top bar + dock + desktop widgets) for the Lorien-style rice."""
import copy, glob, json, os, subprocess

HERE = os.path.dirname(os.path.abspath(__file__))
PRESET = os.path.expanduser(
    "~/.local/share/plasma/plasmoids/luisbocanegra.panel.colorizer/contents/ui/presets/Rounded Widgets/settings.json")


def color(custom, alpha=1.0, source=0, **extra):
    c = {"enabled": True, "custom": custom, "alpha": alpha, "sourceType": source, "followColor": 0}
    c.update(extra)
    return c


def colorizer(panel_bg, island_bg, radius, panel_radius=0):
    g = json.load(open(PRESET))["globalSettings"]
    g.pop("stockPanelSettings", None)
    p, w, t = g["panel"]["normal"], g["widgets"]["normal"], g["trayWidgets"]["normal"]
    p["backgroundColor"].update(panel_bg)
    p["radius"] = {"enabled": panel_radius > 0, "corner": dict.fromkeys(["topLeft", "topRight", "bottomRight", "bottomLeft"], panel_radius)}
    w["backgroundColor"].update(island_bg)
    w["foregroundColor"].update(color("#eeeeee"))
    w["radius"] = {"enabled": True, "corner": dict.fromkeys(["topLeft", "topRight", "bottomRight", "bottomLeft"], radius)}
    w["margin"] = {"enabled": True, "side": {"left": 0, "right": 0, "top": 4, "bottom": 4}}
    w["spacing"] = 6
    t["backgroundColor"]["enabled"] = False
    g["nativePanel"] = {"background": {"enabled": False, "opacity": 1, "shadow": False},
                        "floatingDialogs": False, "floatingDialogsAllowOverride": False}
    return {"globalSettings": json.dumps(g, separators=(",", ":"))}


def user_preset(name):
    """Load a Panel Colorizer preset from ~/.config/panel-colorizer/presets as applet config values."""
    d = json.load(open(os.path.expanduser(f"~/.config/panel-colorizer/presets/{name}/settings.json")))
    return {k: v if isinstance(v, bool) else json.dumps(v, separators=(",", ":")) for k, v in d.items()}


# True: the author's own presets (mayanklad/cachyos-kde-pixel-rice), a transparent top bar
# whose colours come from the wallpaper. False: a painted pink -> violet -> green gradient.
AUTHOR_PRESETS = True

if AUTHOR_PRESETS:
    top_cfg = user_preset("Lorien Top Panel")
    dock_cfg = user_preset("Lorien Dock")
else:
    top_cfg = colorizer(
        panel_bg=color("#000000", 0.92, source=5, gradient={"orientation": 0, "stops": [
            {"color": "#a8457f", "position": 0}, {"color": "#6d58a0", "position": 0.5}, {"color": "#3a8443", "position": 1}]}),
        island_bg=color("#161616", 0.92), radius=7)
    dock_cfg = colorizer(panel_bg=color("#141414", 0.82), island_bg=color("#262626", 0.9), radius=10, panel_radius=14)

# Desktop tiles run in two tall, narrow columns along the left and right screen edges, leaving
# the middle of the wallpaper free, and cover at most 20 % of the screen area
# (2 x 272 x 560 = 14.7 %). Each column is 2 x 4 cells of R_W x R_H, centred vertically in the
# desktop area between the top panel and the dock (AREA_H; containment coordinates start below
# the top panel). Plasma's own weather widget is at least 416 px wide, so org.lorien.weather
# replaces it; a full calendar would need 416 x 288, so it sits in one cell as a date icon.
# Plasma snaps desktop widgets' position and size to a 16 px grid in both directions, so every
# size, gap and offset here is a multiple of 16; otherwise tiles grow or shift and collide.
def screen_size():
    """Logical size of the primary screen: LORIEN_SCREEN=WxH, else kscreen-doctor, else 1920x1080."""
    if os.environ.get("LORIEN_SCREEN"):
        return tuple(int(v) for v in os.environ["LORIEN_SCREEN"].lower().split("x"))
    try:
        outputs = json.loads(subprocess.run(["kscreen-doctor", "-j"], capture_output=True, text=True,
                                            timeout=10).stdout)["outputs"]
        out = min((o for o in outputs if o.get("enabled")), key=lambda o: o.get("priority", 99))
        mode = next(m for m in out["modes"] if m["id"] == out["currentModeId"])
        scale = out.get("scale", 1) or 1
        w, h = mode["size"]["width"], mode["size"]["height"]
        if out.get("rotation") in (2, 8):
            w, h = h, w
        return round(w / scale), round(h / scale)
    except (OSError, ValueError, KeyError, StopIteration, subprocess.SubprocessError):
        return 1920, 1080


# the desktop area is the screen minus the top bar (36 px) and the dock (52 px), on the 16 px grid
SCREEN_W, SCREEN_H = screen_size()
SCREEN_W = SCREEN_W // 16 * 16
AREA_H = (SCREEN_H - 88) // 16 * 16
MARGIN, GAP = 32, 16
R_W, R_H, ROWS = 128, 128, 4
COL_W = 2 * R_W + GAP
COL_H = ROWS * R_H + (ROWS - 1) * GAP
Y0 = (AREA_H - COL_H) // 2 // 16 * 16
COL_X = {"left": MARGIN, "right": SCREEN_W - MARGIN - COL_W}


def cell(side, col, row, cols=1, rows=1):
    """x, y, w, h of a cell in the left or right column, optionally spanning several cells."""
    return [COL_X[side] + col * (R_W + GAP), Y0 + row * (R_H + GAP),
            cols * R_W + (cols - 1) * GAP, rows * R_H + (rows - 1) * GAP]


def have_app(launcher):
    """Whether a dock launcher's .desktop file exists, so a friend's dock has no dead icons."""
    if launcher.startswith("file://"):
        return os.path.exists(launcher[len("file://"):])
    name = launcher.split(":", 1)[1]
    dirs = [os.path.expanduser("~/.local/share")] + \
        os.environ.get("XDG_DATA_DIRS", "/usr/local/share:/usr/share").split(":") + \
        [os.path.expanduser("~/.local/share/flatpak/exports/share"), "/var/lib/flatpak/exports/share"]
    return any(os.path.exists(os.path.join(d, "applications", name)) for d in dirs)


HAS_BATTERY = bool(glob.glob("/sys/class/power_supply/BAT*"))


def network_iface():
    """The Wi-Fi card, else the first wired one, for org.lorien.network."""
    wifi = sorted(os.path.basename(os.path.dirname(p)) for p in glob.glob("/sys/class/net/*/wireless"))
    wired = sorted(n for n in os.listdir("/sys/class/net")
                   if n != "lo" and os.path.exists(f"/sys/class/net/{n}/device"))
    return (wifi or wired or ["wlan0"])[0]

# BBC Weather station for org.lorien.weather; install.sh writes it from the city the user gives
try:
    WEATHER_STATION = open(os.path.expanduser("~/.config/lorien-rice/weather-station")).read().strip()
except OSError:
    WEATHER_STATION = ""

# the menu button: the distro logo in white, like the Apple menu (apply-kde.sh makes it; Plasma's icon otherwise)
LOGO = os.path.join(HERE, "menu-logo.png")
MENU_BUTTON = {"useCustomButtonImage": True, "customButtonImage": LOGO, "showRecentApps": False,
               "showRecentDocs": False} if os.path.exists(LOGO) else {"icon": "start-here-kde-symbolic"}

layout = {
    "top": [
        # left, as on a Mac: the system menu behind the distro logo, then the active app's menus
        ["org.kde.plasma.kicker", {"General": MENU_BUTTON}],
        ["org.kde.plasma.appmenu", {}],
        ["org.kde.plasma.panelspacer", {}],
        # the island (org.lorien.island, after Isle for GNOME) in the middle; it hangs from the
        # screen edge when opened, and Panel Colorizer leaves it without a background of its own
        ["org.lorien.island", {}],
        ["org.kde.plasma.panelspacer", {}],
        ["luisbocanegra.audio.visualizer", {"General": {
            "visualizerStyle": 0, "barCount": 32, "barWidth": 3, "barGap": 2, "roundedBars": True,
            "length": 170, "noiseReduction": 77, "hideToolTip": True,
            "barColors": json.dumps({"enabled": True, "sourceType": 1, "systemColor": "highlightColor", "systemColorSet": "View"})}}],
        ["org.lorien.cpu", {}],
        ["org.lorien.cpu", {"General": {"sensorId": "memory/physical/usedPercent", "icon": "\U000f035b", "title": "RAM", "decimals": 0}}],
        ["org.lorien.cpu", {"General": {"sensorId": "network/all/download", "icon": "\U000f01da", "title": "Download", "unit": "formatted"}}],
        ["org.lorien.cpu", {"General": {"sensorId": "network/all/upload", "icon": "\U000f0552", "title": "Upload", "unit": "formatted"}}],
    ] + ([
        ["org.lorien.cpu", {"General": {"sensorId": "power/0001/chargePercentage", "icon": "\U000f0079", "title": "Battery", "decimals": 0}}],
    ] if HAS_BATTERY else []) + [
        ["org.dhruv8sh.kara", {"general": {"spacing": 4, "type": 0}}],
        ["org.kde.plasma.systemtray", {"General": {"iconSpacing": 1}}],
        ["org.kde.plasma.digitalclock", {"Appearance": {
            "showDate": False, "showSeconds": 0, "use24hFormat": 2,
            "autoFontAndSize": False, "fontFamily": "JetBrainsMono Nerd Font", "fontWeight": 700, "fontSize": 11}}],
        ["org.kde.plasma.lock_logout", {"General": {
            "show_lockScreen": True, "show_requestReboot": True, "show_requestShutDown": True,
            "show_requestLogoutScreen": False, "show_switchUser": False}}],
        ["luisbocanegra.panel.colorizer", {"General": dict(hideWidget=True, **top_cfg)}],
    ],
    "dock": [
        ["plasmusic-toolbar", {"General": {
            "albumCoverRadius": 6, "albumPosition": 2, "fallbackToIconWhenArtNotAvailable": True,
            "panelControlsSizeRatio": 0.9, "panelIconSizeRatio": 1, "titlePosition": 2, "useAlbumCoverAsPanelIcon": True}}],
        ["org.linexin.launcher", {}],
        ["org.kde.plasma.icontasks", {"General": {"launchers": ",".join(l for l in [
            "applications:systemsettings.desktop",
            "applications:org.kde.dolphin.desktop",
            "applications:firefox.desktop",
            "applications:org.kde.konsole.desktop",
            "applications:com.microsoft.VSCode.desktop",
            "applications:dev.vencord.Vesktop.desktop",
            "applications:tidal-hifi.desktop",
            "file:///var/lib/flatpak/exports/share/applications/com.rustdesk.RustDesk.desktop"] if have_app(l)),
            "showOnlyCurrentActivity": False, "showOnlyCurrentDesktop": False, "iconSpacing": 1}}],
        ["luisbocanegra.panel.colorizer", {"General": dict(hideWidget=True, **dock_cfg)}],
    ],
    # desktop widgets that were replaced or dropped; removed when the desktop is rebuilt
    "retired": ["org.kde.plasma.systemmonitor", "org.kde.plasma.konsoleprofiles", "org.kde.plasma.mediaframe",
                "org.kde.plasma.weather",
                "org.lorien.clocktile", "org.kde.plasma.calendar"],
    # x, y, w, h in px (grid constants above)
    "desktop": [
        # left column: weather and time, then music and the fun bits. The org.lorien.* tiles share
        # one minimal layout: a small caption on top, one big value at the bottom with a thin bar
        # or a bare line; details live in the tooltip.
        ["org.lorien.weather", cell("left", 0, 0, cols=2),
         {"General": {"station": WEATHER_STATION}} if WEATHER_STATION else {}],
        # the binary clock sizes its LEDs by height and needs ~205 px of width at this height
        ["org.kde.plasma.binaryclock", cell("left", 0, 1, cols=2), {"General": {
            "showSeconds": True, "showOffLeds": True,
            "useCustomColorForActive": True, "customColorForActive": "181,137,214",
            "useCustomColorForInactive": True, "customColorForInactive": "36,36,36"}}],
        ["org.lorien.nowplaying", cell("left", 0, 2, cols=2), {}],
        ["org.lorien.pokemon", cell("left", 0, 3), {}],
        ["org.lorien.terminals", cell("left", 1, 3), {}],

        # right column: system state, then the note
        ["org.lorien.system", cell("right", 0, 0), {}],
        ["org.lorien.network", cell("right", 1, 0), {"General": {"iface": network_iface()}}],
        ["org.lorien.battery", cell("right", 0, 1), {}],
        ["org.lorien.disks", cell("right", 1, 1), {}],
        ["org.lorien.updates", cell("right", 0, 2, cols=2), {}],
        ["org.kde.plasma.notes", cell("right", 0, 3, cols=2), {"General": {
            "color": "translucent-light", "noteId": "lorien-notes", "fontSize": 9}}],
    ],
}

# The Panel Colorizer presets are big (about 60 KiB each as JSON), and qdbus6 takes a script of at
# most 128 KiB, so the panels are created without them and colorizer-*.js configure each one.
colorizer_cfg = {}
for where in ("top", "dock"):
    for it in layout[where]:
        if it[0] == "luisbocanegra.panel.colorizer":
            colorizer_cfg[where], it[1] = it[1], {"General": {"hideWidget": True}}

js = """
var L = %s;

function configure(w, groups) {
    for (var g in groups) {
        w.currentConfigGroup = g.split("/");
        for (var k in groups[g]) w.writeConfig(k, groups[g][k]);
    }
    w.reloadConfig();
}

var old = panels();
for (var i = 0; i < old.length; i++) old[i].remove();

var top = new Panel("org.kde.panel");
top.location = "top";
top.height = 36;
top.floating = false;
top.hiding = "none";
L.top.forEach(function (it) { configure(top.addWidget(it[0]), it[1]); });

var dock = new Panel("org.kde.panel");
dock.location = "bottom";
dock.height = 52;
dock.floating = true;
dock.lengthMode = "fit";
dock.alignment = "center";
dock.hiding = "none";
L.dock.forEach(function (it) { configure(dock.addWidget(it[0]), it[1]); });

var desk = desktopForScreen(0);
var ours = L.desktop.map(function (it) { return it[0]; }).concat(L.retired);
desk.widgets().forEach(function (w) { if (ours.indexOf(w.type) >= 0) w.remove(); });
L.desktop.forEach(function (it) {
    var r = it[1];
    configure(desk.addWidget(it[0], r[0], r[1], r[2], r[3]), it[2]);
});
print("top widgets: " + top.widgetIds.length + ", dock widgets: " + dock.widgetIds.length + ", desktop widgets: " + desk.widgetIds.length);
""" % json.dumps(layout)

open(os.path.join(HERE, "layout.js"), "w").write(js)
for where, cfg in colorizer_cfg.items():
    location = {"top": "top", "dock": "bottom"}[where]
    open(os.path.join(HERE, f"colorizer-{where}.js"), "w").write("""
var cfg = %s;
panels().forEach(function (p) {
    if (p.location !== "%s") return;
    // no colorizer background behind the island: it draws its own black shape
    // Super+I opens the island's assistant, as in Isle
    p.widgets("org.lorien.island").forEach(function (w) { w.globalShortcut = "Meta+I"; });
    var skip = p.widgets("org.lorien.island").map(function (w) {
        return {id: w.id, name: "org.lorien.island", blacklisted: true};
    });
    p.widgets("luisbocanegra.panel.colorizer").forEach(function (w) {
        w.currentConfigGroup = ["General"];
        for (var k in cfg.General) w.writeConfig(k, cfg.General[k]);
        w.writeConfig("blacklistedWidgets", JSON.stringify({widgets: skip}));
        w.reloadConfig();
    });
});
""" % (json.dumps(cfg), location))
print("wrote", os.path.join(HERE, "layout.js"), len(js), "bytes")

# Desktop tiles only, leaving the panels alone. Plasma ignores the addWidget geometry for the
# folder containment, so apply-desktop.sh writes desktop-geometry.json into appletsrc afterwards.
# Only the desktop part of L goes in: the panel presets would push the script past the
# 128 KiB limit for a single command-line argument to qdbus6.
desktop_js = "\nvar L = %s;\n" % json.dumps({"desktop": layout["desktop"], "retired": layout["retired"]}) \
    + js[js.index("function configure"):js.index("var old = panels();")] \
    + js[js.index("var desk = desktopForScreen(0);"):] \
    .replace('print("top widgets: " + top.widgetIds.length + ", dock widgets: " + dock.widgetIds.length + ", ', 'print("')
open(os.path.join(HERE, "desktop.js"), "w").write(desktop_js)
json.dump({it[0]: it[1] for it in layout["desktop"]}, open(os.path.join(HERE, "desktop-geometry.json"), "w"), indent=1)
print("wrote desktop.js and desktop-geometry.json")
