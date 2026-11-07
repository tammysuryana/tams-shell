import QtQuick
import qs.config

// Baris judul yang bisa dibuka: klik teks = buka/tutup daftar di bawahnya, sakelar di kanan = nyala/mati.
// switchable: false = tanpa sakelar, baris selalu bisa dibuka.
Item {
    id: root

    property string label: ""
    property bool switchable: true
    property bool checked: false
    property bool expanded: false
    signal toggled()
    signal expandClicked()

    implicitHeight: 42
    implicitWidth: 240

    Row {
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width - 56
        spacing: 6
        Txt {
            text: root.label
            elide: Text.ElideRight
            width: Math.min(implicitWidth, parent.width - 24)
        }
        Txt {
            visible: root.checked || !root.switchable
            mono: true; font.pixelSize: 16; color: Theme.muted
            text: Icons.chevronDown
            rotation: root.expanded ? 180 : 0
            Behavior on rotation { NumberAnimation { duration: 150 } }
        }
    }
    MouseArea {
        anchors { left: parent.left; top: parent.top; bottom: parent.bottom; right: root.switchable ? track.left : parent.right }
        cursorShape: Qt.PointingHandCursor
        enabled: root.checked || !root.switchable
        onClicked: root.expandClicked()
    }

    Rectangle {
        id: track
        visible: root.switchable
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: 40; height: 22; radius: 11
        color: root.checked ? Theme.accent : Theme.surface2
        Behavior on color { ColorAnimation { duration: 150 } }
        Rectangle {
            width: 16; height: 16; radius: 8
            y: 3
            x: root.checked ? 21 : 3
            color: root.checked ? Theme.frame : Theme.muted
            Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
        }
        MouseArea {
            anchors { fill: parent; margins: -8 }
            cursorShape: Qt.PointingHandCursor
            onClicked: root.toggled()
        }
    }
}
