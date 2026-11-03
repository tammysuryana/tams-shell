import QtQuick
import qs.config

// Tombol sederhana: ikon dan/atau teks, latar muncul saat disorot.
Rectangle {
    id: root

    property string icon: ""
    property string label: ""
    property color fg: Theme.text
    property color bg: Theme.surface
    property bool active: false
    property int pad: 12
    signal clicked()

    implicitHeight: 36
    implicitWidth: row.implicitWidth + pad * 2
    radius: 12
    color: active ? Theme.accent : mouse.containsMouse ? Theme.surface2 : bg
    Behavior on color { ColorAnimation { duration: 120 } }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 8
        Txt { visible: root.icon !== ""; text: root.icon; mono: true; font.pixelSize: 18; color: root.active ? Theme.frame : root.fg }
        Txt { visible: root.label !== ""; text: root.label; color: root.active ? Theme.frame : root.fg }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
