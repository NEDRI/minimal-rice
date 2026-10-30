#!/bin/sh
# Set up the GNOME session to look and work like the Lorien KDE rice. Only touches GNOME's own
# settings (dconf) and a wallpaper file, so it is safe to run from KDE; KDE ignores all of it.
set -e
HERE="$(dirname "$(readlink -f "$0")")"
ACCENT="#b589d6"   # system24 purple-2, the KDE accent's default

# ---- wallpaper: ~/Pictures/Wallpapers/lorien-gnome.png when there is one (Waywallen draws a live
# wallpaper over it anyway); otherwise GNOME's own stays ----
WALL="$HOME/Pictures/Wallpapers/lorien-gnome.png"
if [ -f "$WALL" ]; then
    for key in picture-uri picture-uri-dark; do
        gsettings set org.gnome.desktop.background "$key" "file://$WALL"
    done
    gsettings set org.gnome.desktop.background picture-options zoom
    gsettings set org.gnome.desktop.screensaver picture-uri "file://$WALL"
fi

# ---- look: dark, purple accent, Qogir icons and cursor, JetBrains Mono everywhere ----
I=org.gnome.desktop.interface
gsettings set $I color-scheme prefer-dark
gsettings set $I accent-color purple
gsettings set $I gtk-theme Adwaita-dark
gsettings set $I icon-theme Qogir-Dark
gsettings set $I cursor-theme Qogir-Dark
gsettings set $I font-name "JetBrainsMono Nerd Font 10"
gsettings set $I document-font-name "JetBrainsMono Nerd Font 10"
gsettings set $I monospace-font-name "JetBrainsMono Nerd Font 10"
gsettings set $I clock-format 24h
gsettings set $I enable-hot-corners false
gsettings set $I show-battery-percentage true
gsettings set org.gnome.desktop.wm.preferences titlebar-font "JetBrainsMono Nerd Font Bold 10"
gsettings set org.gnome.desktop.wm.preferences button-layout "appmenu:minimize,maximize,close"

# ---- input: the same keyboard layouts as KDE (pl, us), tap to click ----
gsettings set org.gnome.desktop.input-sources sources "[('xkb', 'pl'), ('xkb', 'us')]"
gsettings set org.gnome.desktop.peripherals.touchpad tap-to-click true

# ---- shortcuts as in KDE: Super+Enter Konsole, Super+Q close; Super+arrows tile (GNOME default) ----
gsettings set org.gnome.desktop.wm.keybindings close "['<Super>q', '<Alt>F4']"
gsettings set org.gnome.shell.keybindings show-screenshot-ui "['Print', '<Super><Shift>s']"
gsettings set org.gnome.settings-daemon.plugins.media-keys home "['<Super>e']"
KB=/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/lorien-terminal/
gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "['$KB']"
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$KB name "Konsole"
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$KB command "konsole"
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$KB binding "<Super>Return"

# ---- extensions: the ones from Arch packages now; dock, blur and panel tweaks once installed by
# install-gnome-extensions.sh (their settings are written below already, so they start configured) ----
gsettings set org.gnome.shell disable-user-extensions false
gsettings set org.gnome.shell enabled-extensions "['appindicatorsupport@rgcjonas.gmail.com', 'Vitals@CoreCoding.com', 'dash-to-dock@micxgx.gmail.com', 'blur-my-shell@aunetx', 'just-perfection-desktop@just-perfection', 'isle@zickrian.github.io', 'org.waywallen.gnome@waywallen.io', 'arcmenu@arcmenu.com', 'lorien-bar@lorien-rice']"
gsettings set org.gnome.shell favorite-apps "['org.kde.dolphin.desktop', 'firefox.desktop', 'org.kde.konsole.desktop', 'com.microsoft.VSCode.desktop', 'dev.vencord.Vesktop.desktop', 'tidal-hifi.desktop', 'org.gnome.Settings.desktop']"

# Vitals: CPU, RAM, download, upload and battery on the left, like the KDE pills
V=/org/gnome/shell/extensions/vitals/
dconf write ${V}hot-sensors "['_processor_usage_', '_memory_usage_', '__network-rx_max__', '__network-tx_max__']"
dconf write ${V}position-in-panel 0
dconf write ${V}use-higher-precision false
dconf write ${V}hide-icons false
dconf write ${V}fixed-widths true
dconf write ${V}icon-style 1
dconf write ${V}show-battery false
dconf write ${V}battery-slot 0

# Dash to Dock: a floating dark dock at the bottom with accent dots under running apps
D=/org/gnome/shell/extensions/dash-to-dock/
dconf write ${D}dock-position "'BOTTOM'"
dconf write ${D}dock-fixed true
dconf write ${D}extend-height false
dconf write ${D}dash-max-icon-size 40
dconf write ${D}height-fraction 0.9
dconf write ${D}apply-custom-theme false
dconf write ${D}custom-background-color true
dconf write ${D}background-color "'#141414'"
dconf write ${D}transparency-mode "'FIXED'"
dconf write ${D}background-opacity 0.85
dconf write ${D}running-indicator-style "'DOTS'"
dconf write ${D}custom-theme-customize-running-dots true
dconf write ${D}custom-theme-running-dots-color "'$ACCENT'"
dconf write ${D}custom-theme-shrink true
dconf write ${D}show-trash false
dconf write ${D}show-mounts false
dconf write ${D}show-show-apps-button true
dconf write ${D}show-apps-at-top true
dconf write ${D}shortcut "@as []"   # its Super+Q would swallow the close-window shortcut
dconf write ${D}shortcut-text "''"

# Blur my Shell: a see-through blurred top bar, as in KDE where the wallpaper shows through
B=/org/gnome/shell/extensions/blur-my-shell/
dconf write ${B}panel/blur false   # Isle draws the island over the bar; blurring it darkens the island
dconf write ${B}panel/static-blur true
dconf write ${B}dash-to-dock/blur false

# Just Perfection: no Activities button (the workspace dots stay), no hot corner
J=/org/gnome/shell/extensions/just-perfection/
dconf write ${J}activities-button false
dconf write ${J}workspace-popup false
dconf write ${J}startup-status 0

echo "GNOME ustawiony. Rozszerzenia: $HERE/install-gnome-extensions.sh"
