import QtQuick
import qs.config
import qs.services
import qs.widgets
import qs.dashboard

// Popup notifikasi yang keluar dari sisi kanan bingkai, di bawah bingkai atas.
Item {
    id: root

    readonly property int r: Theme.panelRadius
    readonly property bool has: Notifs.popups.length > 0

    readonly property int bodyHeight: list.implicitHeight + 28
    width: has ? 380 + r : 0
    height: has ? bodyHeight + r : 0
    clip: true
    Behavior on width { NumberAnimation { duration: Theme.anim; easing.type: Easing.OutCubic } }
    Behavior on height { NumberAnimation { duration: Theme.anim; easing.type: Easing.OutCubic } }

    // telinga: kiri-atas (di bawah bingkai atas) & kanan-bawah (menempel bingkai kanan)
    Corner { corner: "tr"; size: root.r; x: 0; y: 0 }
    Corner { corner: "tr"; size: root.r; x: root.width - root.r; y: root.bodyHeight }

    Rectangle {
        x: root.r
        width: root.width - root.r
        height: root.bodyHeight
        color: Theme.frame
        radius: root.r
        Rectangle { width: parent.width; height: root.r; color: Theme.frame }
        Rectangle { anchors.right: parent.right; width: root.r; height: parent.height; color: Theme.frame }

        Column {
            id: list
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 14 }
            spacing: 10
            Repeater {
                model: Notifs.popups
                NotifCard {
                    required property var modelData
                    notif: modelData
                    width: list.width
                    Timer {
                        running: true
                        interval: parent.notif && parent.notif.expireTimeout > 0 ? parent.notif.expireTimeout : 6000
                        onTriggered: Notifs.removePopup(parent.notif)
                    }
                }
            }
        }
    }
}
