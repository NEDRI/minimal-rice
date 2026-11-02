// KWin restores the last session's desktops at login, and the session's apps come back to their old desktop
// numbers, so empty desktops stay in front of them; dynamic_workspaces only tidies up when you switch desktops.
// This does it right after login, and again as the apps open: the windows move left onto consecutive desktops
// (as dynamic_workspaces moves them, so the pager stays right) and one empty desktop stays at the end.

function counted(w) {
    return w.normalWindow && !w.skipPager && !w.onAllDesktops;
}

function tidy() {
    const desktops = workspace.desktops;
    const windows = workspace.windowList().filter(counted);
    const used = desktops.filter(d => windows.some(w => w.desktops.indexOf(d) !== -1));
    if (used.length === 0)
        return;
    // each used desktop's new place: the next one along, in order
    const shown = workspace.currentDesktop;
    const target = used.indexOf(shown) !== -1 ? used.indexOf(shown) : 0;
    for (const w of windows)
        w.desktops = w.desktops.map(d => desktops[used.indexOf(d) !== -1 ? used.indexOf(d) : 0]);
    workspace.currentDesktop = desktops[target];
    // the rest go from the end, keeping one empty desktop to go to
    while (workspace.desktops.length > used.length + 1)
        workspace.removeDesktop(workspace.desktops[workspace.desktops.length - 1]);
    if (workspace.desktops.length === used.length)
        workspace.createDesktop(workspace.desktops.length, "");
}

for (const delay of [1500, 6000, 20000]) {
    const timer = new QTimer();
    timer.singleShot = true;
    timer.interval = delay;
    timer.timeout.connect(tidy);
    timer.start();
}
