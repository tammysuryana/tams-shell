pragma Singleton

import QtQuick
import Quickshell

// Kalkulator kecil untuk launcher. Hanya angka & operator yang diizinkan (aman dari kode lain).
Singleton {
    function compute(expr) {
        const e = expr.replace(/,/g, ".").replace(/×/g, "*").replace(/:/g, "/").replace(/\^/g, "**").trim()
        if (e === "") return "…"
        if (!/^[0-9+\-*/%().\s*]+$/.test(e)) return "tidak bisa dihitung"
        try {
            const v = Function('"use strict"; return (' + e + ")")()
            if (typeof v !== "number" || !isFinite(v)) return "tidak bisa dihitung"
            return Number(v.toFixed(10)).toLocaleString(Qt.locale(), "f", v % 1 === 0 ? 0 : 4)
        } catch (err) {
            return "…"
        }
    }
}
