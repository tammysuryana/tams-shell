pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Notifications

// Server notifikasi: menyimpan daftar notifikasi & yang sedang tampil sebagai popup.
Singleton {
    id: root

    property bool dnd: false
    readonly property var list: server.trackedNotifications.values
    property var popups: []

    function dismissAll() {
        const l = root.list.slice()
        for (let i = 0; i < l.length; i++) l[i].dismiss()
    }
    function removePopup(n) {
        root.popups = root.popups.filter(p => p !== n)
    }

    NotificationServer {
        id: server
        keepOnReload: true
        bodySupported: true
        actionsSupported: true
        imageSupported: true
        persistenceSupported: true

        onNotification: n => {
            n.tracked = true
            if (!root.dnd || n.urgency === NotificationUrgency.Critical) {
                root.popups = [n].concat(root.popups).slice(0, 4)
                n.closed.connect(() => root.removePopup(n))
            }
        }
    }
}
