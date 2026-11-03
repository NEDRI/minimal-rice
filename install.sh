#!/usr/bin/env bash
# Lorien rice installer for Arch / EndeavourOS / CachyOS (KDE Plasma 6 and GNOME).
#
#   ./install.sh                 everything: packages, files, builds, the KDE and GNOME look
#   ./install.sh --kde           KDE only         ./install.sh --gnome    GNOME only
#   ./install.sh --city Krakow   city for the weather tile (without asking)
#   ./install.sh --yes           no questions (city: Warsaw unless --city is given)
#   --no-packages  --no-build  --no-apply   skip that step
#
# Before overwriting anything it saves a copy in ~/lorien-backup-<date>; ./uninstall.sh restores it.
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
        *) echo "Unknown option: $1 (see --help)" >&2; exit 2 ;;
    esac
    shift
done
$kde || $gnome || { kde=true; gnome=true; }
noconfirm=(); $yes && noconfirm=(--noconfirm)

say() { printf '\n\033[1;35m==> %s\033[0m\n' "$*"; }
ask() { $yes && return 0; read -rp "$1 [Y/n] " a; [[ -z "$a" || "$a" =~ ^[Yy] ]]; }
list() { grep -v '^\s*#' "$1" | tr -s ' \n' '\n' | grep -v '^$'; }

[[ $EUID -ne 0 ]] || { echo "Run this as your normal user, not root (sudo asks for the password when needed)." >&2; exit 1; }
command -v pacman >/dev/null || { echo "This installer is for Arch and its derivatives (pacman not found)." >&2; exit 1; }

# ---------------------------------------------------------------- packages
if $packages; then
    say "Packages"
    mapfile -t repo < <(list "$REPO/packages.txt")
    mapfile -t aur < <(list "$REPO/packages-aur.txt")
    echo "From the repositories: ${repo[*]}"
    echo "From the AUR: ${aur[*]}"
    if ask "Install the missing packages?"; then
        sudo pacman -S --needed "${noconfirm[@]}" "${repo[@]}"
        if ! command -v yay >/dev/null; then
            say "Installing yay (AUR helper)"
            tmp="$(mktemp -d)"
            git clone --depth 1 https://aur.archlinux.org/yay-bin.git "$tmp/yay-bin"
            (cd "$tmp/yay-bin" && makepkg -si --noconfirm)
            rm -rf "$tmp"
        fi
        yay -S --needed "${noconfirm[@]}" "${aur[@]}"
    fi
fi

# ---------------------------------------------------------------- backup
BACKUP="$HOME/lorien-backup-$(date +%Y%m%d-%H%M%S)"
say "Backup: $BACKUP"
mkdir -p "$BACKUP"
for rel in .config/kdeglobals .config/kwinrc .config/kglobalshortcutsrc .config/konsolerc .config/plasmarc \
           .config/plasmashellrc .config/plasma-org.kde.plasma.desktop-appletsrc \
           .config/environment.d/20-lorien-decorations.conf .config/autostart/lorien-accent.desktop \
           .config/autostart/waywallen.desktop .config/rofi/config.rasi .local/bin/updateall; do
    [[ -e "$HOME/$rel" ]] && { mkdir -p "$BACKUP/$(dirname "$rel")"; cp -a "$HOME/$rel" "$BACKUP/$rel"; }
done
command -v dconf >/dev/null && dconf dump / > "$BACKUP/dconf.ini" || true
echo "$kde $gnome" > "$BACKUP/components"

# ---------------------------------------------------------------- files
say "Copying files"
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
    mkdir -p "$L/kwin/scripts"
    for k in "$REPO"/kwin/scripts/*; do rm -rf "$L/kwin/scripts/$(basename "$k")"; cp -a "$k" "$L/kwin/scripts/"; done
    # Super+D: the rofi app launcher, as in Hyprland
    mkdir -p "$HOME/.config/rofi" "$HOME/.config/systemd/user"
    cp "$REPO/config/rofi/config.rasi" "$HOME/.config/rofi/"
    cp "$REPO/config/systemd/user/lorien-launcher.service" "$HOME/.config/systemd/user/"
    systemctl --user daemon-reload 2>/dev/null || true
fi
if $gnome; then
    mkdir -p "$L/gnome-shell/extensions" "$HOME/.config/systemd/user"
    rm -rf "$L/gnome-shell/extensions/lorien-bar@lorien-rice"
    cp -a "$REPO/gnome/lorien-bar@lorien-rice" "$L/gnome-shell/extensions/"
    cp "$REPO/config/environment.d/20-lorien-decorations.conf" "$HOME/.config/environment.d/"
fi

# ---------------------------------------------------------------- weather
if $kde; then
    say "Weather"
    if [[ -z "$city" ]]; then
        if $yes; then city="Warsaw"; else read -rp "City for the weather tile [Warsaw]: " city; city="${city:-Warsaw}"; fi
    fi
    # BBC Weather (Plasma's weather engine) knows places by their GeoNames id, which Open-Meteo returns
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
        echo "Station: ${station#bbcukmet|weather|}"
    else
        echo "City \"$city\" not found; the tile will show Szczecin. Change it with: ./install.sh --kde --no-packages --no-build --city <city>"
    fi
fi

# ---------------------------------------------------------------- builds and widgets from the web
if $build; then
    if $kde; then
        say "Widgets from GitHub: audio visualizer (with the colour fix) and Linexin Launcher"
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

        # The island (org.lorien.island) reads music, the focus timer and power alerts from isled, the
        # background service of Isle for GNOME; Isle's installer puts it in ~/.local/bin as a user service.
        if [[ ! -x "$HOME/.local/bin/isled" ]]; then
            say "isled, the island's background service (from Isle)"
            curl -fsSL https://raw.githubusercontent.com/zickrian/isle/main/get.sh | bash ||
                echo "isled could not be installed; the island shows only the clock until it is."
        fi

        say "Hyprland-style window borders (KDE Rounded Corners, installing needs sudo)"
        "$L/lorien-rice/rebuild-corners.sh" || echo "Window borders failed; try again later with: ramka"
    fi
    if $gnome; then
        say "Smaller title bars for Qt apps in GNOME (patched qadwaitadecorations)"
        src="$HOME/.local/src/qadwaitadecorations"
        rm -rf "$src"
        git clone --depth 1 https://aur.archlinux.org/qadwaitadecorations.git "$src"
        printf '\n' >> "$src/PKGBUILD"
        cat "$REPO/patches/qadwaitadecorations/prepare.sh" >> "$src/PKGBUILD"
        sed -i 's/^pkgrel=\([0-9]*\)$/pkgrel=\1.1/' "$src/PKGBUILD"
        (cd "$src" && makepkg -sfi "${noconfirm[@]}") || echo "Title bars: the build failed (everything else works)."

        say "GNOME extensions (Dash to Dock, Blur my Shell, Just Perfection, ArcMenu, Isle)"
        "$L/lorien-rice/install-gnome-extensions.sh"   # Dash to Dock, Blur my Shell, Just Perfection, Isle
        "$L/lorien-rice/install-gnome-extensions.sh" arcmenu@arcmenu.com
    fi
fi

# ---------------------------------------------------------------- look
if $apply; then
    if $gnome; then
        say "GNOME settings"
        "$L/lorien-rice/make-gnome.sh"
        "$L/lorien-rice/make-gnome-apps.sh"
    fi
    if $kde; then
        if [[ "${XDG_CURRENT_DESKTOP:-}" == *KDE* ]]; then
            say "KDE look (your panels will be replaced)"
            ask "Apply the panel and tile layout now?" && "$L/lorien-rice/apply-kde.sh"
        else
            echo "KDE: log in to Plasma and run: ~/.local/share/lorien-rice/apply-kde.sh"
        fi
    fi
fi

say "Done"
echo "Backup of your previous settings: $BACKUP (restore it with: $REPO/uninstall.sh)"
echo "Log out and log back in. Wallpaper Engine wallpapers: open Waywallen from the tray and point it to your Steam library."
