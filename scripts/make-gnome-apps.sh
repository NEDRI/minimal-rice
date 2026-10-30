#!/bin/sh
# Tidy GNOME's app grid: app folders by topic, and hide entries that only make sense in KDE or
# duplicate GNOME's own tools. Hiding copies the launcher to ~/.local/share/applications with
# NotShowIn=GNOME, so KDE keeps showing it. Run again after installing apps you want sorted.
set -e

# ---- hidden in GNOME ----
HIDE="kdesystemsettings org.kde.discover org.kde.plasma-systemmonitor org.kde.spectacle org.kde.kwrite
org.kde.kdeconnect.nonplasma org.kde.kdeconnect.sms eos-apps-info eos-log-tool eos-quickstart eos-update welcome
reflector-simple yad-icon-browser yad-settings assistant designer linguist qdbusviewer qv4l2 qvidcap lstopo
stoken-gui-small org.torproject.torbrowser-launcher.settings"
DST="$HOME/.local/share/applications"
mkdir -p "$DST"
for id in $HIDE; do
    for dir in /usr/share/applications /var/lib/flatpak/exports/share/applications; do
        src="$dir/$id.desktop"
        [ -f "$src" ] || continue
        if [ ! -f "$DST/$id.desktop" ]; then
            cp "$src" "$DST/$id.desktop"
        fi
        # add GNOME to an existing NotShowIn (a second NotShowIn line would override the first)
        if grep -q '^NotShowIn=' "$DST/$id.desktop"; then
            grep -q '^NotShowIn=.*GNOME' "$DST/$id.desktop" || sed -i 's/^NotShowIn=/NotShowIn=GNOME;/' "$DST/$id.desktop"
        else
            sed -i '0,/^\[Desktop Entry\]$/s//[Desktop Entry]\nNotShowIn=GNOME;/' "$DST/$id.desktop"
        fi
        break
    done
done

# ---- folders ----
folder() {  # id, name, desktop ids...
    id=$1 name=$2
    shift 2
    apps=""
    for a in "$@"; do apps="$apps'$a.desktop', "; done
    p=/org/gnome/desktop/app-folders/folders/$id/
    dconf write ${p}name "'$name'"
    dconf write ${p}translate false
    dconf write ${p}apps "[${apps%, }]"
    dconf write ${p}categories "@as []"
    FOLDERS="$FOLDERS'$id', "
}
FOLDERS=""
folder Programming "Programming" matlab cmake-gui nvim vim org.gnome.Meld org.kde.kate org.thonny.Thonny \
    com.jetbrains.CLion dev.zed.Zed org.codeblocks.codeblocks org.gaphor.Gaphor io.github.tobagin.digger \
    com.github.finefindus.eyedropper
folder Electronics "Electronics" org.kicad.kicad org.kicad.eeschema org.kicad.pcbnew org.kicad.gerbview \
    org.kicad.bitmap2component org.kicad.pcbcalculator ltspice stm32cubeide-2.2.0 stm32cubemx stm32cubeprog \
    stm32cubeprog-trusted-package-creator stlink-gui cc.arduino.IDE2 cc.arduino.arduinoide
folder Internet "Internet" com.google.Chrome org.torproject.torbrowser-launcher org.telegram.desktop \
    com.github.IsmaelMartinez.teams_for_linux com.anydesk.Anydesk com.rustdesk.RustDesk org.filezillaproject.Filezilla \
    org.qbittorrent.qBittorrent io.frama.tractor.carburetor io.github.bytezz.IPLookup io.github.vmkspv.netsleuth \
    io.github.zingytomato.netpeek org.kde.kdeconnect.app nm-connection-editor
folder Multimedia "Multimedia" vlc mpv org.kde.haruna io.github.diegopvlk.Cine org.kde.gwenview org.kde.krita \
    com.github.wwmm.easyeffects lsp-plugins org.rncbc.qtractor org.pulseaudio.pavucontrol org.gnome.NetworkDisplays \
    hp-uiscan
folder Office "Office" org.libreoffice.LibreOffice org.libreoffice.LibreOffice.writer org.libreoffice.LibreOffice.calc \
    org.libreoffice.LibreOffice.impress org.libreoffice.LibreOffice.draw org.libreoffice.LibreOffice.math \
    org.libreoffice.LibreOffice.base org.kde.okular
folder Games "Games" com.valvesoftware.Steam com.heroicgameslauncher.hgl org.prismlauncher.PrismLauncher \
    com.usebottles.bottles net.hhoney.tinycrate org.hnefatafl.hnefatafl_client io.github.josephmawa.SpellingBee
folder System "System" btop htop net.nokyan.Resources com.tuxedocomputers.tcc virtualbox org.virt_manager.virt-manager \
    com.ranfdev.DistroShelf ros2 winboat cups system-config-printer hplip com.github.tchx84.Flatseal \
    com.mattjakeman.ExtensionManager org.gnome.tweaks waywallen
folder Tools "Tools" org.kde.ark org.kde.kcalc io.github.vmkspv.lenspect io.github.gaheldev.Millisecond \
    io.gitlab.adhami3310.Impression stoken-gui
dconf write /org/gnome/desktop/app-folders/folder-children "[${FOLDERS%, }]"

# first page: the folders from the top left, then the everyday apps; everything else follows
TOP="com.anthropic.Claude firefox com.microsoft.VSCode org.kde.konsole org.kde.dolphin org.gnome.Nautilus
org.gnome.Settings dev.vencord.Vesktop"
page="" pos=0
for f in $(echo "$FOLDERS" | tr -d "'," ); do page="$page'$f': <{'position': <$pos>}>, "; pos=$((pos + 1)); done
for a in $TOP; do page="$page'$a.desktop': <{'position': <$pos>}>, "; pos=$((pos + 1)); done
gsettings set org.gnome.shell app-picker-layout "[{${page%, }}]"
echo "GNOME app grid organised."
