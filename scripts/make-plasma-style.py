#!/usr/bin/env python3
"""Write widgets/background.svg for the "lorien" Plasma style: rounded translucent tiles with an accent border."""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from system24_palette import palette

P = palette()
hexc = lambda k: "#%02x%02x%02x" % P[k]

# Accents are painted with the colour scheme's highlight colour, which KSvg fills in through the
# "current-color-scheme" stylesheet, so they follow the accent colour (set from the wallpaper by
# accent-from-wallpaper.py) without regenerating these files. The colour in STYLE is only a fallback.
HL = 'class="ColorScheme-Highlight" fill="currentColor"'
STYLE = f'<style id="current-color-scheme" type="text/css">.ColorScheme-Highlight {{ color:{hexc("purple-2")}; }}</style>'

R, M = 18, 12                     # corner radius, content margin
FILL = f'fill="{hexc("bg-2")}" fill-opacity="0.62"'
EDGE = f'{HL} fill-opacity="0.45"'   # the border is a filled 1px band, not a stroke
S = 3 * R
a, b, r = R, 2 * R, R - 1
cells = {  # name: (x, y, inner fill, border band)
    "topleft":     (0, 0, f'<path {FILL} d="M1,{R} A{r},{r} 0 0 1 {R},1 V{R} Z"/>',
                    f'<path {EDGE} d="M0,{R} A{R},{R} 0 0 1 {R},0 V1 A{r},{r} 0 0 0 1,{R} Z"/>'),
    "top":         (a, 0, f'<rect {FILL} x="{a}" y="1" width="{R}" height="{R - 1}"/>',
                    f'<rect {EDGE} x="{a}" y="0" width="{R}" height="1"/>'),
    "topright":    (b, 0, f'<path {FILL} d="M{b},1 A{r},{r} 0 0 1 {S - 1},{R} H{b} Z"/>',
                    f'<path {EDGE} d="M{b},0 A{R},{R} 0 0 1 {S},{R} H{S - 1} A{r},{r} 0 0 0 {b},1 Z"/>'),
    "left":        (0, a, f'<rect {FILL} x="1" y="{a}" width="{R - 1}" height="{R}"/>',
                    f'<rect {EDGE} x="0" y="{a}" width="1" height="{R}"/>'),
    "center":      (a, a, f'<rect {FILL} x="{a}" y="{a}" width="{R}" height="{R}"/>', ""),
    "right":       (b, a, f'<rect {FILL} x="{b}" y="{a}" width="{R - 1}" height="{R}"/>',
                    f'<rect {EDGE} x="{S - 1}" y="{a}" width="1" height="{R}"/>'),
    "bottomleft":  (0, b, f'<path {FILL} d="M1,{b} H{R} V{S - 1} A{r},{r} 0 0 1 1,{b} Z"/>',
                    f'<path {EDGE} d="M0,{b} H1 A{r},{r} 0 0 0 {R},{S - 1} V{S} A{R},{R} 0 0 1 0,{b} Z"/>'),
    "bottom":      (a, b, f'<rect {FILL} x="{a}" y="{b}" width="{R}" height="{R - 1}"/>',
                    f'<rect {EDGE} x="{a}" y="{S - 1}" width="{R}" height="1"/>'),
    "bottomright": (b, b, f'<path {FILL} d="M{b},{b} H{S - 1} A{r},{r} 0 0 1 {b},{S - 1} Z"/>',
                    f'<path {EDGE} d="M{S - 1},{b} H{S} A{R},{R} 0 0 1 {b},{S} V{S - 1} A{r},{r} 0 0 0 {S - 1},{b} Z"/>'),
}
out = [f'<svg xmlns="http://www.w3.org/2000/svg" width="{S + 40}" height="{S}" viewBox="0 0 {S + 40} {S}">', "  " + STYLE]
for name, (x, y, body, edge) in cells.items():
    # an invisible full-cell rect pins every element's bounds to exactly R x R
    frame = f'<rect x="{x}" y="{y}" width="{R}" height="{R}" fill="#000000" fill-opacity="0"/>'
    out.append(f'  <g id="{name}">{frame}{body}{edge}</g>')
x = S + 8
out += [
    f'  <rect id="hint-top-margin" x="{x}" y="0" width="1" height="{M}" fill="none"/>',
    f'  <rect id="hint-bottom-margin" x="{x + 4}" y="0" width="1" height="{M}" fill="none"/>',
    f'  <rect id="hint-left-margin" x="{x + 8}" y="0" width="{M}" height="1" fill="none"/>',
    f'  <rect id="hint-right-margin" x="{x + 8}" y="4" width="{M}" height="1" fill="none"/>',
    f'  <rect id="hint-stretch-borders" x="{x}" y="{S - 2}" width="1" height="1" fill="none"/>',
    '</svg>',
]
dst = os.path.expanduser("~/.local/share/plasma/desktoptheme/lorien/widgets/background.svg")
open(dst, "w").write("\n".join(out) + "\n")
print("wrote", dst)


# ---- widgets/tasks.svg: task manager states (no grey squares, a purple pill under running apps) ----

def paint(color, opacity):
    """Fill attributes; ACC means the colour scheme's highlight (accent) colour."""
    fill = HL if color == ACC else f'fill="{color}"'
    return f'{fill} fill-opacity="{opacity}"'


def task_frame(prefix, ox, C, fill, pill, out):
    """One 9-slice frame for a task state, drawn at horizontal offset ox. C = corner size;
    the pill sits in the bottom border only, so its length is the task width minus both corners."""
    S = 3 * C
    xa, xb, xe = ox + C, ox + 2 * C, ox + S   # column edges
    ya, yb = C, 2 * C                          # row edges
    F = paint(*fill) if fill else None
    shapes = dict.fromkeys(["topleft", "top", "topright", "left", "center", "right",
                            "bottomleft", "bottom", "bottomright"], "")
    if F:
        shapes.update({
            "topleft":     f'<path {F} d="M{ox},{ya} A{C},{C} 0 0 1 {xa},0 V{ya} Z"/>',
            "top":         f'<rect {F} x="{xa}" y="0" width="{C}" height="{C}"/>',
            "topright":    f'<path {F} d="M{xb},0 A{C},{C} 0 0 1 {xe},{ya} H{xb} Z"/>',
            "left":        f'<rect {F} x="{ox}" y="{ya}" width="{C}" height="{C}"/>',
            "center":      f'<rect {F} x="{xa}" y="{ya}" width="{C}" height="{C}"/>',
            "right":       f'<rect {F} x="{xb}" y="{ya}" width="{C}" height="{C}"/>',
            "bottomleft":  f'<path {F} d="M{ox},{yb} H{xa} V{S} A{C},{C} 0 0 1 {ox},{yb} Z"/>',
            "bottom":      f'<rect {F} x="{xa}" y="{yb}" width="{C}" height="{C}"/>',
            "bottomright": f'<path {F} d="M{xb},{yb} H{xe} A{C},{C} 0 0 1 {xb},{S} Z"/>',
        })
    if pill:
        shapes["bottom"] += f'<rect {paint(*pill)} x="{xa}" y="{S - 4}" width="{C}" height="3"/>'
    cells = {"topleft": (ox, 0), "top": (xa, 0), "topright": (xb, 0), "left": (ox, ya), "center": (xa, ya),
             "right": (xb, ya), "bottomleft": (ox, yb), "bottom": (xa, yb), "bottomright": (xb, yb)}
    for name, (x, y) in cells.items():
        frame = f'<rect x="{x}" y="{y}" width="{C}" height="{C}" fill="#000000" fill-opacity="0"/>'
        out.append(f'  <g id="{prefix}-{name}">{frame}{shapes[name]}</g>')
    return xe + 10


ACC, WHITE = "accent", "#ffffff"
states = [  # prefix, corner, background fill, indicator pill
    ("normal",    14, None,               (ACC, 0.75)),
    ("minimized", 14, None,               (hexc("text-4"), 0.7)),
    ("hover",     14, (WHITE, 0.07),      (ACC, 0.75)),
    ("focus",      8, (WHITE, 0.10),      (ACC, 1.0)),
    ("attention",  8, (hexc("red-2"), 0.18), (hexc("red-2"), 1.0)),
    ("progress",   8, (ACC, 0.22),        None),
]
out, ox = [], 0
for prefix, C, fill, pill in states:
    ox = task_frame(prefix, ox, C, fill, pill, out)
hint = 3  # padding between the task frame and its icon
out += [f'  <rect id="normal-hint-{side}-margin" x="{ox + i * 4}" y="0" width="{hint}" height="{hint}" fill="none"/>'
        for i, side in enumerate(("top", "bottom", "left", "right"))]
out.append(f'  <rect id="hint-stretch-borders" x="{ox + 20}" y="0" width="1" height="1" fill="none"/>')
out = [f'<svg xmlns="http://www.w3.org/2000/svg" width="{ox + 30}" height="42" viewBox="0 0 {ox + 30} 42">', "  " + STYLE] + out + ["</svg>"]
dst = os.path.expanduser("~/.local/share/plasma/desktoptheme/lorien/widgets/tasks.svg")
open(dst, "w").write("\n".join(out) + "\n")
print("wrote", dst)


# ---- widgets/notes.svg: Breeze's sticky notes plus "translucent" ones drawn as a desktop tile ----
# The notes widget has no background of its own and stretches one whole element ("<color>-notes")
# over itself, so the tile is drawn at the size the note sits at on the desktop: taken from
# desktop-geometry.json, which make-layout.py writes (run that one first).
import gzip, json, re
_geo = os.path.join(os.path.dirname(os.path.abspath(__file__)), "desktop-geometry.json")
NW, NH = json.load(open(_geo))["org.kde.plasma.notes"][2:] if os.path.exists(_geo) else (384, 400)
ring = (f'M{R},0 H{NW - R} A{R},{R} 0 0 1 {NW},{R} V{NH - R} A{R},{R} 0 0 1 {NW - R},{NH} H{R} A{R},{R} 0 0 1 0,{NH - R} V{R} A{R},{R} 0 0 1 {R},0 Z '
        f'M{R},1 A{r},{r} 0 0 0 1,{R} V{NH - R} A{r},{r} 0 0 0 {R},{NH - 1} H{NW - R} A{r},{r} 0 0 0 {NW - 1},{NH - R} V{R} A{r},{r} 0 0 0 {NW - R},1 Z')
inner = f'<rect {FILL} x="1" y="1" width="{NW - 2}" height="{NH - 2}" rx="{r}"/>'
tile = f'<rect x="0" y="0" width="{NW}" height="{NH}" fill="#000000" fill-opacity="0"/>{inner}<path {EDGE} fill-rule="evenodd" d="{ring}"/>'
breeze = gzip.open("/usr/share/plasma/desktoptheme/default/widgets/notes.svgz").read().decode()
extra = "".join(f'\n  <g id="{name}">{tile}</g>' for name in ("translucent-notes", "translucent-light-notes"))
if "current-color-scheme" not in breeze:
    extra = "\n  " + STYLE + extra
breeze = re.sub(r"</svg>\s*$", extra + "\n</svg>\n", breeze)
dst = os.path.expanduser("~/.local/share/plasma/desktoptheme/lorien/widgets/notes.svg")
open(dst, "w").write(breeze)
print("wrote", dst)
