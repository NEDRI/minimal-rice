// Album art with rounded corners on a dark placeholder, as Isle's Art.
import QtQuick
import QtQuick.Effects

Rectangle {
    id: comp
    property alias source: image.source
    property int size: 24

    width: size
    height: size
    color: "#2c2c2e"

    Image {
        id: image
        anchors.fill: parent
        sourceSize: Qt.size(comp.size * 2, comp.size * 2)
        fillMode: Image.PreserveAspectCrop
        visible: false
        layer.enabled: true
    }
    Rectangle {
        id: mask
        anchors.fill: parent
        radius: comp.radius
        visible: false
        layer.enabled: true
    }
    MultiEffect {
        anchors.fill: parent
        source: image
        visible: image.status === Image.Ready
        maskEnabled: true
        maskSource: mask
        maskThresholdMin: 0.5
        maskSpreadAtMin: 1.0
    }
}
