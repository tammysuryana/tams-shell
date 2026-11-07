import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.widgets

// Keluaran suara di dashboard: baris judul + daftar speaker / headphone / HDMI / Bluetooth.
// Klik salah satu = jadikan keluaran bawaan dan pindahkan suara yang sedang main ke sana.
ColumnLayout {
    id: root

    property bool active: false            // dashboard sedang terbuka
    property bool expanded: false

    spacing: 0
    visible: Audio.outputs.length > 0

    onActiveChanged: if (!active) expanded = false
    onExpandedChanged: if (expanded) Audio.refresh()

    Connections {
        target: Panels
        function onAudioListChanged() { if (Panels.audioList) root.expanded = true }
    }

    ExpandSwitch {
        Layout.fillWidth: true
        switchable: false
        label: "Keluaran suara" + (Audio.current ? "  ·  " + Audio.current.label : "")
        expanded: root.expanded
        onExpandClicked: root.expanded = !root.expanded
    }

    Rectangle {
        Layout.fillWidth: true
        Layout.topMargin: 6
        Layout.bottomMargin: 6
        visible: root.expanded
        implicitHeight: col.implicitHeight + 12
        radius: 16
        color: Theme.surface

        ColumnLayout {
            id: col
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 6 }
            spacing: 2
            Repeater {
                model: Audio.outputs
                delegate: OutRow { Layout.fillWidth: true }
            }
        }
    }

    component OutRow: Rectangle {
        id: row
        required property var modelData
        readonly property var o: modelData
        readonly property bool busy: Audio.pending !== null && Audio.pending.card === o.card && Audio.pending.port === o.port
        height: 42
        radius: 12
        color: mouse.containsMouse ? Theme.surface2 : "transparent"
        opacity: o.plugged || o.active ? 1 : 0.55

        Txt {
            id: ic
            anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
            mono: true; font.pixelSize: 18
            color: row.o.active ? Theme.accent : Theme.text
            text: row.o.kind === "headphones" ? Icons.headphones : row.o.kind === "hdmi" ? Icons.monitor : Icons.speaker
        }
        Column {
            anchors { left: ic.right; leftMargin: 10; right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter }
            Txt { width: parent.width; text: row.o.label; elide: Text.ElideRight; color: row.o.active ? Theme.accent : Theme.text }
            Txt {
                width: parent.width; visible: text !== ""; elide: Text.ElideRight
                font.pixelSize: 11; color: Theme.muted
                text: row.busy ? "Memindahkan…" : row.o.active ? "Aktif" + (row.o.sub ? " · " + row.o.sub : "") : row.o.sub
            }
        }
        MouseArea {
            id: mouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: Audio.select(row.o)
        }
    }
}
