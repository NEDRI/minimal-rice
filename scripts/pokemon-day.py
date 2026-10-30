#!/usr/bin/env python3
"""Print the Pokémon of the day as JSON pixels for the org.lorien.pokemon desktop tile.

Reads the sprites that pokemon-colorscripts ships (large size: every pixel is two
full blocks "██" coloured with a 24-bit ANSI escape, two spaces are a transparent pixel).
The pick is seeded by today's date, so it stays the same all day; pass "random" for a new one.
"""
import datetime, json, os, random, re, sys

# a local install, or the AUR package pokemon-colorscripts-git
DATA = next((d for d in (os.path.expanduser("~/.local/opt/pokemon-colorscripts"), "/opt/pokemon-colorscripts")
             if os.path.isdir(d)), "/opt/pokemon-colorscripts")
TOKEN = re.compile(r"\x1b\[([0-9;]*)m|(██)|(  )|(▀|▄)")


def sprite(path):
    rows, fg = [], None
    for line in open(path, encoding="utf-8").read().splitlines():
        row = []
        for esc, block, blank, _half in TOKEN.findall(line):
            if esc:
                p = esc.split(";")
                fg = "#%02x%02x%02x" % tuple(map(int, p[2:5])) if p[:2] == ["38", "2"] else None
            elif block:
                row.append(fg or "")
            elif blank:
                row.append("")
        rows.append(row)
    while rows and not any(rows[-1]):
        rows.pop()
    while rows and not any(rows[0]):
        rows.pop(0)
    width = max(len(r) for r in rows)
    rows = [r + [""] * (width - len(r)) for r in rows]
    # trim empty columns on both sides
    used = [x for x in range(width) if any(r[x] for r in rows)]
    lo, hi = used[0], used[-1] + 1
    return [r[lo:hi] for r in rows]


def main():
    names = [p["name"] for p in json.load(open(os.path.join(DATA, "pokemon.json")))]
    seed = None if sys.argv[1:] == ["random"] else datetime.date.today().isoformat()
    rng = random.Random(seed)
    index = rng.randrange(len(names))
    shiny = rng.random() < 1 / 64
    name = names[index]
    path = os.path.join(DATA, "colorscripts", "large", "shiny" if shiny else "regular", name)
    rows = sprite(path)
    print(json.dumps({
        "id": index + 1,
        "name": name.replace("-", " ").title(),
        "shiny": shiny,
        "w": len(rows[0]),
        "h": len(rows),
        "px": [c for r in rows for c in r],
    }, separators=(",", ":")))


main()
