import QtQuick
import qs.config

// Potongan sudut cekung: kotak seukuran `size` berwarna bingkai, dikurangi seperempat lingkaran.
// `corner` = sudut mana yang diisi: "tl" kiri-atas, "tr" kanan-atas, "bl" kiri-bawah, "br" kanan-bawah.
Canvas {
    id: root

    property string corner: "tl"
    property int size: Theme.radius
    property color color: Theme.frame

    width: size
    height: size
    onColorChanged: requestPaint()
    onCornerChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    onPaint: {
        const c = getContext("2d")
        const s = root.size
        c.reset()
        c.fillStyle = root.color
        c.beginPath()
        if (corner === "tl") { c.moveTo(0, 0); c.lineTo(s, 0); c.arc(s, s, s, -Math.PI / 2, Math.PI, true) }
        else if (corner === "tr") { c.moveTo(s, 0); c.lineTo(s, s); c.arc(0, s, s, 0, -Math.PI / 2, true) }
        else if (corner === "bl") { c.moveTo(0, s); c.lineTo(0, 0); c.arc(s, 0, s, Math.PI, Math.PI / 2, true) }
        else { c.moveTo(s, s); c.lineTo(0, s); c.arc(0, 0, s, Math.PI / 2, 0, true) }
        c.closePath()
        c.fill()
    }
}
