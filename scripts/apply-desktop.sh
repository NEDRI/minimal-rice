#!/bin/sh
# Re-create the desktop tiles from make-layout.py without touching the panels.
set -e
HERE="$(dirname "$(readlink -f "$0")")"
python3 -I "$HERE/make-layout.py"
# removing the notes widget deletes its note, so keep a copy and put it back afterwards
NOTE="$HOME/.local/share/plasma_notes/lorien-notes"
[ -f "$NOTE" ] && cp "$NOTE" "$HERE/.note-backup"
qdbus6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "$(cat "$HERE/desktop.js")"
sleep 3
systemctl --user stop plasma-plasmashell.service
python3 -I "$HERE/set-desktop-geometry.py"
[ -f "$HERE/.note-backup" ] && cp "$HERE/.note-backup" "$NOTE"
# drop cached theme SVGs so a regenerated lorien style is picked up
rm -f "$HOME"/.cache/plasma_theme_lorien*.kcache "$HOME"/.cache/plasma-svgelements*lorien* "$HOME"/.cache/ksvg-elements*
"$HERE/restart-plasma.sh"
# the new binary clock widget starts with the layout's colour: give it the wallpaper accent again
sleep 5
rm -f "$HOME"/.cache/lorien-accent*
python3 -I "$HERE/accent-from-wallpaper.py"
