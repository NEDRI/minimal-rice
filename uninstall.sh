#!/usr/bin/env bash
# Restores the settings from before ./install.sh from a ~/lorien-backup-<date> copy (the newest by
# default) and removes the Lorien files. Packages stay installed.
#   ./uninstall.sh [~/lorien-backup-20261030-1800]
set -euo pipefail
BACKUP="${1:-$(ls -d "$HOME"/lorien-backup-* 2>/dev/null | sort | tail -1)}"
[[ -d "$BACKUP" ]] || { echo "No ~/lorien-backup-* copy found." >&2; exit 1; }
echo "Restoring from: $BACKUP"
read -rp "Continue? [Y/n] " a; [[ -z "$a" || "$a" =~ ^[Yy] ]] || exit 0

L="$HOME/.local/share"
rm -rf "$L/lorien-rice" "$L"/plasma/plasmoids/org.lorien.* "$L/plasma/desktoptheme/lorien" \
       "$L/gnome-shell/extensions/lorien-bar@lorien-rice" "$HOME/.config/lorien-rice" \
       "$HOME/.config/systemd/user/isled.service.d" \
       "$HOME/.config/autostart/lorien-accent.desktop" "$HOME/.config/autostart/waywallen.desktop" \
       "$HOME/.config/environment.d/20-lorien-decorations.conf" \
       "$HOME/.local/bin/updateall" "$HOME/.local/bin/ramka" "$HOME/.local/bin/rmaka"
rm -f "$L"/konsole/{Update,btop,Cava,Lorien}.profile "$L/konsole/Lorien.colorscheme" \
      "$HOME"/.cache/lorien-accent-*

# plasmashell saves its layout when it exits, so stop it while restoring
plasma=false
systemctl --user is-active -q plasma-plasmashell.service 2>/dev/null && plasma=true
$plasma && systemctl --user stop plasma-plasmashell.service
# files that existed before the install come back from the copy
(cd "$BACKUP" && find . -type f ! -name dconf.ini ! -name components) | while read -r rel; do
    mkdir -p "$HOME/$(dirname "$rel")"
    cp -a "$BACKUP/$rel" "$HOME/$rel"
done
$plasma && systemctl --user start plasma-plasmashell.service
if [[ -f "$BACKUP/dconf.ini" ]] && command -v dconf >/dev/null; then
    dconf reset -f /org/gnome/shell/extensions/
    dconf load / < "$BACKUP/dconf.ini"
fi
echo "Restored. Log out and log back in. The window borders (KDE Rounded Corners) and packages stay;"
echo "remove them by hand, e.g.: sudo pacman -Rns qadwaitadecorations-qt6 waywallen-bin"
