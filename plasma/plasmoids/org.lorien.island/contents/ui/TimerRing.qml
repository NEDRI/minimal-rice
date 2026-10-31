// the focus timer's ring: white while focusing, green on a break
import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Canvas {
    id: comp
    property var isle
    property real lineWidth: 3
    property real progress: isle.timerTotal > 0 ? 1 - isle.timerLeft / isle.timerTotal : 0
    onProgressChanged: requestPaint()
    onVisibleChanged: requestPaint()
    onPaint: {
        const ctx = getContext("2d");
        ctx.reset();
        const r = Math.min(width, height) / 2 - lineWidth / 2;
        ctx.lineWidth = lineWidth;
        ctx.lineCap = "round";
        ctx.strokeStyle = Qt.rgba(1, 1, 1, 0.18);
        ctx.beginPath();
        ctx.arc(width / 2, height / 2, r, 0, 2 * Math.PI);
        ctx.stroke();
        ctx.strokeStyle = isle.timerPhase === "break" ? isle.green : "white";
        ctx.beginPath();
        ctx.arc(width / 2, height / 2, r, -Math.PI / 2, -Math.PI / 2 + 2 * Math.PI * (1 - progress));
        ctx.stroke();
    }
}
