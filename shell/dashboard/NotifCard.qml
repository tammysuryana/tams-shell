import QtQuick
import qs.config
import qs.widgets

// Satu kartu notifikasi bergaris aksen di kiri, dengan gambar (mis. pratinjau screenshot) dan
// tombol aksi kalau ada. Klik kartu = aksi utama ("default") kalau ada, kalau tidak tutup.
Rectangle {
    id: root

    property var notif: null
    property bool showClose: false

    readonly property string img: {
        if (!notif) return ""
        if (notif.image) return notif.image
        const i = notif.appIcon || ""
        return i.startsWith("/") ? "file://" + i : i.startsWith("file://") ? i : ""
    }
    // notif.actions adalah list QML; salin ke array JS biasa dulu
    readonly property var acts: {
        const out = []
        const l = notif ? notif.actions : []
        for (let i = 0; i < l.length; i++) out.push(l[i])
        return out
    }
    readonly property var buttons: acts.filter(a => a.identifier !== "default")

    implicitHeight: content.implicitHeight + 22
    radius: 14
    color: Theme.surface

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (!root.notif) return
            const def = root.acts.find(a => a.identifier === "default")
            if (def) def.invoke()
            else root.notif.dismiss()
        }
    }

    Rectangle { width: 3; height: parent.height - 16; anchors.verticalCenter: parent.verticalCenter; x: 0; radius: 2; color: root.notif && root.notif.urgency === 2 ? Theme.bad : Theme.accent2 }

    Column {
        id: content
        anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; leftMargin: 14; rightMargin: 12 }
        spacing: 8

        Row {
            width: parent.width
            spacing: 10
            Rectangle {
                id: thumb
                visible: root.img !== "" && pic.status !== Image.Error
                width: 72; height: 48; radius: 8
                color: Theme.surface2
                clip: true
                Image {
                    id: pic
                    anchors.fill: parent
                    source: root.img
                    fillMode: Image.PreserveAspectCrop
                    sourceSize { width: 144; height: 96 }
                    asynchronous: true
                }
            }
            Column {
                width: parent.width - (thumb.visible ? thumb.width + parent.spacing : 0)
                anchors.verticalCenter: parent.verticalCenter
                spacing: 3
                Txt { width: parent.width; elide: Text.ElideRight; font.weight: Font.DemiBold; text: root.notif ? root.notif.summary : "" }
                Txt { width: parent.width; elide: Text.ElideRight; maximumLineCount: 2; wrapMode: Text.Wrap; color: Theme.muted; font.pixelSize: 13
                      text: root.notif ? (root.notif.appName ? root.notif.appName + " · " : "") + root.notif.body : ""; textFormat: Text.PlainText }
            }
        }

        Row {
            visible: root.buttons.length > 0
            spacing: 6
            Repeater {
                model: root.buttons
                SmallBtn { required property var modelData; label: modelData.text; onClicked: modelData.invoke() }
            }
        }
    }
}
