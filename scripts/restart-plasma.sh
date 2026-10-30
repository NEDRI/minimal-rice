#!/bin/sh
# Restart plasmashell without losing the Waywallen wallpaper.
# Waywallen 0.5.0 keeps its scene renderer bound to the old desktop connection when
# plasmashell restarts, so the wallpaper stays empty; restarting the daemon rebinds it.
systemctl --user restart plasma-plasmashell.service
sleep 5
if busctl --user status org.waywallen.waywallen.Daemon >/dev/null 2>&1; then
    busctl --user call org.waywallen.waywallen.Daemon /org/waywallen/waywallen/Daemon \
        org.waywallen.waywallen.Daemon1 Quit
    sleep 3
    # Start it in its own app unit, not inside whatever ran this script: Plasma names the app
    # behind a notification after the unit (it once showed Waywallen's notifications as "Claude").
    systemd-run --user --quiet --collect --slice=app.slice --unit="app-waywallen-$(date +%s)" \
        "$(command -v waywallen || echo "$HOME/.local/opt/waywallen/waywallen.AppImage")" --no-ui
fi
