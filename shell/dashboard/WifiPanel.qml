import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Networking
import qs.config
import qs.services
import qs.widgets

// WiFi di dashboard: sakelar + daftar jaringan hasil pindai.
// Klik jaringan untuk menyambung; jaringan baru yang berkunci minta kata sandi dulu.
ColumnLayout {
    id: root

    property bool active: false            // dashboard sedang terbuka
    property bool expanded: false
    property string prompt: ""             // NAMA jaringan yang sedang diminta kata sandinya (string, bukan objek:
                                           // objek jaringan bisa dibuat ulang NetworkManager saat memindai)
    property string pskDraft: ""           // ketikan kata sandi disimpan di panel, bukan di baris daftar
    property var trying: null              // jaringan yang terakhir dicoba disambung
    property string message: ""

    spacing: 0

    onActiveChanged: if (!active) { expanded = false; prompt = ""; pskDraft = ""; message = "" }

    Connections {
        target: Panels
        function onWifiListChanged() { if (Panels.wifiList) root.expanded = true }
    }

    // Pindai hanya selama daftar terlihat (NetworkManager memindai ulang tiap beberapa detik)
    Binding {
        when: Net.wifiDevice !== null
        target: Net.wifiDevice
        property: "scannerEnabled"
        value: root.active && root.expanded && Net.wifiOn && root.prompt === ""   // jeda pindai saat mengetik sandi
    }

    // Daftar "hidup" ikut hasil pindai; daftar yang DITAMPILKAN dibekukan selama kolom sandi terbuka
    // supaya baris tidak dibuat ulang / berpindah di bawah kursor ketika sinyal berubah.
    readonly property var liveNetworks: {
        if (!Net.wifiDevice) return []
        const bucket = n => Math.round(n.signalStrength / 20)   // sinyal dibulatkan: urutan tidak goyang tiap pindai
        return Net.wifiDevice.networks.values
            .filter(n => n.name !== "")
            .sort((a, b) => (b.connected - a.connected) || (b.known - a.known) || (bucket(b) - bucket(a)) || a.name.localeCompare(b.name))
    }
    property var networks: []
    onLiveNetworksChanged: if (prompt === "") networks = liveNetworks
    onPromptChanged: if (prompt === "") networks = liveNetworks
    Component.onCompleted: networks = liveNetworks

    function isOpen(n) { return n.security === WifiSecurityType.Open || n.security === WifiSecurityType.Owe }
    function isPsk(n) {
        return n.security === WifiSecurityType.WpaPsk || n.security === WifiSecurityType.Wpa2Psk
            || n.security === WifiSecurityType.Sae
    }

    function choose(n) {
        root.message = ""
        if (n.connected || n.stateChanging) return
        if (n.known || isOpen(n)) {
            root.prompt = ""
            root.trying = n
            n.connect()
        } else if (isPsk(n)) {
            root.pskDraft = ""
            root.prompt = (root.prompt === n.name) ? "" : n.name
        } else {
            // WPA-Enterprise dll. butuh identitas/sertifikat: serahkan ke nmtui
            root.message = "Jaringan enterprise: atur lewat terminal (nmtui)"
            Quickshell.execDetached(["sh", "-c", Settings.terminal + " -e nmtui-connect '" + n.name.replace(/'/g, "'\\''") + "'"])
        }
    }

    function submit(n, psk) {
        if (psk.length < 8) { root.message = "Kata sandi minimal 8 karakter"; return }
        root.message = ""
        root.trying = n
        root.prompt = ""
        root.pskDraft = ""
        n.connectWithPsk(psk)
    }

    Connections {
        target: root.trying
        ignoreUnknownSignals: true
        function onConnectionFailed(reason) {
            const n = root.trying
            if (reason === ConnectionFailReason.NoSecrets && root.isPsk(n)) {
                root.message = "Kata sandi salah untuk " + n.name
                root.prompt = n.name
            } else {
                root.message = "Gagal menyambung ke " + n.name + " (" + ConnectionFailReason.toString(reason) + ")"
            }
        }
        function onConnectedChanged() {
            if (root.trying && root.trying.connected) { root.message = ""; root.trying = null }
        }
    }

    ExpandSwitch {
        Layout.fillWidth: true
        label: "WiFi" + (Net.wifiNetwork ? "  ·  " + Net.wifiNetwork.name : "")
        checked: Net.wifiOn
        expanded: root.expanded
        onToggled: Net.toggleWifi()
        onExpandClicked: { root.expanded = !root.expanded; root.prompt = ""; root.message = "" }
    }

    // Daftar jaringan
    Rectangle {
        Layout.fillWidth: true
        Layout.topMargin: 6
        Layout.bottomMargin: 6
        visible: root.expanded && Net.wifiOn
        implicitHeight: col.implicitHeight + 12
        radius: 16
        color: Theme.surface

        ColumnLayout {
            id: col
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 6 }
            spacing: 2

            Txt {
                visible: root.networks.length === 0
                Layout.margins: 10
                text: "Memindai…"
                color: Theme.muted
            }

            ListView {
                id: list
                Layout.fillWidth: true
                implicitHeight: Math.min(contentHeight, 5 * 44)
                clip: true
                spacing: 2
                boundsBehavior: Flickable.StopAtBounds
                // ScriptModel: delegat dipertahankan (diff), bukan dibuat ulang tiap daftar berubah
                model: ScriptModel { values: root.networks }
                delegate: NetRow {}
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
        }
    }

    component NetRow: Column {
        id: row
        required property var modelData
        readonly property var n: modelData
        readonly property bool asking: root.prompt === n.name
        width: ListView.view.width

        onAskingChanged: if (asking) { pw.text = root.pskDraft; pw.forceActiveFocus() }

        Rectangle {
            width: parent.width
            height: 42
            radius: 12
            color: mouse.containsMouse || row.asking ? Theme.surface2 : "transparent"

            Txt {
                id: icon
                anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
                mono: true; font.pixelSize: 18
                color: row.n.connected ? Theme.accent : Theme.text
                text: Icons.wifiStrength(row.n.signalStrength, !root.isOpen(row.n))
            }
            Column {
                anchors { left: icon.right; leftMargin: 10; right: actions.visible ? actions.left : parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter }
                Txt { width: parent.width; text: row.n.name; elide: Text.ElideRight; color: row.n.connected ? Theme.accent : Theme.text }
                Txt {
                    width: parent.width
                    visible: text !== ""
                    font.pixelSize: 11
                    color: Theme.muted
                    text: row.n.connected ? "Tersambung"
                        : row.n.stateChanging ? "Menyambung…"
                        : row.n.known ? "Tersimpan" : ""
                }
            }

            MouseArea {
                id: mouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.choose(row.n)
            }

            // Putus / Lupakan muncul saat disorot (di atas MouseArea baris)
            Row {
                id: actions
                anchors { right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter }
                spacing: 4
                visible: mouse.containsMouse || hoverA.containsMouse || hoverB.containsMouse
                SmallBtn { id: hoverA; visible: row.n.connected; label: "Putus"; onClicked: row.n.disconnect() }
                SmallBtn { id: hoverB; visible: row.n.known; label: "Lupakan"; onClicked: row.n.forget() }
            }
        }

        // Kolom kata sandi untuk jaringan baru
        Item {
            width: parent.width
            height: row.asking ? 46 : 0
            visible: row.asking
            Rectangle {
                anchors { fill: parent; topMargin: 4; leftMargin: 6; rightMargin: 6 }
                radius: 12
                color: Theme.frame
                border.color: pw.activeFocus ? Theme.accent : Theme.line
                TextInput {
                    id: pw
                    anchors { left: parent.left; leftMargin: 12; right: eye.left; rightMargin: 8; verticalCenter: parent.verticalCenter }
                    color: Theme.text
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize
                    echoMode: eye.shown ? TextInput.Normal : TextInput.Password
                    selectionColor: Theme.accent
                    clip: true
                    Keys.onReturnPressed: root.submit(row.n, text)
                    Keys.onEnterPressed: root.submit(row.n, text)
                    Keys.onEscapePressed: root.prompt = ""
                    onTextChanged: if (row.asking) root.pskDraft = text
                    Component.onCompleted: if (row.asking) { text = root.pskDraft; forceActiveFocus() }
                    Txt { visible: pw.text === ""; text: "Kata sandi, lalu Enter"; color: Theme.muted }
                }
                Txt {
                    id: eye
                    property bool shown: false
                    anchors { right: go.left; rightMargin: 10; verticalCenter: parent.verticalCenter }
                    mono: true; font.pixelSize: 16; color: Theme.muted
                    text: shown ? Icons.eyeOff : Icons.eye
                    MouseArea { anchors { fill: parent; margins: -6 } cursorShape: Qt.PointingHandCursor; onClicked: eye.shown = !eye.shown }
                }
                SmallBtn {
                    id: go
                    anchors { right: parent.right; rightMargin: 6; verticalCenter: parent.verticalCenter }
                    label: "Sambung"
                    onClicked: root.submit(row.n, pw.text)
                }
            }
        }
    }
}
