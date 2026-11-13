import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import qs.config
import qs.services
import qs.widgets

// Bluetooth di dashboard: sakelar + daftar perangkat. Selama daftar terbuka, adaptor mencari
// perangkat baru. Klik perangkat baru = pasangkan lalu sambungkan; perangkat tersimpan = sambungkan.
ColumnLayout {
    id: root

    property bool active: false            // dashboard sedang terbuka
    property bool expanded: false
    property string message: ""
    property var pairingDev: null          // perangkat yang sedang dipasangkan

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool on: adapter !== null && adapter.enabled

    spacing: 0
    visible: adapter !== null

    onActiveChanged: if (!active) { expanded = false; message = "" }

    Connections {
        target: Panels
        function onBtListChanged() { if (Panels.btList) root.expanded = true }
    }

    // Cari perangkat hanya selama daftar terlihat
    readonly property bool scanning: active && expanded && on
    onScanningChanged: {
        if (!adapter) return
        adapter.discovering = scanning
        adapter.pairable = scanning
    }

    readonly property var connectedDev: {
        if (!adapter) return null
        const d = adapter.devices.values
        for (let i = 0; i < d.length; i++) if (d[i].connected) return d[i]
        return null
    }

    function named(d) { return d.deviceName !== "" && d.name.replace(/[-:]/g, "") !== d.address.replace(/[-:]/g, "") }

    readonly property var devices: {
        if (!adapter) return []
        return adapter.devices.values
            .filter(d => d.paired || d.connected || named(d))
            .sort((a, b) => (b.connected - a.connected) || (b.paired - a.paired) || a.name.localeCompare(b.name))
    }

    function choose(d) {
        root.message = ""
        if (d.connected || d.pairing || d.state === BluetoothDeviceState.Connecting) return
        if (d.paired) d.connect()
        else { root.pairingDev = d; d.pair() }
    }

    // Selesai memasangkan: percayai (supaya tersambung otomatis lain kali) lalu sambungkan
    Connections {
        target: root.pairingDev
        ignoreUnknownSignals: true
        function onPairingChanged() {
            const d = root.pairingDev
            if (!d || d.pairing) return
            if (d.paired) {
                d.trusted = true
                d.connect()
            } else {
                root.message = "Gagal memasangkan " + d.name + ". Perangkat yang minta PIN: pasangkan lewat terminal."
            }
            root.pairingDev = null
        }
    }

    function icon(d) {
        const i = d.icon
        if (i.startsWith("audio-head")) return Icons.headphones
        if (i.startsWith("audio")) return Icons.speaker
        if (i === "input-mouse") return Icons.mouse
        if (i === "input-keyboard") return Icons.keyboard
        if (i === "input-gaming") return Icons.gamepad
        if (i.startsWith("phone")) return Icons.phone
        if (i === "computer") return Icons.laptop
        return Icons.bluetooth
    }

    function status(d) {
        if (d.pairing) return "Memasangkan…"
        if (d.state === BluetoothDeviceState.Connecting) return "Menyambung…"
        if (d.state === BluetoothDeviceState.Disconnecting) return "Memutus…"
        if (d.connected) return "Tersambung" + (d.batteryAvailable ? " · baterai " + Math.round(d.battery * 100) + "%" : "")
        if (d.paired) return "Tersimpan"
        return ""
    }

    ExpandSwitch {
        Layout.fillWidth: true
        label: "Bluetooth" + (root.connectedDev ? "  ·  " + root.connectedDev.name : "")
        checked: root.on
        expanded: root.expanded
        onToggled: if (root.adapter) root.adapter.enabled = !root.adapter.enabled
        onExpandClicked: { root.expanded = !root.expanded; root.message = "" }
    }

    // Daftar perangkat
    Rectangle {
        Layout.fillWidth: true
        Layout.topMargin: 6
        Layout.bottomMargin: 6
        visible: root.expanded && root.on
        implicitHeight: col.implicitHeight + 12
        radius: 16
        color: Theme.surface

        ColumnLayout {
            id: col
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 6 }
            spacing: 2

            Txt {
                Layout.preferredWidth: col.width - 20
                Layout.margins: 10
                wrapMode: Text.Wrap
                text: "Mencari perangkat… Perangkat baru harus dalam mode pairing."
                color: Theme.muted
                font.pixelSize: 12
                visible: root.adapter && root.adapter.discovering
            }

            ListView {
                Layout.fillWidth: true
                implicitHeight: Math.min(contentHeight, 5 * 44)
                clip: true
                spacing: 2
                boundsBehavior: Flickable.StopAtBounds
                model: ScriptModel { values: root.devices }   // delegat dipertahankan saat daftar berubah
                delegate: DevRow {}
            }

            Txt {
                visible: root.message !== ""
                Layout.preferredWidth: col.width - 16
                Layout.margins: 8
                text: root.message
                color: Theme.bad
                font.pixelSize: 12
                wrapMode: Text.Wrap
            }
            SmallBtn {
                visible: root.message !== ""
                Layout.margins: 8
                Layout.topMargin: 0
                label: "Buka bluetoothctl"
                onClicked: { Panels.closeAll(); Quickshell.execDetached(["sh", "-c", Settings.terminal + " -e bluetoothctl"]) }
            }
        }
    }

    component DevRow: Rectangle {
        id: row
        required property var modelData
        readonly property var d: modelData
        width: ListView.view.width
        height: 42
        radius: 12
        color: mouse.containsMouse ? Theme.surface2 : "transparent"

        Txt {
            id: ic
            anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
            mono: true; font.pixelSize: 18
            color: row.d.connected ? Theme.accent : Theme.text
            text: root.icon(row.d)
        }
        Column {
            anchors { left: ic.right; leftMargin: 10; right: actions.visible ? actions.left : parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter }
            Txt { width: parent.width; text: row.d.name; elide: Text.ElideRight; color: row.d.connected ? Theme.accent : Theme.text }
            Txt { width: parent.width; visible: text !== ""; font.pixelSize: 11; color: Theme.muted; text: root.status(row.d) }
        }

        MouseArea {
            id: mouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.choose(row.d)
        }

        Row {
            id: actions
            anchors { right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter }
            spacing: 4
            visible: row.d.pairing || mouse.containsMouse || a.containsMouse || b.containsMouse || c.containsMouse
            SmallBtn { id: c; visible: row.d.pairing; label: "Batal"; onClicked: row.d.cancelPair() }
            SmallBtn { id: a; visible: row.d.connected; label: "Putus"; onClicked: row.d.disconnect() }
            SmallBtn { id: b; visible: row.d.paired && !row.d.pairing; label: "Lupakan"; onClicked: row.d.forget() }
        }
    }
}
