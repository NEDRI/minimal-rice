// Isle's ring: a faint track and an arc that fills clockwise from the top.
import QtQuick

Canvas {
    id: ring

    property real size: 20
    property real lineWidth: 3
    property real trackOpacity: 0.18
    property real progress: 0
    property color color: "white"

    width: size
    height: size
    onProgressChanged: requestPaint()
    onColorChanged: requestPaint()
    onVisibleChanged: requestPaint()
    onPaint: {
        const ctx = getContext("2d");
        ctx.reset();
        const r = size / 2 - lineWidth / 2;
        ctx.lineWidth = lineWidth;
        ctx.lineCap = "round";
        ctx.strokeStyle = Qt.rgba(1, 1, 1, trackOpacity);
        ctx.beginPath();
        ctx.arc(size / 2, size / 2, r, 0, 2 * Math.PI);
        ctx.stroke();
        if (progress <= 0)
            return;
        ctx.strokeStyle = color;
        ctx.beginPath();
        ctx.arc(size / 2, size / 2, r, -Math.PI / 2, -Math.PI / 2 + 2 * Math.PI * Math.min(1, progress));
        ctx.stroke();
    }
}
