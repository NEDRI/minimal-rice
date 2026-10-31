// A short alert the island grows to show, as Isle's peek.js: a 32 px badge (a ring sweeping to the battery
// level round a bolt for power), title and subtitle, and a large value on the right, 12 px all round.
import QtQuick

Item {
    id: comp
    property var isle
    property var alert: null     // {icon, ring, title, subtitle, value, tone}
    readonly property color toneColor: !alert ? "white" : alert.tone === "good" ? "#30d158" : alert.tone === "bad" ? "#ff453a" : "white"
    readonly property real preferredWidth: Math.min(380, 12 + 32 + 10 + Math.max(title.implicitWidth, sub.implicitWidth) + 16 + value.implicitWidth + 12 + 6)

    // the badge: a gradient disc, faint for neutral alerts, tinted otherwise
    Rectangle {
        id: badge
        x: 12; y: 12
        width: 32; height: 32; radius: 16
        readonly property bool neutral: !comp.alert || !comp.alert.tone || comp.alert.tone === "neutral"
        gradient: Gradient {
            GradientStop { position: 0; color: Qt.rgba(badge.neutral ? 1 : comp.toneColor.r, badge.neutral ? 1 : comp.toneColor.g, badge.neutral ? 1 : comp.toneColor.b, badge.neutral ? 0.16 : 0.34) }
            GradientStop { position: 1; color: Qt.rgba(badge.neutral ? 1 : comp.toneColor.r, badge.neutral ? 1 : comp.toneColor.g, badge.neutral ? 1 : comp.toneColor.b, badge.neutral ? 0.08 : 0.16) }
        }
        Ring {
            id: ring
            anchors.centerIn: parent
            visible: comp.alert && comp.alert.ring !== undefined
            size: 22; lineWidth: 2.5
            color: comp.toneColor
            progress: 0
        }
        IsleIcon {
            anchors.centerIn: parent
            name: comp.alert ? comp.alert.icon : ""
            size: ring.visible ? 12 : 16
            color: comp.toneColor
        }
    }

    Column {
        anchors { left: badge.right; leftMargin: 10; verticalCenter: badge.verticalCenter }
        Text { renderType: Text.QtRendering; id: title; text: comp.alert ? comp.alert.title : ""; color: "white"; font { family: isle.font; pixelSize: 14; weight: Font.DemiBold } }
        Text { renderType: Text.QtRendering; id: sub; text: comp.alert ? comp.alert.subtitle : ""; color: Qt.rgba(1, 1, 1, 0.5); font { family: isle.font; pixelSize: 12 } }
    }

    Text { renderType: Text.QtRendering;
        id: value
        anchors { right: parent.right; rightMargin: 18; verticalCenter: badge.verticalCenter }
        // counts up with the ring, as Isle's
        text: comp.alert && comp.alert.value ? (comp.counting ? Math.round(ring.progress * 100) + "%" : comp.alert.value) : ""
        color: comp.toneColor
        font { family: isle.font; pixelSize: 20; weight: Font.DemiBold; letterSpacing: -0.5 }
        font.features: { "tnum": 1 }
    }
    readonly property bool counting: alert && alert.ring !== undefined && /^\d+%$/.test(alert.value || "")

    // the ring sweeps once the island has made room
    SequentialAnimation {
        id: sweep
        PauseAnimation { duration: 350 }
        NumberAnimation { target: ring; property: "progress"; from: 0; to: comp.alert && comp.alert.ring !== undefined ? comp.alert.ring : 0; duration: 700; easing.type: Easing.OutCubic }
    }
    onAlertChanged: { ring.progress = 0; if (alert && alert.ring !== undefined) sweep.restart(); }
}
