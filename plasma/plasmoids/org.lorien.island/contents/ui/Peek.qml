// A short alert the island grows to show, as Isle's peek.js: a 32 px lead (an icon on a lit badge, a ring
// sweeping round a small badge, a cover with the player's icon, or an app's own icon), title and subtitle,
// and on the right a large value, a status pill or a level bar; buttons under the words, 12 px all round.
// alert: {icon, appIcon, art, artBadge, ring, title, subtitle, subtitleLines, value, status, level,
//         levelText, tone, actions: [{label, primary, callback}], closable}
import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Item {
    id: comp
    property var isle
    property var alert: null
    signal closeRequested()

    readonly property color toneColor: !alert ? "white" : ({ good: "#30d158", focus: "#30d158", bad: "#ff453a", warn: "#ff9f0a" })[alert.tone] || "white"
    readonly property bool neutral: !alert || !alert.tone || alert.tone === "neutral"
    readonly property bool hasRing: !!alert && alert.ring !== undefined && alert.ring !== null
    readonly property bool hasLevel: !!alert && alert.level !== undefined && alert.level !== null
    readonly property var actions: alert && alert.actions ? alert.actions : []
    readonly property bool actionsBeside: actions.length === 1
    // what the right side holds (not `visible`: the copy that is only measured is never on screen)
    readonly property bool valueShown: !!(alert && alert.value) && !hasLevel
    readonly property bool statusShown: !!(alert && alert.status)
    readonly property bool singleShown: actionsBeside && !valueShown && !statusShown && !hasLevel
    // the widest an alert gets is 380 px; narrower, it fits its content
    readonly property real preferredWidth: Math.min(380, 12 + 32 + 10 + Math.max(titleText.implicitWidth, subText.implicitWidth, 60)
        + (accessory.implicitWidth > 0 ? 16 + accessory.implicitWidth : 0) + 12 + 6)
    readonly property real preferredHeight: Math.max(32, texts.implicitHeight) + 24
    readonly property bool hovered: hover.hovered

    HoverHandler { id: hover }

    RowLayout {
        id: row
        anchors { left: parent.left; right: parent.right; top: parent.top; leftMargin: 12; rightMargin: 12; topMargin: 12 }
        spacing: 10

        // ---------------------------------------------------------------- the lead
        Item {
            Layout.preferredWidth: 32
            Layout.preferredHeight: 32
            Layout.alignment: comp.actions.length > 1 ? Qt.AlignTop : Qt.AlignVCenter

            // a symbolic icon on a badge lit from the top in the alert's colour, grey when neutral
            Rectangle {
                anchors.fill: parent
                visible: !comp.hasRing && !(comp.alert && (comp.alert.art || comp.alert.appIcon))
                radius: 16
                gradient: Gradient {
                    GradientStop { position: 0; color: comp.neutral ? Qt.rgba(1, 1, 1, 0.16) : Qt.rgba(comp.toneColor.r, comp.toneColor.g, comp.toneColor.b, 0.34) }
                    GradientStop { position: 1; color: comp.neutral ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(comp.toneColor.r, comp.toneColor.g, comp.toneColor.b, 0.16) }
                }
                IsleIcon {
                    anchors.centerIn: parent
                    name: comp.alert && comp.alert.icon && comp.alert.icon.startsWith("isle-") ? comp.alert.icon : ""
                    visible: name !== ""
                    size: 16
                    color: comp.toneColor
                }
                Kirigami.Icon {
                    anchors.centerIn: parent
                    width: 16; height: 16
                    visible: !!(comp.alert && comp.alert.icon && !comp.alert.icon.startsWith("isle-"))
                    source: visible ? comp.alert.icon : ""
                    isMask: true
                    color: comp.toneColor
                }
            }
            // a ring that sweeps up to a level, round a small badge
            Ring {
                id: ring
                anchors.fill: parent
                visible: comp.hasRing
                size: 32; lineWidth: 3
                color: comp.toneColor
                progress: 0
                Rectangle {
                    anchors.centerIn: parent
                    width: 22; height: 22; radius: 11
                    gradient: Gradient {
                        GradientStop { position: 0; color: comp.neutral ? Qt.rgba(1, 1, 1, 0.16) : Qt.rgba(comp.toneColor.r, comp.toneColor.g, comp.toneColor.b, 0.34) }
                        GradientStop { position: 1; color: comp.neutral ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(comp.toneColor.r, comp.toneColor.g, comp.toneColor.b, 0.16) }
                    }
                    IsleIcon { anchors.centerIn: parent; name: comp.alert && comp.hasRing ? comp.alert.icon : ""
                               size: comp.alert && comp.alert.ringIconSize ? comp.alert.ringIconSize : 12; color: comp.toneColor }
                }
            }
            // a cover, with the player's icon as a small badge at its corner
            Art {
                anchors.fill: parent
                visible: !!(comp.alert && comp.alert.art)
                size: 32; radius: 8
                source: comp.alert && comp.alert.art ? "file://" + comp.alert.art : ""
                Rectangle {
                    x: parent.width - width + 4; y: parent.height - height + 4
                    width: 16; height: 16; radius: 8
                    color: "black"
                    visible: !!(comp.alert && comp.alert.artBadge)
                    Kirigami.Icon { anchors.centerIn: parent; width: 12; height: 12; source: comp.alert && comp.alert.artBadge ? comp.alert.artBadge : "" }
                }
            }
            // an app's own colour icon stands alone
            Kirigami.Icon {
                anchors.fill: parent
                anchors.margins: 2
                visible: !!(comp.alert && comp.alert.appIcon)
                source: comp.alert && comp.alert.appIcon ? comp.alert.appIcon : ""
            }
            // closable alerts: × in place of the lead under the pointer
            IsleButton {
                anchors.centerIn: parent
                visible: !!(comp.alert && comp.alert.closable) && comp.hovered
                padding: 9; icon: "isle-close-symbolic"; iconSize: 14
                color: hovered ? "#4a4a4c" : "#3a3a3c"
                onClicked: comp.closeRequested()
            }
        }

        // ---------------------------------------------------------------- the words, and buttons under them
        ColumnLayout {
            id: texts
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 0
            Text { renderType: Text.QtRendering;
                id: titleText
                Layout.fillWidth: true
                text: comp.alert ? (comp.alert.title || "") : ""
                elide: Text.ElideRight
                color: "white"
                font { family: isle.font; pixelSize: 14; weight: Font.DemiBold }
            }
            Text { renderType: Text.QtRendering;
                id: subText
                Layout.fillWidth: true
                visible: text !== ""
                Layout.preferredWidth: Math.min(implicitWidth, 380 - 12 - 32 - 10 - 12 - 6 - (accessory.implicitWidth > 0 ? 16 + accessory.implicitWidth : 0))
                text: comp.alert ? (comp.alert.subtitle || "") : ""
                wrapMode: Text.Wrap
                maximumLineCount: comp.alert && comp.alert.subtitleLines ? comp.alert.subtitleLines : 1
                elide: Text.ElideRight
                color: Qt.rgba(1, 1, 1, 0.5)
                font { family: isle.font; pixelSize: 12 }
            }
            Flow {
                Layout.fillWidth: true
                Layout.topMargin: 10
                visible: comp.actions.length > 1
                spacing: 8
                Repeater {
                    model: comp.actions.length > 1 ? comp.actions : []
                    Pill { label: modelData.label; primary: !!modelData.primary; onClicked: modelData.callback() }
                }
            }
        }

        // ---------------------------------------------------------------- on the right
        Item {
            id: accessory
            Layout.alignment: Qt.AlignVCenter
            Layout.leftMargin: implicitWidth > 0 ? 6 : 0
            implicitWidth: comp.valueShown ? valueText.implicitWidth : comp.statusShown ? statusPill.width
                : comp.hasLevel ? levelBox.implicitWidth : comp.singleShown ? single.width : 0
            implicitHeight: 32

            Text { renderType: Text.QtRendering;
                id: valueText
                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                visible: comp.valueShown
                // counts up with the ring's sweep
                text: !visible ? "" : comp.hasRing && /^\d+%$/.test(comp.alert.value) ? Math.round(ring.progress * 100) + "%" : comp.alert.value
                color: comp.toneColor
                font { family: isle.font; pixelSize: 20; weight: Font.DemiBold; letterSpacing: -0.5 }
                font.features: { "tnum": 1 }
            }
            // a short state, e.g. Caps Lock "On", in the alert's colour
            Rectangle {
                id: statusPill
                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                visible: comp.statusShown
                width: statusText.implicitWidth + 20
                height: statusText.implicitHeight + 6
                radius: height / 2
                color: Qt.rgba(comp.neutral ? 1 : comp.toneColor.r, comp.neutral ? 1 : comp.toneColor.g, comp.neutral ? 1 : comp.toneColor.b, 0.14)
                Text { renderType: Text.QtRendering;
                    id: statusText
                    anchors.centerIn: parent
                    text: comp.alert && comp.alert.status ? comp.alert.status : ""
                    color: comp.toneColor
                    font { family: isle.font; pixelSize: 12; weight: Font.DemiBold }
                }
            }
            // a level: volume, brightness
            Row {
                id: levelBox
                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                visible: comp.hasLevel
                spacing: 8
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 72; height: 5; radius: 3
                    color: Qt.rgba(1, 1, 1, 0.18)
                    Rectangle {
                        height: 5; radius: 3
                        color: comp.toneColor
                        width: comp.hasLevel ? Math.round(72 * Math.max(0, Math.min(1, comp.alert.level))) : 0
                        Behavior on width { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                    }
                }
                Text { renderType: Text.QtRendering;
                    anchors.verticalCenter: parent.verticalCenter
                    width: 30
                    horizontalAlignment: Text.AlignRight
                    text: comp.alert && comp.alert.levelText ? comp.alert.levelText : ""
                    color: "white"
                    font { family: isle.font; pixelSize: 12; weight: Font.DemiBold }
                    font.features: { "tnum": 1 }
                }
            }
            // one button beside the words
            Pill {
                id: single
                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                visible: comp.singleShown
                label: comp.actionsBeside ? comp.actions[0].label : ""
                onClicked: comp.actions[0].callback()
            }
        }
    }

    component Pill: Rectangle {
        id: pill
        property string label: ""
        property bool primary: false
        signal clicked()
        width: pillText.implicitWidth + 28
        height: pillText.implicitHeight + 10
        radius: height / 2
        color: primary ? (pillArea.containsMouse ? Qt.rgba(1, 1, 1, 0.86) : "white")
            : pillArea.pressed ? "#48484a" : pillArea.containsMouse ? "#3a3a3c" : "#2c2c2e"
        Text { renderType: Text.QtRendering;
            id: pillText
            anchors.centerIn: parent
            text: pill.label
            color: pill.primary ? "black" : "white"
            font { family: isle.font; pixelSize: 12; weight: Font.DemiBold }
        }
        MouseArea { id: pillArea; anchors.fill: parent; hoverEnabled: true; onClicked: pill.clicked() }
    }

    // the ring sweeps once the island has made room
    SequentialAnimation {
        id: sweep
        PauseAnimation { duration: 350 }
        NumberAnimation { target: ring; property: "progress"; from: 0; to: comp.hasRing ? comp.alert.ring : 0; duration: 700; easing.type: Easing.OutCubic }
    }
    property string lastKey: ""
    onAlertChanged: {
        const key = alert ? (alert.key || "") + ":" + (alert.title || "") : "";
        if (key === lastKey && hasRing) {
            ring.progress = alert.ring;       // updated in place: no new sweep
            return;
        }
        lastKey = key;
        ring.progress = 0;
        if (hasRing)
            sweep.restart();
    }
}
