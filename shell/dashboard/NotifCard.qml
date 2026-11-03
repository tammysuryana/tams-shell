import QtQuick
import qs.config
import qs.widgets

// Satu kartu notifikasi bergaris aksen di kiri. Klik = tutup.
Rectangle {
    id: root

    property var notif: null
    property bool showClose: false

    implicitHeight: col.implicitHeight + 22
    radius: 14
    color: Theme.surface

    Rectangle { width: 3; height: parent.height - 16; anchors.verticalCenter: parent.verticalCenter; x: 0; radius: 2; color: root.notif && root.notif.urgency === 2 ? Theme.bad : Theme.accent2 }

    Column {
        id: col
        anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; leftMargin: 14; rightMargin: 12 }
        spacing: 3
        Txt { width: parent.width; elide: Text.ElideRight; font.weight: Font.DemiBold; text: root.notif ? root.notif.summary : "" }
        Txt { width: parent.width; elide: Text.ElideRight; maximumLineCount: 2; wrapMode: Text.Wrap; color: Theme.muted; font.pixelSize: 13
              text: root.notif ? (root.notif.appName ? root.notif.appName + " · " : "") + root.notif.body : ""; textFormat: Text.PlainText }
    }

    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: if (root.notif) root.notif.dismiss() }
}
