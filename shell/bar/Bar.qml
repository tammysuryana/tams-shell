import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.config
import qs.services
import qs.widgets

// Isi bingkai atas: logo, workspace, judul jendela | jam | status.
Item {
    id: root

    property var monitor: null

    // Kiri
    Row {
        anchors.left: parent.left
        anchors.leftMargin: Theme.ui(18)
        anchors.verticalCenter: parent.verticalCenter
        spacing: Theme.ui(18)

        Rectangle {
            width: Theme.ui(26); height: Theme.ui(26); radius: Theme.ui(8)
            color: logoMouse.containsMouse ? Theme.surface2 : "transparent"
            Image { anchors.centerIn: parent; source: Qt.resolvedUrl("../assets/logo.svg"); width: Theme.ui(22); height: Theme.ui(22); sourceSize: Qt.size(44, 44) }
            MouseArea { id: logoMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Panels.toggleLauncher() }
        }

        Workspaces { monitor: root.monitor; count: Settings.workspaces; anchors.verticalCenter: parent.verticalCenter }

        Txt {
            anchors.verticalCenter: parent.verticalCenter
            readonly property var w: Hyprland.activeToplevel
            readonly property var ipc: w ? w.lastIpcObject : null
            text: w && w.title ? (ipc && ipc.class ? "<b>" + ipc.class + "</b>  <font color='" + Theme.muted + "'>" + w.title + "</font>" : w.title) : ""
            textFormat: Text.StyledText
            elide: Text.ElideRight
            width: Math.min(implicitWidth, root.width * 0.28)
        }
    }

    // Tengah: jam, klik = dashboard
    Rectangle {
        anchors.centerIn: parent
        width: clockRow.implicitWidth + Theme.ui(28)
        height: Theme.ui(32)
        radius: Theme.ui(10)
        color: clockMouse.containsMouse || (Panels.dashboard && Panels.screenName === (root.monitor ? root.monitor.name : "")) ? Theme.surface : "transparent"
        Behavior on color { ColorAnimation { duration: 150 } }
        Row {
            id: clockRow
            anchors.centerIn: parent
            spacing: 10
            Txt { mono: true; font.pixelSize: Theme.ui(16); font.weight: Font.Bold; text: Qt.formatTime(clock.date, "HH:mm") }
            Txt { color: Theme.muted; font.pixelSize: Theme.ui(Theme.fontSize); text: Qt.locale().toString(clock.date, "ddd d MMM") }
        }
        MouseArea { id: clockMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Panels.toggleDashboard() }
    }

    // Kanan
    Item {
        anchors.right: parent.right
        anchors.rightMargin: Theme.ui(20)
        anchors.verticalCenter: parent.verticalCenter
        width: status.implicitWidth
        height: status.implicitHeight
        Status { id: status }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: mouse => {
                const p = mapToItem(status.net, mouse.x, mouse.y)
                if (status.net.contains(p) && !Panels.dashboard) Panels.openWifi()
                else Panels.toggleDashboard()
            }
        }
    }

    SystemClock { id: clock; precision: SystemClock.Minutes }
}
