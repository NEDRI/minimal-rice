// The island's outline, as Isle's island.js `_outline` with no bar inset: it hangs from the screen's
// top edge, flares into concave shoulders ("ears") there, and rounds its bottom corners.
import QtQuick
import QtQuick.Shapes

Shape {
    id: shape

    property real bodyWidth: 144     // the body, without the shoulders
    property real bodyHeight: 36
    property real radius: 10
    property real shoulder: 7

    readonly property real s: Math.max(0, Math.min(shoulder, bodyHeight / 2))
    readonly property real r: Math.max(0, Math.min(radius, bodyHeight - s, bodyWidth / 2))
    readonly property real lx: (width - bodyWidth) / 2
    readonly property real rx: lx + bodyWidth

    preferredRendererType: Shape.CurveRenderer
    antialiasing: true

    ShapePath {
        fillColor: "black"
        strokeWidth: -1
        startX: shape.lx - shape.s; startY: 0
        PathLine { x: shape.rx + shape.s; y: 0 }
        PathArc { x: shape.rx; y: shape.s; radiusX: shape.s; radiusY: shape.s; direction: PathArc.Counterclockwise }
        PathLine { x: shape.rx; y: shape.bodyHeight - shape.r }
        PathArc { x: shape.rx - shape.r; y: shape.bodyHeight; radiusX: shape.r; radiusY: shape.r }
        PathLine { x: shape.lx + shape.r; y: shape.bodyHeight }
        PathArc { x: shape.lx; y: shape.bodyHeight - shape.r; radiusX: shape.r; radiusY: shape.r }
        PathLine { x: shape.lx; y: shape.s }
        PathArc { x: shape.lx - shape.s; y: 0; radiusX: shape.s; radiusY: shape.s; direction: PathArc.Counterclockwise }
    }
}
