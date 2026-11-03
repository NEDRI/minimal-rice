// Super+D opens the rofi app launcher (as in Hyprland) and closes it when it is open. KWin keeps the
// shortcut, so it works from the start of the session; rofi runs as the lorien-launcher user service.

function systemd(method) {
    callDBus("org.freedesktop.systemd1", "/org/freedesktop/systemd1", "org.freedesktop.systemd1.Manager",
             method, "lorien-launcher.service", "replace");
}

registerShortcut("Lorien launcher", "Lorien launcher: open or close the app menu", "Meta+D", function () {
    const open = workspace.windowList().some(w => w.resourceClass === "rofi");
    systemd(open ? "StopUnit" : "StartUnit");
});
