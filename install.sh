#!/usr/bin/env bash
# Lorien rice: instalator dla Arch / EndeavourOS / CachyOS (KDE Plasma 6 i GNOME).
#
#   ./install.sh                 wszystko: pakiety, pliki, budowanie, wygląd KDE i GNOME
#   ./install.sh --kde           tylko KDE        ./install.sh --gnome    tylko GNOME
#   ./install.sh --city Kraków   miasto do kafelka pogody (bez pytania)
#   ./install.sh --yes           bez pytań (miasto: Warszawa, jeśli nie podano --city)
#   --no-packages  --no-build  --no-apply   pomija dany krok
#
# Przed nadpisaniem czegokolwiek robi kopię w ~/lorien-backup-<data>; ./uninstall.sh ją przywraca.
set -euo pipefail
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

kde=false gnome=false yes=false packages=true build=true apply=true city=""
while (($#)); do
    case "$1" in
        --kde) kde=true ;;
        --gnome) gnome=true ;;
        --yes|-y) yes=true ;;
        --no-packages) packages=false ;;
        --no-build) build=false ;;
        --no-apply) apply=false ;;
        --city) city="$2"; shift ;;
        -h|--help) sed -n '2,10p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
        *) echo "Nieznana opcja: $1 (zobacz --help)" >&2; exit 2 ;;
    esac
    shift
done
$kde || $gnome || { kde=true; gnome=true; }
noconfirm=(); $yes && noconfirm=(--noconfirm)

say() { printf '\n\033[1;35m==> %s\033[0m\n' "$*"; }
ask() { $yes && return 0; read -rp "$1 [T/n] " a; [[ -z "$a" || "$a" =~ ^[TtYy] ]]; }
list() { grep -v '^\s*#' "$1" | tr -s ' \n' '\n' | grep -v '^$'; }

[[ $EUID -ne 0 ]] || { echo "Uruchom jako zwykły użytkownik, nie root (sudo zapyta o hasło, gdy trzeba)." >&2; exit 1; }
command -v pacman >/dev/null || { echo "To jest instalator dla Archa i pochodnych (brak pacmana)." >&2; exit 1; }

# ---------------------------------------------------------------- pakiety
if $packages; then
    say "Pakiety"
    mapfile -t repo < <(list "$REPO/packages.txt")
    mapfile -t aur < <(list "$REPO/packages-aur.txt")
    echo "Z repozytoriów: ${repo[*]}"
    echo "Z AUR: ${aur[*]}"
    if ask "Zainstalować brakujące pakiety?"; then
        sudo pacman -S --needed "${noconfirm[@]}" "${repo[@]}"
        if ! command -v yay >/dev/null; then
            say "Instaluję yay (pomocnik AUR)"
            tmp="$(mktemp -d)"
            git clone --depth 1 https://aur.archlinux.org/yay-bin.git "$tmp/yay-bin"
            (cd "$tmp/yay-bin" && makepkg -si --noconfirm)
            rm -rf "$tmp"
        fi
        yay -S --needed "${noconfirm[@]}" "${aur[@]}"
    fi
fi

# ---------------------------------------------------------------- kopia zapasowa
BACKUP="$HOME/lorien-backup-$(date +%Y%m%d-%H%M%S)"
say "Kopia zapasowa: $BACKUP"
mkdir -p "$BACKUP"
for rel in .config/kdeglobals .config/kwinrc .config/kglobalshortcutsrc .config/konsolerc .config/plasmarc \
           .config/plasmashellrc .config/plasma-org.kde.plasma.desktop-appletsrc \
           .config/environment.d/20-lorien-decorations.conf .config/autostart/lorien-accent.desktop \
           .config/autostart/waywallen.desktop .local/bin/updateall; do
    [[ -e "$HOME/$rel" ]] && { mkdir -p "$BACKUP/$(dirname "$rel")"; cp -a "$HOME/$rel" "$BACKUP/$rel"; }
done
command -v dconf >/dev/null && dconf dump / > "$BACKUP/dconf.ini" || true
echo "$kde $gnome" > "$BACKUP/components"

# ---------------------------------------------------------------- pliki
say "Kopiuję pliki"
L="$HOME/.local/share"
mkdir -p "$L/lorien-rice" "$HOME/.local/bin" "$L/plasma/plasmoids" "$L/plasma/desktoptheme" "$L/color-schemes" \
         "$L/konsole" "$HOME/.config/panel-colorizer/presets" "$HOME/.config/autostart" "$HOME/.config/environment.d" \
         "$HOME/.config/lorien-rice"
cp -a "$REPO/scripts/." "$L/lorien-rice/"
cp -a "$REPO/bin/updateall" "$HOME/.local/bin/"
ln -sf "$L/lorien-rice/rebuild-corners.sh" "$HOME/.local/bin/ramka"
ln -sf "$L/lorien-rice/rebuild-corners.sh" "$HOME/.local/bin/rmaka"
fill() { sed "s|@HOME@|$HOME|g" "$1" > "$2"; }
for f in "$REPO"/konsole/*; do fill "$f" "$L/konsole/$(basename "$f")"; done
fill "$REPO/config/autostart/lorien-accent.desktop.in" "$HOME/.config/autostart/lorien-accent.desktop"
cp "$REPO/config/autostart/waywallen.desktop" "$HOME/.config/autostart/"
if $kde; then
    for p in "$REPO"/plasma/plasmoids/*; do rm -rf "$L/plasma/plasmoids/$(basename "$p")"; cp -a "$p" "$L/plasma/plasmoids/"; done
    rm -rf "$L/plasma/desktoptheme/lorien"; cp -a "$REPO/plasma/desktoptheme/lorien" "$L/plasma/desktoptheme/"
    cp "$REPO"/plasma/color-schemes/*.colors "$L/color-schemes/"
    cp -a "$REPO/plasma/panel-colorizer-presets/." "$HOME/.config/panel-colorizer/presets/"
fi
if $gnome; then
    mkdir -p "$L/gnome-shell/extensions" "$HOME/.config/systemd/user"
    rm -rf "$L/gnome-shell/extensions/lorien-bar@lorien-rice"
    cp -a "$REPO/gnome/lorien-bar@lorien-rice" "$L/gnome-shell/extensions/"
    cp -a "$REPO/config/systemd/isled.service.d" "$HOME/.config/systemd/user/"
    cp "$REPO/config/environment.d/20-lorien-decorations.conf" "$HOME/.config/environment.d/"
fi

# ---------------------------------------------------------------- pogoda
if $kde; then
    say "Pogoda"
    if [[ -z "$city" ]]; then
        if $yes; then city="Warszawa"; else read -rp "Miasto do kafelka pogody [Warszawa]: " city; city="${city:-Warszawa}"; fi
    fi
    # BBC Weather (silnik pogody Plasmy) zna miejsca po identyfikatorze GeoNames; Open-Meteo go podaje
    station="$(curl -fsSL --get "https://geocoding-api.open-meteo.com/v1/search" --data-urlencode "name=$city" \
        --data "count=1&language=en" | python3 -I -c '
import json, sys
r = json.load(sys.stdin).get("results")
if r:
    r = r[0]
    print("bbcukmet|weather|%s, %s, %s|%d" % (r["name"], r["country"], r["country_code"], r["id"]))
' || true)"
    if [[ -n "$station" ]]; then
        echo "$station" > "$HOME/.config/lorien-rice/weather-station"
        echo "Stacja: ${station#bbcukmet|weather|}"
    else
        echo "Nie znalazłem miasta \"$city\"; kafelek pokaże Szczecin. Zmienisz to: ./install.sh --kde --no-packages --no-build --city <miasto>"
    fi
fi

# ---------------------------------------------------------------- budowanie i widżety z sieci
if $build; then
    if $kde; then
        say "Widżety z GitHuba: wizualizer dźwięku (z poprawką kolorów) i Linexin Launcher"
        tmp="$(mktemp -d)"
        url="$(curl -fsSL https://api.github.com/repos/luisbocanegra/plasma-audio-visualizer/releases/latest |
               python3 -I -c 'import json,sys; print([a["browser_download_url"] for a in json.load(sys.stdin)["assets"] if a["name"].endswith(".plasmoid")][0])')"
        curl -fsSL "$url" -o "$tmp/visualizer.plasmoid"
        kpackagetool6 -t Plasma/Applet -u "$tmp/visualizer.plasmoid" 2>/dev/null || kpackagetool6 -t Plasma/Applet -i "$tmp/visualizer.plasmoid"
        # repaint when the colours change too, so the bars follow the wallpaper accent right away
        vis="$(find "$L/plasma/plasmoids/luisbocanegra.audio.visualizer" -name Visualizer.qml | head -1)"
        if [[ -n "$vis" ]] && ! grep -q onColorsChanged "$vis"; then
            sed -i 's|^\( *\)onValuesChanged: canvas.requestPaint()|&\n\1// lorien-rice: also repaint when the colours change (accent follows the wallpaper)\n\1onColorsChanged: canvas.requestPaint()|' "$vis"
        fi
        git clone --depth 1 https://github.com/Petexy/Linexin-Launcher.git "$tmp/linexin"
        kpackagetool6 -t Plasma/Applet -u "$tmp/linexin/package" 2>/dev/null || kpackagetool6 -t Plasma/Applet -i "$tmp/linexin/package"
        rm -rf "$tmp"

        say "Ramki okien w stylu Hyprlanda (KDE Rounded Corners, wymaga sudo do instalacji)"
        "$L/lorien-rice/rebuild-corners.sh" || echo "Ramki: nie udało się, spróbuj później poleceniem: ramka"
    fi
    if $gnome; then
        say "Mniejsze paski tytułowe aplikacji Qt w GNOME (qadwaitadecorations z poprawką)"
        src="$HOME/.local/src/qadwaitadecorations"
        rm -rf "$src"
        git clone --depth 1 https://aur.archlinux.org/qadwaitadecorations.git "$src"
        printf '\n' >> "$src/PKGBUILD"
        cat "$REPO/patches/qadwaitadecorations/prepare.sh" >> "$src/PKGBUILD"
        sed -i 's/^pkgrel=\([0-9]*\)$/pkgrel=\1.1/' "$src/PKGBUILD"
        (cd "$src" && makepkg -sfi "${noconfirm[@]}") || echo "Paski tytułowe: budowanie się nie udało (reszta działa)."

        say "Rozszerzenia GNOME (Dash to Dock, Blur my Shell, Just Perfection, ArcMenu, Isle)"
        "$L/lorien-rice/install-gnome-extensions.sh"   # Dash to Dock, Blur my Shell, Just Perfection, Isle
        "$L/lorien-rice/install-gnome-extensions.sh" arcmenu@arcmenu.com
    fi
fi

# ---------------------------------------------------------------- wygląd
if $apply; then
    if $gnome; then
        say "Ustawienia GNOME"
        "$L/lorien-rice/make-gnome.sh"
        "$L/lorien-rice/make-gnome-apps.sh"
    fi
    if $kde; then
        if [[ "${XDG_CURRENT_DESKTOP:-}" == *KDE* ]]; then
            say "Wygląd KDE (panele zostaną zastąpione)"
            ask "Zastosować teraz układ paneli i kafelków?" && "$L/lorien-rice/apply-kde.sh"
        else
            echo "KDE: zaloguj się do Plasmy i uruchom: ~/.local/share/lorien-rice/apply-kde.sh"
        fi
    fi
fi

say "Gotowe"
echo "Kopia poprzednich ustawień: $BACKUP (przywrócisz ją: $REPO/uninstall.sh)"
echo "Wyloguj się i zaloguj ponownie. Tapety Wallpaper Engine: otwórz Waywallen z zasobnika i wskaż bibliotekę Steama."
