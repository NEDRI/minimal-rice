#!/bin/sh
# Pending updates for the org.lorien.updates desktop tile: repo packages, AUR packages,
# then whether the window border effect is enabled and actually loaded in KWin.
checkupdates 2>/dev/null
[ $? -eq 1 ] && echo "@@ERROR"
echo "@@AUR"
yay -Qua 2>/dev/null
echo "@@CORNERS"
kreadconfig6 --file kwinrc --group Plugins --key kwin4_effect_shapecornersEnabled
qdbus6 org.kde.KWin /Effects org.kde.kwin.Effects.isEffectLoaded kwin4_effect_shapecorners 2>/dev/null
