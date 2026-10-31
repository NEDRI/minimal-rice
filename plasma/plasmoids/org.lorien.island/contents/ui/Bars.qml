// Isle's music bars: four white bars that bounce at random while playing and rest in a "|ılı" shape.
import QtQuick

Row {
    id: bars

    property real barHeight: 16
    property bool playing: false
    readonly property var rest: [0.45, 1, 0.7, 0.35]

    spacing: 2
    height: barHeight

    Repeater {
        model: 4

        Rectangle {
            id: bar

            property real level: bars.rest[index]

            width: 3
            radius: 1.5
            color: "white"
            height: bars.barHeight * level
            anchors.verticalCenter: parent.verticalCenter
            opacity: bars.playing ? 1 : 110 / 255

            Behavior on level {
                enabled: !bars.playing
                NumberAnimation { duration: 200 }
            }

            NumberAnimation on level {
                id: bounce
                running: false
                easing.type: Easing.InOutSine
                onFinished: bar.next()
            }

            function next() {
                if (!bars.playing || !bars.visible)
                    return;
                bounce.from = level;
                bounce.to = 0.25 + Math.random() * 0.75;
                bounce.duration = 180 + Math.random() * 220;
                bounce.start();
            }

            Connections {
                target: bars
                function onPlayingChanged() {
                    if (bars.playing)
                        bar.next();
                    else {
                        bounce.stop();
                        bar.level = bars.rest[index];
                    }
                }
                function onVisibleChanged() {
                    if (bars.visible && bars.playing)
                        bar.next();
                }
            }

            Component.onCompleted: if (bars.playing) next()
        }
    }
}
