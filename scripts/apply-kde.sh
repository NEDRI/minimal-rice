#!/bin/sh
# Apply the whole Lorien look to a running Plasma 6 session: fonts, colours, icons, the lorien
# Plasma style, window borders and shortcuts, then the top bar, the dock and the desktop tiles.
# Replaces the existing panels. Run it from inside the KDE session; log out and back in afterwards.
set -e
HERE="$(dirname "$(readlink -f "$0")")"
kw() { kwriteconfig6 --file "$1" --group "$2" --key "$3" "$4"; }
kw2() { kwriteconfig6 --file "$1" --group "$2" --group "$3" --key "$4" "$5"; }

python3 -I "$HERE/make-layout.py"
python3 -I "$HERE/make-plasma-style.py"

# ---- look: JetBrains Mono everywhere, system24 colours, Qogir icons, the lorien Plasma style ----
FONT="JetBrainsMono Nerd Font,10,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"
for key in font fixed menuFont toolBarFont; do kw kdeglobals General "$key" "$FONT"; done
kw kdeglobals General smallestReadableFont "JetBrainsMono Nerd Font,8,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"
kw kdeglobals WM activeFont "JetBrainsMono Nerd Font,10,-1,5,700,0,0,0,0,0,0,0,0,0,0,1"
plasma-apply-colorscheme System24 >/dev/null
for icons in Qogir-Dark Qogir-dark Papirus-Dark; do
    if [ -d "/usr/share/icons/$icons" ] || [ -d "$HOME/.local/share/icons/$icons" ]; then
        /usr/lib/plasma-changeicons "$icons" 2>/dev/null || kw kdeglobals Icons Theme "$icons"
        break
    fi
done
plasma-apply-desktoptheme lorien >/dev/null
kw konsolerc "Desktop Entry" DefaultProfile Lorien.profile

# ---- window borders: KDE Rounded Corners in the accent (accent-from-wallpaper.py sets the colour) ----
RC="Round-Corners"
for kv in Size=10 InactiveCornerRadius=10 OutlineThickness=2 InactiveOutlineThickness=1 \
          ActiveOutlineUseCustom=true ActiveOutlineUsePalette=false InactiveOutlineUseCustom=true \
          ActiveOutlineAlpha=255 InactiveOutlineAlpha=115 OutlineColor=181,137,214 InactiveOutlineColor=181,137,214 \
          OutlineIsGradient=false InactiveOutlineIsGradient=false SecondOutlineThickness=0 \
          InactiveSecondOutlineThickness=0 DisableOutlineTile=false DisableRoundTile=false; do
    kw kwinrc "$RC" "${kv%%=*}" "${kv#*=}"
done
kw kwinrc Plugins kwin4_effect_shapecornersEnabled true
kw kwinrc Plugins dynamic_workspacesEnabled true

# ---- shortcuts: Super+Q close, Super+Enter Konsole, Super+Shift+S screenshot, Super+arrows tile ----
kw kglobalshortcutsrc kwin "Window Close" "Alt+F4	Meta+Q,Alt+F4,Close Window"
for d in Left Right Top:Up Bottom:Down; do
    name="${d%%:*}"; key="${d#*:}"
    kw kglobalshortcutsrc kwin "Window Quick Tile $name" "Meta+$key,Meta+$key,Quick Tile Window to the $name"
done
kw2 kglobalshortcutsrc services org.kde.konsole.desktop _launch "Ctrl+Alt+T	Meta+Return"
kw2 kglobalshortcutsrc services org.kde.spectacle.desktop RectangularRegionScreenShot "Meta+Shift+S"
qdbus6 org.kde.KWin /KWin reconfigure >/dev/null 2>&1 || true

# ---- panels and desktop tiles ----
run() { qdbus6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "$(cat "$1")"; }
run "$HERE/layout.js"
sleep 3
run "$HERE/colorizer-top.js"
run "$HERE/colorizer-dock.js"
sleep 3
# Plasma ignores the desktop tiles' geometry from the script: write it with plasmashell stopped
systemctl --user stop plasma-plasmashell.service
python3 -I "$HERE/set-desktop-geometry.py"
rm -f "$HOME"/.cache/plasma_theme_lorien*.kcache "$HOME"/.cache/plasma-svgelements*lorien* "$HOME"/.cache/ksvg-elements*
"$HERE/restart-plasma.sh"
sleep 5
rm -f "$HOME"/.cache/lorien-accent-KDE
python3 -I "$HERE/accent-from-wallpaper.py" || true
echo "KDE gotowe. Wyloguj się i zaloguj ponownie, żeby czcionki i skróty objęły wszystkie aplikacje."
