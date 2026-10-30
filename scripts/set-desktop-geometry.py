#!/usr/bin/env python3
"""Write desktop-geometry.json into the ItemGeometries keys of the primary desktop containment.

Run only while plasmashell is stopped, otherwise it overwrites appletsrc on exit.
"""
import json, os, re

HERE = os.path.dirname(os.path.abspath(__file__))
RC = os.path.expanduser("~/.config/plasma-org.kde.plasma.desktop-appletsrc")

geometry = json.load(open(os.path.join(HERE, "desktop-geometry.json")))
text = open(RC).read()

# containment id -> its keys, and applet id -> plugin, from the section headers
sections = re.split(r"(?m)^(?=\[)", text)
containments, applets = {}, {}
for sec in sections:
    head = sec.split("\n", 1)[0]
    body = dict(re.findall(r"(?m)^([^=\n]+)=(.*)$", sec))
    if m := re.fullmatch(r"\[Containments\]\[(\d+)\]", head):
        containments[m.group(1)] = body
    elif m := re.fullmatch(r"\[Containments\]\[(\d+)\]\[Applets\]\[(\d+)\]", head):
        applets[m.group(2)] = (m.group(1), body.get("plugin"))

desk = next(cid for cid, b in containments.items()
            if b.get("plugin") == "org.kde.plasma.folder" and b.get("lastScreen") == "0")
items = []
for aid, (cid, plugin) in sorted(applets.items(), key=lambda kv: int(kv[0])):
    if cid == desk and plugin in geometry:
        x, y, w, h = geometry[plugin]
        items.append(f"Applet-{aid}:{x},{y},{w},{h},0;")
value = "".join(items)

out = []
for sec in sections:
    if sec.split("\n", 1)[0] == f"[Containments][{desk}]":
        sec = re.sub(r"(?m)^(ItemGeometries-1920x1080|ItemGeometriesHorizontal)=.*$", lambda m: f"{m.group(1)}={value}", sec)
    out.append(sec)
open(RC, "w").write("".join(out))
print(f"containment {desk}: {len(items)} tiles placed")
