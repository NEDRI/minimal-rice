// KWin restores the last session's desktops at login, and the session's apps come back to their old desktop
// numbers, so empty desktops stay in front of them; dynamic_workspaces only tidies up when you switch desktops.
// For the first minutes after login (apps from the last session can take a minute to open), every window that
// opens or moves sets off a tidy-up: the windows move left onto consecutive desktops (as dynamic_workspaces
// moves them, so the pager stays right) and one empty desktop stays at the end.
// dynamic_workspaces names the desktops it adds "undefined"; they get KWin's own "Desktop N" names.

const SETTLE_MS = 180000;

function counted(w) {
    return w.normalWindow && !w.skipPager && !w.onAllDesktops;
}

function rename() {
    workspace.desktops.forEach((d, i) => {
        if (d.name === "undefined" || d.name === "" || /^Desktop \d+$/.test(d.name))
            d.name = "Desktop " + (i + 1);
    });
}

function tidy() {
    const desktops = workspace.desktops;
    const windows = workspace.windowList().filter(counted);
    const used = desktops.filter(d => windows.some(w => w.desktops.indexOf(d) !== -1));
    // each used desktop's new place: the next one along, in order
    const target = Math.max(used.indexOf(workspace.currentDesktop), 0);
    for (const w of windows)
        w.desktops = w.desktops.map(d => desktops[Math.max(used.indexOf(d), 0)]);
    workspace.currentDesktop = desktops[target];
    // the rest go from the end, keeping one empty desktop to go to
    while (workspace.desktops.length > used.length + 1)
        workspace.removeDesktop(workspace.desktops[workspace.desktops.length - 1]);
    if (workspace.desktops.length === used.length)
        workspace.createDesktop(workspace.desktops.length, "");
    rename();
}

// the session's windows come one by one: tidy once they stop coming for a moment
const pending = new QTimer();
pending.singleShot = true;
pending.interval = 1500;
pending.timeout.connect(tidy);

let settling = true;
const settled = new QTimer();
settled.singleShot = true;
settled.interval = SETTLE_MS;
settled.timeout.connect(() => { settling = false; });
settled.start();

function later() {
    if (settling)
        pending.start();
}

function watch(w) {
    if (!w || !counted(w))
        return;
    later();
    w.desktopsChanged.connect(later);
}

workspace.windowList().forEach(watch);
workspace.windowAdded.connect(watch);
workspace.desktopsChanged.connect(rename);
pending.start();
