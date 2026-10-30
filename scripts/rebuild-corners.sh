#!/bin/sh
# Rebuild the KDE Rounded Corners window border effect for the installed KWin and load it again.
# Needed after every Plasma/KWin update (log out and back in after the update first).
set -e
SRC="$HOME/.local/src/KDE-Rounded-Corners"
[ -d "$SRC" ] || git clone --depth 1 https://github.com/matinlotfali/KDE-Rounded-Corners.git "$SRC"
cd "$SRC"
# Build from scratch: an old build tree keeps the moc output with the previous KWin version
# in the plugin id, and KWin then rejects the new .so as "built for a different version".
rm -rf build
cmake -B build
cmake --build build -j"$(nproc)"
sudo cmake --install build
if ! qdbus6 org.kde.KWin /Effects >/dev/null 2>&1; then
    echo "Window borders built; KWin loads them at the next KDE login."
    exit 0
fi
qdbus6 org.kde.KWin /Effects org.kde.kwin.Effects.unloadEffect kwin4_effect_shapecorners >/dev/null || true
if [ "$(qdbus6 org.kde.KWin /Effects org.kde.kwin.Effects.loadEffect kwin4_effect_shapecorners)" = "true" ]; then
    qdbus6 org.kde.KWin /Effects org.kde.kwin.Effects.reconfigureEffect kwin4_effect_shapecorners
    echo "Window borders rebuilt and enabled."
else
    echo "The effect was built but KWin did not load it. Details: journalctl --user -b | grep shapecorners" >&2
    exit 1
fi
