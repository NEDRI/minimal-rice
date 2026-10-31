// Super+H: the active window floats in the middle of the work area (the screen less the bar and the dock),
// GAP px from every edge; pressed again, it goes back to where it was (maximized or not). The floating dock
// draws DOCK_INSET px above the edge of the work area it reserves, so the gap above it gets those too.
const GAP = 16;
const DOCK_INSET = 8;
const saved = {};

function toggle() {
    const w = workspace.activeWindow;
    if (!w || !w.normalWindow || !w.resizeable || !w.moveable)
        return;
    const id = String(w.internalId);
    if (saved[id]) {
        const s = saved[id];
        delete saved[id];
        if (s.maximized)
            w.setMaximize(true, true);
        else
            w.frameGeometry = s.geometry;
        return;
    }
    const area = workspace.clientArea(KWin.MaximizeArea, w);
    const maximized = w.width >= area.width - 1 && w.height >= area.height - 1;
    saved[id] = { geometry: Object.assign({}, { x: w.frameGeometry.x, y: w.frameGeometry.y,
        width: w.frameGeometry.width, height: w.frameGeometry.height }), maximized: maximized };
    if (maximized)
        w.setMaximize(false, false);
    w.frameGeometry = { x: area.x + GAP, y: area.y + GAP, width: area.width - 2 * GAP, height: area.height - 2 * GAP - DOCK_INSET };
}

registerShortcut("LorienCenterWindow", "Lorien: Centre the window with gaps", "Meta+H", toggle);
workspace.windowRemoved.connect(w => delete saved[String(w.internalId)]);
