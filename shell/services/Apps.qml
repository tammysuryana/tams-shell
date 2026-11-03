pragma Singleton

import QtQuick
import Quickshell

// Daftar aplikasi terpasang + pencarian sederhana (awal nama > awal kata > mengandung).
Singleton {
    id: root

    readonly property var all: DesktopEntries.applications.values
        .filter(e => !e.noDisplay)
        .sort((a, b) => a.name.localeCompare(b.name))

    function score(e, q) {
        const n = e.name.toLowerCase()
        if (n.startsWith(q)) return 100 - n.length / 100
        if (n.split(/[\s\-_.]+/).some(w => w.startsWith(q))) return 80
        if (n.includes(q)) return 60
        const extra = [e.genericName, e.comment].concat(e.keywords || []).join(" ").toLowerCase()
        if (extra.includes(q)) return 30
        return 0
    }

    function search(q) {
        q = q.toLowerCase()
        if (q === "") return root.all
        return root.all
            .map(e => ({ e: e, s: root.score(e, q) }))
            .filter(x => x.s > 0)
            .sort((a, b) => b.s - a.s)
            .map(x => x.e)
    }
}
