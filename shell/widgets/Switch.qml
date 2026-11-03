import QtQuick
import qs.config

// Baris pengaturan: teks di kiri, sakelar di kanan, garis putus-putus di bawah.
Item {
    id: root

    property string label: ""
    property string sub: ""
    property bool checked: false
    signal toggled()

    implicitHeight: 42
    implicitWidth: 240

    Txt { anchors.verticalCenter: parent.verticalCenter; text: root.label + (root.sub ? "  ·  " + root.sub : ""); elide: Text.ElideRight; width: parent.width - 56 }

    Rectangle {
        id: track
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
    }

    Row {
        anchors.bottom: parent.bottom
        width: parent.width
        spacing: 4
        Repeater {
            model: Math.floor(root.width / 8)
            Rectangle { width: 4; height: 1; color: Theme.line }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled()
    }
}
