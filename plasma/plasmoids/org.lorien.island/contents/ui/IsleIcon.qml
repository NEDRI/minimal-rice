// One of Isle's own icons (contents/icons), tinted.
import QtQuick
import org.kde.kirigami as Kirigami

Kirigami.Icon {
    property string name: ""
    property int size: 16
    width: size
    height: size
    source: name ? Qt.resolvedUrl("../icons/" + name + ".svg") : ""
    isMask: true
    color: "white"
}
