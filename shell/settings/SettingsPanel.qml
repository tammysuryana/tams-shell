import QtQuick
import QtQuick.Layouts
import QtQuick.Dialogs
import Quickshell
import Quickshell.Io
import qs.config
import qs.services
import qs.widgets

// Panel Pengaturan yang keluar dari sisi kanan bingkai (Super + I, atau ikon roda di dashboard).
// Semua perubahan langsung dipakai dan disimpan ke ~/.config/tams/settings.json.
Item {
    id: root

    property bool open: false
    property bool here: false      // layar ini yang sedang aktif
    readonly property int panelWidth: 440
    readonly property int r: Theme.panelRadius

    width: open ? panelWidth + r : 0
    visible: width > 0
    clip: true
    Behavior on width { NumberAnimation { duration: Theme.anim; easing.type: Easing.OutCubic } }

    onOpenChanged: if (open) { term.text = Settings.terminal; shotDir.text = Settings.screenshotDir; walls.running = true; Displays.refresh() }

    readonly property var accents: ["#e0af68", "#ff9e64", "#f7768e", "#bb9af7", "#7aa2f7", "#7dcfff", "#73daca", "#9ece6a", "#c0caf5"]

    // Telinga cekung kiri-atas & kiri-bawah
    Corner { corner: "tr"; x: 0; y: 0; size: root.r }
    Corner { corner: "br"; x: 0; y: root.height - root.r; size: root.r }

    Rectangle {
        id: body
        x: root.r
        width: root.panelWidth
        height: parent.height
        color: Theme.frame

        Keys.onEscapePressed: Panels.closeAll()

        RowLayout {
            id: header
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 28; bottomMargin: 0 }
            Txt { text: "Pengaturan"; font.pixelSize: 22; font.weight: Font.Bold; Layout.fillWidth: true }
            Btn { icon: Icons.close; pad: 8; onClicked: Panels.closeAll() }
        }

        Flickable {
            anchors { left: parent.left; right: parent.right; top: header.bottom; bottom: parent.bottom; margins: 28; topMargin: 12 }
            contentHeight: col.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            ColumnLayout {
                id: col
                width: parent.width
                spacing: 4

                RowLayout {
                    Layout.fillWidth: true
                    Heading { text: "Tema"; Layout.fillWidth: true }
                    // Gelap / terang: dua ikon ringkas
                    Btn { icon: Icons.moon; pad: 8; active: Settings.mode === "dark"; onClicked: Settings.set("mode", "dark") }
                    Btn { icon: Icons.sun; pad: 8; active: Settings.mode === "light"; onClicked: Settings.set("mode", "light") }
                }
                Txt { text: "Sumber warna"; color: Theme.muted; font.pixelSize: 13; Layout.topMargin: 6 }
                Segmented {
                    options: [{ v: "manual", t: "Pilih sendiri" }, { v: "wallpaper", t: "Dari wallpaper" }]
                    current: Settings.colorSource
                    onPicked: v => Settings.set("colorSource", v)
                }
                // Warna aksen pilihan sendiri
                Flow {
                    visible: Settings.colorSource !== "wallpaper"
                    Layout.fillWidth: true
                    Layout.topMargin: 10
                    Layout.bottomMargin: 6
                    spacing: 8
                    Repeater {
                        model: root.accents
                        Rectangle {
                            required property string modelData
                            readonly property bool on: Qt.colorEqual(Settings.accent, modelData)
                            width: 30; height: 30; radius: 15
                            color: modelData
                            border.width: on ? 3 : 0
                            border.color: Theme.text
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Settings.set("accent", parent.modelData) }
                        }
                    }
                }
                // Contoh palet yang dibuat dari wallpaper
                RowLayout {
                    visible: Settings.colorSource === "wallpaper"
                    Layout.fillWidth: true
                    Layout.topMargin: 10
                    Layout.bottomMargin: 6
                    spacing: 8
                    Repeater {
                        model: [Theme.accent, Theme.accent2, Theme.surface2, Theme.text]
                        Rectangle {
                            required property color modelData
                            width: 30; height: 30; radius: 15
                            color: modelData
                            border.width: 1
                            border.color: Theme.line
                        }
                    }
                    Txt {
                        Layout.fillWidth: true
                        Layout.leftMargin: 4
                        wrapMode: Text.Wrap
                        font.pixelSize: 12
                        color: Theme.muted
                        text: !WallColors.ready ? "Membaca warna wallpaper…"
                            : WallColors.seed === null ? "Wallpaper hampir tanpa warna, dipakai warna aksen pilihan"
                            : "Diambil dari wallpaper, ikut berubah saat wallpaper diganti"
                    }
                }

                Heading { text: "Jendela"; Layout.topMargin: 18 }
                Range { label: "Jarak antar jendela"; key: "gapsIn"; min: 0; max: 20 }
                Range { label: "Jarak ke bingkai"; key: "gapsOut"; min: 0; max: 40 }
                Range { label: "Tebal garis tepi"; key: "border"; min: 0; max: 6 }
                Range { label: "Lengkung sudut"; key: "rounding"; min: 0; max: 24 }
                Range { label: "Jendela tidak aktif"; key: "inactiveOpacity"; min: 0.5; max: 1; step: 0.05; percent: true }
                Switch { Layout.fillWidth: true; label: "Blur"; checked: Settings.blur; onToggled: Settings.set("blur", !Settings.blur) }
                Switch { Layout.fillWidth: true; label: "Animasi"; checked: Settings.animations; onToggled: Settings.set("animations", !Settings.animations) }

                Heading { text: "Bingkai"; Layout.topMargin: 18 }
                Range { label: "Tebal bingkai samping"; key: "edge"; min: 0; max: 24 }
                Range { label: "Jumlah workspace"; key: "workspaces"; min: 1; max: 10 }
                Txt { text: "Gaya nomor workspace"; font.pixelSize: 13; Layout.topMargin: 6 }
                Segmented {
                    Layout.topMargin: 4
                    options: [{ v: "number", t: "1 2 3" }, { v: "dot", t: "• • •" }, { v: "roman", t: "I II III" }, { v: "kanji", t: "一 二 三" }]
                    current: Settings.workspaceStyle
                    onPicked: v => Settings.set("workspaceStyle", v)
                }

                Heading { text: "Saat ditinggal"; Layout.topMargin: 18 }
                Txt {
                    Layout.fillWidth: true
                    wrapMode: Text.Wrap
                    font.pixelSize: 12
                    color: Theme.muted
                    text: "Dihitung dari sentuhan terakhir. Video yang sedang diputar dan sakelar \"Tetap menyala\" di dashboard menundanya."
                }
                IdleChoice { label: "Redupkan layar"; key: "idleDim"; visible: Brightness.available; options: [0, 60, 120, 300] }
                IdleChoice { label: "Kunci layar"; key: "idleLock"; options: [0, 180, 300, 600, 900] }
                IdleChoice { label: "Matikan layar"; key: "idleScreenOff"; options: [0, 300, 600, 900, 1800] }
                IdleChoice { label: "Tidur (suspend)"; key: "idleSuspend"; options: [0, 900, 1800, 3600] }
                Switch { Layout.fillWidth: true; Layout.topMargin: 6; label: "Kunci saat laptop tidur / ditutup"; checked: Settings.lockOnSleep; onToggled: Settings.set("lockOnSleep", !Settings.lockOnSleep) }

                Heading { text: "Layar"; Layout.topMargin: 18 }
                Repeater {
                    model: Displays.monitors
                    DisplayCard { required property var modelData; m: modelData; Layout.fillWidth: true; Layout.bottomMargin: 6 }
                }

                Heading { text: "Aplikasi"; Layout.topMargin: 18 }
                Txt { text: "Terminal (dipakai launcher & WiFi enterprise)"; color: Theme.muted; font.pixelSize: 13 }
                Rectangle {
                    Layout.fillWidth: true
                    Layout.topMargin: 6
                    implicitHeight: 38
                    radius: 12
                    color: Theme.surface
                    border.color: term.activeFocus ? Theme.accent : Theme.line
                    TextInput {
                        id: term
                        anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
                        verticalAlignment: TextInput.AlignVCenter
                        color: Theme.text
                        font.family: Theme.mono
                        font.pixelSize: 13
                        selectionColor: Theme.accent
                        clip: true
                        onEditingFinished: if (text.trim() !== "") Settings.set("terminal", text.trim())
                        Keys.onEscapePressed: Panels.closeAll()
                    }
                }
                Txt { text: "Folder screenshot"; color: Theme.muted; font.pixelSize: 13; Layout.topMargin: 10 }
                Rectangle {
                    Layout.fillWidth: true
                    Layout.topMargin: 6
                    implicitHeight: 38
                    radius: 12
                    color: Theme.surface
                    border.color: shotDir.activeFocus ? Theme.accent : Theme.line
                    TextInput {
                        id: shotDir
                        anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
                        verticalAlignment: TextInput.AlignVCenter
                        color: Theme.text
                        font.family: Theme.mono
                        font.pixelSize: 13
                        selectionColor: Theme.accent
                        clip: true
                        // kosong = folder bawaan
                        onEditingFinished: Settings.setScreenshotDir(text.trim().replace(/^~(?=\/|$)/, Quickshell.env("HOME")))
                        Keys.onEscapePressed: Panels.closeAll()
                        Txt {
                            visible: shotDir.text === ""
                            anchors.verticalCenter: parent.verticalCenter
                            text: Screenshot.dir
                            color: Theme.muted
                            font.family: Theme.mono
                            font.pixelSize: 13
                        }
                    }
                }

                Heading { text: "Wallpaper"; Layout.topMargin: 18 }
                Txt {
                    Layout.fillWidth: true
                    text: "Klik gambar untuk memasang. Daftar diambil dari ~/Pictures dan ~/Pictures/Wallpapers"
                    color: Theme.muted; font.pixelSize: 13; wrapMode: Text.Wrap
                }
                GridLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: 6
                    columns: 3
                    columnSpacing: 8
                    rowSpacing: 8
                    Repeater {
                        model: [""].concat(walls.files)
                        Rectangle {
                            required property string modelData
                            readonly property bool on: Settings.wallpaperPath === modelData
                            Layout.fillWidth: true
                            implicitHeight: 70
                            radius: 10
                            color: Theme.surface2
                            clip: true
                            Image {
                                anchors { fill: parent; margins: 3 }
                                source: parent.modelData === "" ? Settings.defaultWallpaper : "file://" + parent.modelData
                                sourceSize { width: 200; height: 120 }
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                cache: true
                            }
                            Rectangle {
                                anchors.fill: parent
                                radius: parent.radius
                                color: "transparent"
                                border.width: parent.on ? 3 : 0
                                border.color: Theme.accent
                            }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Settings.setWallpaper(parent.modelData) }
                        }
                    }
                }

                Btn {
                    Layout.topMargin: 8
                    label: "Pilih file lain…"
                    onClicked: Panels.openWallpaperPicker()
                }

                Btn {
                    Layout.topMargin: 22
                    Layout.bottomMargin: 8
                    label: "Kembalikan tampilan bawaan"
                    onClicked: Settings.resetLook()
                }
            }
        }
    }

    // Pemilih file wallpaper dari folder mana saja
    Connections {
        target: Panels
        function onPickWallpaper() { if (root.here) picker.open() }
    }
    FileDialog {
        id: picker
        title: "Pilih wallpaper"
        nameFilters: ["Gambar (*.jpg *.jpeg *.png *.webp)"]
        currentFolder: "file://" + Quickshell.env("HOME") + "/Pictures"
        onAccepted: Settings.setWallpaper(decodeURIComponent(selectedFile.toString().replace(/^file:\/\//, "")))
    }

    // Daftar gambar wallpaper (dibaca ulang tiap panel dibuka)
    Process {
        id: walls
        property var files: []
        command: ["sh", "-c", "find \"$HOME/Pictures\" -maxdepth 2 -type f \\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \\) 2>/dev/null | sort | head -n 30"]
        stdout: StdioCollector { onStreamFinished: walls.files = text.split("\n").filter(l => l !== "") }
    }

    // Pilihan berdampingan (segmented): options = [{ v: nilai, t: teks }]
    component Segmented: RowLayout {
        id: ch
        property var options: []
        property string current: ""
        signal picked(string v)
        Layout.fillWidth: true
        spacing: 6
        Repeater {
            model: ch.options
            Btn {
                Layout.fillWidth: true
                label: modelData.t
                active: ch.current === modelData.v
                onClicked: ch.picked(modelData.v)
            }
        }
    }

    // Pilihan waktu (detik) untuk satu langkah saat ditinggal: Mati / 3 mnt / 5 mnt ...
    component IdleChoice: ColumnLayout {
        id: ic
        property string label
        property string key
        property var options: []
        Layout.fillWidth: true
        Layout.topMargin: 6
        spacing: 4
        Txt { text: ic.label; font.pixelSize: 13 }
        Segmented {
            options: ic.options.map(s => ({ v: String(s), t: s === 0 ? "Mati" : (s >= 3600 ? s / 3600 + " jam" : s / 60 + " mnt") }))
            current: String(Settings[ic.key])
            onPicked: v => Settings.set(ic.key, Number(v))
        }
    }

    component Heading: Txt {
        font.pixelSize: 11
        font.letterSpacing: 2
        font.capitalization: Font.AllUppercase
        color: Theme.muted
        Layout.bottomMargin: 4
    }

    // Satu baris pengaturan angka: label di atas, slider di bawah
    component Range: ColumnLayout {
        id: rg
        property string label
        property string key
        property real min: 0
        property real max: 1
        property real step: 1
        property bool percent: false
        readonly property real cur: Settings[key]
        Layout.fillWidth: true
        spacing: 0
        Txt { text: rg.label; font.pixelSize: 13 }
        Slider {
            Layout.fillWidth: true
            fill: Theme.accent
            value: (rg.cur - rg.min) / (rg.max - rg.min)
            display: rg.percent ? Math.round(rg.cur * 100) + "%" : rg.cur
            onMoved: v => {
                const raw = rg.min + v * (rg.max - rg.min)
                const val = Math.round(raw / rg.step) * rg.step
                Settings.set(rg.key, rg.step < 1 ? Number(val.toFixed(2)) : Math.round(val))
            }
        }
    }
}
