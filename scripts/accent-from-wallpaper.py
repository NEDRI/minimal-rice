#!/usr/bin/env python3
"""Pick an accent colour from the current wallpaper and apply it everywhere.

The wallpaper is Waywallen's (Wallpaper Engine) when it runs, otherwise the desktop's own image.

  accent-from-wallpaper.py            apply once for the wallpaper shown now
  accent-from-wallpaper.py --watch    keep running and re-apply whenever the wallpaper changes
  accent-from-wallpaper.py IMAGE      apply the accent of an image file (for testing)

The colour goes to the KDE colour scheme (Plasma, panel pills, desktop tiles and their borders
follow its highlight colour), the window border effect, the binary clock widget and the rofi launcher. In GNOME it
sets the nearest of GNOME's accent colours and the exact colour on the dock's running-app dots.
"""
import colorsys, configparser, math, os, sqlite3, subprocess, sys
from urllib.parse import unquote, urlparse
from gi.repository import Gio, GLib
from PIL import Image

BUS_NAME = "org.waywallen.waywallen.Daemon"
OBJ = "/org/waywallen/waywallen/Daemon"
IFACE = "org.waywallen.waywallen.Daemon1"
DB = os.path.expanduser("~/.local/share/waywallen/waywallen-v2.db")
# KDE and GNOME keep their own settings, so each session remembers what it last applied
DESKTOP = "GNOME" if "GNOME" in os.environ.get("XDG_CURRENT_DESKTOP", "") else "KDE"
STATE = os.path.expanduser(f"~/.cache/lorien-accent-{DESKTOP}")
# GNOME only offers these accent colours (hue in degrees), so it gets the nearest one
GNOME_ACCENTS = {"red": 355, "orange": 25, "yellow": 45, "green": 140, "teal": 175,
                 "blue": 215, "purple": 275, "pink": 325}
FALLBACK = (181, 137, 214)  # system24 purple, for grey wallpapers


def current_preview(bus):
    """Path of the preview image of the wallpaper Waywallen shows now, or None."""
    try:
        res = bus.call_sync(BUS_NAME, OBJ, "org.freedesktop.DBus.Properties", "Get",
                            GLib.Variant("(ss)", (IFACE, "CurrentWallpaperId")), None, 0, 3000, None)
        item_id = res.unpack()[0]
    except GLib.Error:
        return None
    db = sqlite3.connect(f"file:{DB}?mode=ro", uri=True)
    row = db.execute("select l.path, i.preview_path, i.path from item i join library l on l.id = i.library_id "
                     "where i.id = ?", (item_id,)).fetchone()
    if not row:
        return None
    root, preview, path = row
    for rel in (preview, path):
        if rel:
            full = rel if os.path.isabs(rel) else os.path.join(root, rel)
            if os.path.isfile(full) and full.lower().endswith((".jpg", ".jpeg", ".png", ".gif", ".webp", ".bmp")):
                return full
    return None


def uri_path(uri):
    return unquote(urlparse(uri).path) if uri.startswith("file:") else uri


def static_wallpaper():
    """Path of the desktop's own wallpaper image (no Waywallen), or None."""
    if DESKTOP == "GNOME":
        key = "picture-uri-dark" if "dark" in subprocess.run(
            ["gsettings", "get", "org.gnome.desktop.interface", "color-scheme"],
            capture_output=True, text=True).stdout else "picture-uri"
        uri = subprocess.run(["gsettings", "get", "org.gnome.desktop.background", key],
                             capture_output=True, text=True).stdout.strip().strip("'")
        path = uri_path(uri)
    else:
        rc = configparser.ConfigParser(interpolation=None, strict=False)
        try:
            rc.read(os.path.expanduser("~/.config/plasma-org.kde.plasma.desktop-appletsrc"))
        except configparser.Error:
            return None
        path = None
        for sec in rc.sections():
            if sec.endswith("][Wallpaper][org.kde.image][General]") and rc[sec].get("Image"):
                path = uri_path(rc[sec]["Image"])
                break
    if path and os.path.isdir(path):  # a wallpaper package: take its largest image
        imgs = [os.path.join(d, f) for d, _, fs in os.walk(path) for f in fs
                if f.lower().endswith((".jpg", ".jpeg", ".png", ".webp"))]
        path = max(imgs, key=os.path.getsize) if imgs else None
    return path if path and os.path.isfile(path) else None


def accent_of(image_path):
    """A soft accent in the image's most prominent vivid hue, as an (r, g, b) tuple."""
    img = Image.open(image_path)
    img.seek(0)
    img = img.convert("RGB")
    img.thumbnail((96, 96))
    bins = [0.0] * 36
    vec = [[0.0, 0.0] for _ in range(36)]
    sats = [[] for _ in range(36)]
    for r, g, b in (img.get_flattened_data() if hasattr(img, "get_flattened_data") else img.getdata()):
        h, s, v = colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)
        if s < 0.2 or v < 0.2:
            continue
        w = s * v
        k = int(h * 36) % 36
        bins[k] += w
        vec[k][0] += w * math.cos(h * 2 * math.pi)
        vec[k][1] += w * math.sin(h * 2 * math.pi)
        sats[k].append(s)
    total = sum(bins)
    if total < 0.5:
        return FALLBACK
    k = max(range(36), key=lambda i: bins[i] + 0.5 * (bins[i - 1] + bins[(i + 1) % 36]))
    hue = (math.atan2(vec[k][1], vec[k][0]) / (2 * math.pi)) % 1.0
    sat = min(0.55, max(0.32, sorted(sats[k])[len(sats[k]) // 2] * 0.6))
    r, g, b = colorsys.hsv_to_rgb(hue, sat, 0.86)
    return round(r * 255), round(g * 255), round(b * 255)


def apply(rgb):
    hexc = "#%02x%02x%02x" % rgb
    try:
        if open(STATE).read().strip() == hexc:
            return
    except OSError:
        pass
    (apply_gnome if DESKTOP == "GNOME" else apply_kde)(rgb, hexc)
    # the rofi launcher (Super+B) reads the accent from here each time it opens
    rofi = os.path.expanduser("~/.config/rofi/lorien-accent.rasi")
    os.makedirs(os.path.dirname(rofi), exist_ok=True)
    open(rofi, "w").write("* { accent: %s; }\n" % hexc)
    os.makedirs(os.path.dirname(STATE), exist_ok=True)
    open(STATE, "w").write(hexc + "\n")
    print("accent", hexc)


def apply_gnome(rgb, hexc):
    h, s, _ = colorsys.rgb_to_hsv(*(c / 255 for c in rgb))
    hue = h * 360
    name = "slate" if s < 0.15 else min(GNOME_ACCENTS, key=lambda k: min(abs(GNOME_ACCENTS[k] - hue),
                                                                           360 - abs(GNOME_ACCENTS[k] - hue)))
    subprocess.run(["gsettings", "set", "org.gnome.desktop.interface", "accent-color", name])
    # the dock's running-app dots take the exact colour
    subprocess.run(["dconf", "write", "/org/gnome/shell/extensions/dash-to-dock/custom-theme-running-dots-color",
                    "'%s'" % hexc])


def apply_kde(rgb, hexc):
    csv = "%d,%d,%d" % rgb
    subprocess.run(["plasma-apply-colorscheme", "--accent-color", hexc], stdout=subprocess.DEVNULL)
    # plasmashell doesn't always repaint after that; a "palette changed" broadcast makes it
    subprocess.run(["dbus-send", "--session", "--type=signal", "/KGlobalSettings",
                    "org.kde.KGlobalSettings.notifyChange", "int32:0", "int32:0"])
    for key in ("OutlineColor", "InactiveOutlineColor"):
        subprocess.run(["kwriteconfig6", "--file", "kwinrc", "--group", "Round-Corners", "--key", key, csv])
    subprocess.run(["qdbus6", "org.kde.KWin", "/Effects", "org.kde.kwin.Effects.reconfigureEffect",
                    "kwin4_effect_shapecorners"], stdout=subprocess.DEVNULL)
    script = ('desktops().forEach(function (d) { d.widgets("org.kde.plasma.binaryclock").forEach(function (w) {'
              ' w.currentConfigGroup = ["General"]; w.writeConfig("customColorForActive", "%s"); w.reloadConfig(); }); });' % hexc)
    subprocess.run(["qdbus6", "org.kde.plasmashell", "/PlasmaShell", "org.kde.PlasmaShell.evaluateScript", script],
                   stdout=subprocess.DEVNULL)
    # the panel's audio visualizer doesn't repaint when the system colours change, so give it the
    # accent as a custom colour (sourceType 0)
    script = ('panels().forEach(function (p) { p.widgets("luisbocanegra.audio.visualizer").forEach(function (w) {'
              ' w.currentConfigGroup = ["General"]; var c = JSON.parse(w.readConfig("barColors") || "{}");'
              ' c.enabled = true; c.sourceType = 0; c.custom = "%s";'
              ' w.writeConfig("barColors", JSON.stringify(c)); w.reloadConfig(); }); });' % hexc)
    subprocess.run(["qdbus6", "org.kde.plasmashell", "/PlasmaShell", "org.kde.PlasmaShell.evaluateScript", script],
                   stdout=subprocess.DEVNULL)


_last_image = None


def apply_current(bus):
    global _last_image
    image = current_preview(bus) or static_wallpaper()
    # this also runs every half minute: only read the image again when it changed
    key = image and (image, os.path.getmtime(image))
    if image and key != _last_image:
        _last_image = key
        apply(accent_of(image))
    return False  # also used as a one-shot GLib timeout


def main():
    args = sys.argv[1:]
    if args and args[0] != "--watch":
        apply(accent_of(args[0]))
        return
    bus = Gio.bus_get_sync(Gio.BusType.SESSION)
    apply_current(bus)
    if args != ["--watch"]:
        return
    # the wallpaper changed, or Waywallen (re)started and picked one
    bus.signal_subscribe(BUS_NAME, "org.freedesktop.DBus.Properties", "PropertiesChanged", OBJ, None,
                         Gio.DBusSignalFlags.NONE,
                         lambda *a: "CurrentWallpaperId" in a[5].unpack()[1] and apply_current(bus))
    bus.signal_subscribe("org.freedesktop.DBus", "org.freedesktop.DBus", "NameOwnerChanged", "/org/freedesktop/DBus",
                         BUS_NAME, Gio.DBusSignalFlags.NONE,
                         lambda *a: a[5].unpack()[2] and GLib.timeout_add_seconds(5, apply_current, bus))
    # without Waywallen nothing signals a wallpaper change, so look at the desktop's image now and then
    GLib.timeout_add_seconds(30, lambda: apply_current(bus) or True)
    GLib.MainLoop().run()


main()
