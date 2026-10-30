#!/usr/bin/env bash
# Przywraca ustawienia sprzed ./install.sh z kopii ~/lorien-backup-<data> (domyślnie najnowszej)
# i usuwa pliki Lorien. Pakietów nie odinstalowuje.
#   ./uninstall.sh [~/lorien-backup-20261030-1800]
set -euo pipefail
BACKUP="${1:-$(ls -d "$HOME"/lorien-backup-* 2>/dev/null | sort | tail -1)}"
[[ -d "$BACKUP" ]] || { echo "Nie znalazłem kopii ~/lorien-backup-*." >&2; exit 1; }
echo "Przywracam z: $BACKUP"
read -rp "Kontynuować? [T/n] " a; [[ -z "$a" || "$a" =~ ^[TtYy] ]] || exit 0

L="$HOME/.local/share"
rm -rf "$L/lorien-rice" "$L"/plasma/plasmoids/org.lorien.* "$L/plasma/desktoptheme/lorien" \
       "$L/gnome-shell/extensions/lorien-bar@lorien-rice" "$HOME/.config/lorien-rice" \
       "$HOME/.config/systemd/user/isled.service.d" \
       "$HOME/.config/autostart/lorien-accent.desktop" "$HOME/.config/autostart/waywallen.desktop" \
       "$HOME/.config/environment.d/20-lorien-decorations.conf" \
       "$HOME/.local/bin/updateall" "$HOME/.local/bin/ramka" "$HOME/.local/bin/rmaka"
rm -f "$L"/konsole/{Aktualizacja,btop,Cava,Lorien}.profile "$L/konsole/Lorien.colorscheme" \
      "$HOME"/.cache/lorien-accent-*

# plasmashell zapisuje swój układ przy wyjściu, więc na czas przywracania go zatrzymaj
plasma=false
systemctl --user is-active -q plasma-plasmashell.service 2>/dev/null && plasma=true
$plasma && systemctl --user stop plasma-plasmashell.service
# pliki, które istniały przed instalacją, wracają z kopii
(cd "$BACKUP" && find . -type f ! -name dconf.ini ! -name components) | while read -r rel; do
    mkdir -p "$HOME/$(dirname "$rel")"
    cp -a "$BACKUP/$rel" "$HOME/$rel"
done
$plasma && systemctl --user start plasma-plasmashell.service
if [[ -f "$BACKUP/dconf.ini" ]] && command -v dconf >/dev/null; then
    dconf reset -f /org/gnome/shell/extensions/
    dconf load / < "$BACKUP/dconf.ini"
fi
echo "Przywrócone. Wyloguj się i zaloguj ponownie. Ramki okien (KDE Rounded Corners) i pakiety zostają;"
echo "usuniesz je ręcznie, np.: sudo pacman -Rns qadwaitadecorations-qt6 waywallen-bin"
