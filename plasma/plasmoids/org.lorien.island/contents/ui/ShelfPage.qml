// The Shelf page, as Isle's pages/shelf.js, clips.js and files.js: Clipboard (copy history as cards, newest
// first, pinned first; click to copy, hover for pin and ×) and Files (dropped files to drag or copy into any
// app). Both live in isled. In KDE, Klipper tells the island when something is copied (see main.qml).
import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Item {
    id: comp
    property var isle
    property string tab: "clipboard"
    property string filter: ""
    property string query: ""
    property bool confirming: false
    readonly property var clips: (isle.clipboard || [])
        .filter(c => !filter || c.kind === filter)
        .filter(c => !query || (c.preview || "").toLowerCase().indexOf(query.toLowerCase()) >= 0)
        .sort((a, b) => (b.pinned - a.pinned) || (b.at_ms - a.at_ms))
    readonly property var files: isle.shelf || []
    readonly property int capacity: 6

    function ago(ms) {
        const minutes = Math.floor((isle.nowMs - ms) / 60000);
        if (minutes < 1) return "now";
        if (minutes < 60) return minutes + "m";
        if (minutes < 24 * 60) return Math.floor(minutes / 60) + "h";
        return Qt.formatDate(new Date(ms), minutes < 6 * 24 * 60 ? "ddd" : "d MMM");
    }
    function host(url) { const m = /^[a-z]+:\/\/([^\/?#]+)/i.exec(url); return m ? m[1].replace(/^www\./, "") : url; }

    // a segmented control: the chosen segment a raised pill
    component Segment: Rectangle {
        id: seg
        property string text: ""
        property string icon: ""
        property bool checked: false
        signal clicked()
        implicitWidth: (icon ? 13 + 12 : segText.implicitWidth + 20)
        implicitHeight: 22
        radius: height / 2
        gradient: Gradient {
            GradientStop { position: 0; color: seg.checked ? "#4a4a4d" : segArea.containsMouse ? Qt.rgba(1, 1, 1, 0.05) : "transparent" }
            GradientStop { position: 1; color: seg.checked ? "#3a3a3c" : segArea.containsMouse ? Qt.rgba(1, 1, 1, 0.05) : "transparent" }
        }
        Text { renderType: Text.QtRendering;
            id: segText
            anchors.centerIn: parent
            visible: !seg.icon
            text: seg.text
            color: seg.checked || segArea.containsMouse ? "white" : Qt.rgba(1, 1, 1, 0.6)
            font { family: isle.font; pixelSize: 12; weight: Font.DemiBold }
        }
        IsleIcon {
            anchors.centerIn: parent
            visible: !!seg.icon
            name: seg.icon
            size: 13
            opacity: seg.checked || segArea.containsMouse ? 1 : 0.6
        }
        MouseArea { id: segArea; anchors.fill: parent; hoverEnabled: true; onClicked: seg.clicked() }
    }
    component Segmented: Rectangle {
        default property alias segments: row.data
        implicitWidth: row.implicitWidth + 6
        implicitHeight: row.implicitHeight + 6
        radius: height / 2
        color: "#1c1c1e"
        Row { id: row; x: 3; y: 3; spacing: 2 }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 8

        // the tabs, then the controls of the tab shown: filters, search and Clear, or the files hint
        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            Segmented {
                Segment { text: "Clipboard"; checked: comp.tab === "clipboard"; onClicked: comp.tab = "clipboard" }
                Segment { text: "Files"; checked: comp.tab === "files"; onClicked: comp.tab = "files" }
            }
            RowLayout {
                Layout.fillWidth: true
                visible: comp.tab === "clipboard"
                spacing: 8
                Segmented {
                    Repeater {
                        model: [ { kind: "text", icon: "isle-text" }, { kind: "link", icon: "isle-link" },
                                 { kind: "image", icon: "isle-image" }, { kind: "files", icon: "isle-file" } ]
                        Segment { icon: modelData.icon; checked: comp.filter === modelData.kind
                                  onClicked: comp.filter = comp.filter === modelData.kind ? "" : modelData.kind }
                    }
                }
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 26
                    radius: height / 2
                    color: search.activeFocus ? "#2c2c2e" : "#1c1c1e"
                    IsleIcon { id: searchIcon; x: 12; anchors.verticalCenter: parent.verticalCenter; name: "isle-search"; size: 12; opacity: 0.55 }
                    TextInput { renderType: Text.QtRendering;
                        id: search
                        anchors { left: searchIcon.right; leftMargin: 6; right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter }
                        color: "white"
                        clip: true
                        font { family: isle.font; pixelSize: 12 }
                        onTextChanged: comp.query = text
                        Keys.onEscapePressed: text = ""
                        Text { renderType: Text.QtRendering; visible: !parent.text; text: "Search"; color: Qt.rgba(1, 1, 1, 0.45); font: parent.font }
                    }
                }
                // the trash swaps for "Clear all" for a few seconds, so one click never wipes it
                IsleButton {
                    visible: !comp.confirming && (isle.clipboard || []).length > 0
                    padding: 6; icon: "isle-trash"; iconSize: 13
                    onClicked: { comp.confirming = true; confirmTimer.restart(); }
                }
                Rectangle {
                    visible: comp.confirming
                    implicitWidth: confirmText.implicitWidth + 24
                    implicitHeight: 26
                    radius: height / 2
                    color: confirmArea.containsMouse ? "#3a3a3c" : "#2c2c2e"
                    Text { renderType: Text.QtRendering; id: confirmText; anchors.centerIn: parent; text: "Clear all"; color: "white"
                           font { family: isle.font; pixelSize: 12 } }
                    MouseArea { id: confirmArea; anchors.fill: parent; hoverEnabled: true
                                onClicked: { isle.daemon.call("Clipboard1", "Clear"); comp.confirming = false; } }
                }
                Timer { id: confirmTimer; interval: 3000; onTriggered: comp.confirming = false }
            }
            Text { renderType: Text.QtRendering;
                Layout.fillWidth: true
                visible: comp.tab === "files"
                horizontalAlignment: Text.AlignRight
                elide: Text.ElideLeft
                text: comp.files.length === 0 ? "" : comp.files.length >= comp.capacity ? "Full · remove a file to add another"
                    : comp.files.length + " of " + comp.capacity + " · click to copy, or drag into any app"
                color: drop.containsDrag ? "white" : Qt.rgba(1, 1, 1, 0.55)
                font { family: isle.font; pixelSize: 12; weight: drop.containsDrag ? Font.DemiBold : Font.Normal }
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            // ---------------------------------------------------------------- Clipboard
            Column {
                anchors.centerIn: parent
                visible: comp.tab === "clipboard" && comp.clips.length === 0
                spacing: 4
                IsleIcon { anchors.horizontalCenter: parent.horizontalCenter; name: "isle-clipboard"; size: 24; opacity: 0.35 }
                Text { renderType: Text.QtRendering; anchors.horizontalCenter: parent.horizontalCenter; color: "white"
                       text: comp.query || comp.filter ? "Nothing found" : "Nothing copied yet"
                       font { family: isle.font; pixelSize: 15; weight: Font.DemiBold; letterSpacing: -0.1 } }
                Text { renderType: Text.QtRendering; anchors.horizontalCenter: parent.horizontalCenter; color: Qt.rgba(1, 1, 1, 0.5)
                       text: comp.query || comp.filter ? "Try other words or another filter" : "What you copy shows here"
                       font { family: isle.font; pixelSize: 12 } }
            }
            ListView {
                id: cards
                anchors.fill: parent
                visible: comp.tab === "clipboard"
                orientation: ListView.Horizontal
                spacing: 8
                clip: true
                model: comp.clips
                delegate: Rectangle {
                    id: card
                    required property var modelData
                    property bool flashed: false
                    width: 136; height: 96
                    anchors.verticalCenter: parent ? parent.verticalCenter : undefined
                    radius: 12
                    color: cardArea.containsMouse ? "#242426" : "#1c1c1e"
                    clip: true

                    MouseArea {
                        id: cardArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: { isle.copyClip(card.modelData); card.flashed = true; flash.restart(); }
                    }
                    // per kind: a thumbnail, a file icon and name, a host and URL, or the text itself
                    Image {
                        anchors.fill: parent
                        visible: card.modelData.kind === "image"
                        source: card.modelData.thumb ? "file://" + card.modelData.thumb : ""
                        fillMode: Image.PreserveAspectCrop
                    }
                    Column {
                        visible: card.modelData.kind !== "image"
                        anchors { fill: parent; topMargin: 28; leftMargin: 10; rightMargin: 10; bottomMargin: 8 }
                        spacing: 2
                        Kirigami.Icon {
                            visible: card.modelData.kind === "files"
                            width: 28; height: 28
                            source: "text-x-generic"
                        }
                        Text { renderType: Text.QtRendering;
                            width: parent.width
                            visible: card.modelData.kind === "link"
                            text: comp.host((card.modelData.preview || "").trim())
                            elide: Text.ElideRight
                            color: "white"
                            font { family: isle.font; pixelSize: 13; weight: Font.Bold }
                        }
                        Text { renderType: Text.QtRendering;
                            width: parent.width
                            height: parent.height - y
                            text: card.modelData.kind === "link" ? (card.modelData.preview || "").trim().replace(/^https?:\/\//i, "")
                                : card.modelData.kind === "files" ? (card.modelData.preview || "").split("\n")[0]
                                : (card.modelData.preview || "").replace(/\s+/g, " ").trim().slice(0, 160)
                            wrapMode: Text.WrapAnywhere
                            elide: Text.ElideRight
                            color: card.modelData.kind === "link" ? Qt.rgba(1, 1, 1, 0.55) : "white"
                            font { family: isle.font; pixelSize: 12; weight: card.modelData.kind === "files" ? Font.DemiBold : Font.Normal }
                        }
                    }
                    // pin and age in the top-left corner
                    Rectangle {
                        x: card.modelData.kind === "image" ? 5 : 0; y: card.modelData.kind === "image" ? 5 : 0
                        width: header.implicitWidth + (card.modelData.kind === "image" ? 14 : 18)
                        height: header.implicitHeight + (card.modelData.kind === "image" ? 6 : 14)
                        radius: height / 2
                        color: card.modelData.kind === "image" ? Qt.rgba(0, 0, 0, 0.6) : "transparent"
                        Row {
                            id: header
                            anchors.centerIn: parent
                            spacing: 5
                            IsleIcon { visible: card.modelData.pinned; name: "isle-pin-fill"; size: 11; anchors.verticalCenter: parent.verticalCenter }
                            Text { renderType: Text.QtRendering; text: comp.ago(card.modelData.at_ms); color: Qt.rgba(1, 1, 1, 0.5); font { family: isle.font; pixelSize: 12 } }
                        }
                    }
                    // on hover: pin and ×
                    Row {
                        anchors { right: parent.right; top: parent.top; margins: 5 }
                        spacing: 4
                        opacity: cardArea.containsMouse || pinBtn.hovered || delBtn.hovered ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: 120 } }
                        IsleButton { id: pinBtn; padding: 4; iconSize: 11; color: hovered ? "#4a4a4c" : "#3a3a3c"
                                     icon: card.modelData.pinned ? "isle-pin-fill" : "isle-pin"
                                     onClicked: isle.daemon.call("Clipboard1", "SetPinned", [card.modelData.id, !card.modelData.pinned], "tb") }
                        IsleButton { id: delBtn; padding: 4; iconSize: 11; color: hovered ? "#4a4a4c" : "#3a3a3c"
                                     icon: "isle-close-symbolic"
                                     onClicked: isle.daemon.call("Clipboard1", "Remove", [card.modelData.id], "t") }
                    }
                    // "Copied" over the card for a moment
                    Rectangle {
                        anchors.fill: parent
                        radius: 12
                        color: Qt.rgba(28 / 255, 28 / 255, 30 / 255, 0.95)
                        opacity: card.flashed ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: 160 } }
                        Column {
                            anchors.centerIn: parent
                            IsleIcon { anchors.horizontalCenter: parent.horizontalCenter; name: "isle-check-symbolic"; size: 18 }
                            Text { renderType: Text.QtRendering; anchors.horizontalCenter: parent.horizontalCenter; topPadding: 4; text: "Copied"; color: "white"
                                   font { family: isle.font; pixelSize: 12; weight: Font.Bold } }
                        }
                    }
                    Timer { id: flash; interval: 1100; onTriggered: card.flashed = false }
                }
            }

            // ---------------------------------------------------------------- Files
            DropArea {
                id: drop
                anchors.fill: parent
                enabled: comp.tab === "files"
                keys: ["text/uri-list"]
                onDropped: d => {
                    const uris = (d.urls || []).map(u => String(u)).filter(u => u.startsWith("file://"))
                        .slice(0, Math.max(0, comp.capacity - comp.files.length));
                    if (uris.length)
                        isle.daemon.call("Shelf1", "Add", [uris], "as");
                    d.acceptProposedAction();
                }
            }
            Rectangle {
                anchors.fill: parent
                visible: comp.tab === "files" && (comp.files.length === 0 || drop.containsDrag)
                radius: 16
                color: drop.containsDrag ? Qt.rgba(1, 1, 1, 0.05) : "transparent"
                border.width: 1.5
                border.color: Qt.rgba(1, 1, 1, drop.containsDrag ? 0.5 : 0.18)
                Column {
                    anchors.centerIn: parent
                    visible: comp.files.length === 0
                    spacing: 4
                    IsleIcon { anchors.horizontalCenter: parent.horizontalCenter; name: "isle-shelf"; size: 24; opacity: 0.35 }
                    Text { renderType: Text.QtRendering; anchors.horizontalCenter: parent.horizontalCenter; color: "white"
                           text: drop.containsDrag ? "Release to add it" : "Drop files here"
                           font { family: isle.font; pixelSize: 15; weight: Font.DemiBold; letterSpacing: -0.1 } }
                    Text { renderType: Text.QtRendering; anchors.horizontalCenter: parent.horizontalCenter; color: Qt.rgba(1, 1, 1, 0.5)
                           text: "Keep them here to drag into any app"
                           font { family: isle.font; pixelSize: 12 } }
                }
            }
            Row {
                anchors.verticalCenter: parent.verticalCenter
                visible: comp.tab === "files"
                spacing: 6
                Repeater {
                    model: comp.files
                    Rectangle {
                        id: tile
                        required property var modelData
                        readonly property string path: modelData.path || modelData.uri || ""
                        readonly property string url: path.startsWith("file://") ? path : "file://" + path
                        width: 84
                        height: 6 + 58 + 4 + 34 + 6
                        radius: 14
                        color: tileArea.containsMouse ? "#1c1c1e" : "transparent"
                        Column {
                            anchors { top: parent.top; topMargin: 6; horizontalCenter: parent.horizontalCenter }
                            spacing: 4
                            Item {
                                width: 58; height: 58
                                anchors.horizontalCenter: parent.horizontalCenter
                                Kirigami.Icon { anchors.centerIn: parent; width: 46; height: 46; source: tile.modelData.icon || "text-x-generic" }
                                Image {
                                    anchors.centerIn: parent
                                    width: 52; height: 52
                                    visible: status === Image.Ready
                                    source: /\.(png|jpe?g|gif|webp|bmp|svg)$/i.test(tile.url) ? tile.url : ""
                                    fillMode: Image.PreserveAspectCrop
                                }
                            }
                            Text { renderType: Text.QtRendering;
                                width: 76
                                height: 30
                                anchors.horizontalCenter: parent.horizontalCenter
                                horizontalAlignment: Text.AlignHCenter
                                text: tile.modelData.name || decodeURIComponent(tile.path.split("/").pop())
                                wrapMode: Text.WrapAnywhere
                                maximumLineCount: 2
                                elide: Text.ElideMiddle
                                color: "white"
                                font { family: isle.font; pixelSize: 12 }
                            }
                        }
                        MouseArea {
                            id: tileArea
                            anchors.fill: parent
                            hoverEnabled: true
                            drag.target: dragProxy
                            onClicked: isle.copyText(tile.url)
                        }
                        // drag it into any app
                        Item {
                            id: dragProxy
                            Drag.active: tileArea.drag.active
                            Drag.dragType: Drag.Automatic
                            Drag.supportedActions: Qt.CopyAction
                            Drag.mimeData: { "text/uri-list": tile.url }
                        }
                        // always there, so a file can always be taken off the shelf
                        IsleButton {
                            anchors { right: parent.right; top: parent.top; margins: 4 }
                            padding: 4; iconSize: 10; color: "#3a3a3c"
                            icon: "isle-close-symbolic"
                            onClicked: isle.daemon.call("Shelf1", "Remove", [tile.modelData.uri || tile.url], "s")
                        }
                    }
                }
            }
        }
    }
}
