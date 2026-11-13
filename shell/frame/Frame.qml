import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.config
import qs.services
import qs.widgets
import qs.bar
import qs.dashboard
import qs.launcher
import qs.settings
import qs.notifications
import qs.osd
import qs.keys

// Bingkai satu layar:
//  - bingkai atas (berisi bar) + kiri/kanan/bawah tipis, masing-masing memesan ruang (exclusive zone)
//  - lapisan atas tembus-klik: sudut cekung + semua panel yang "tumbuh" dari bingkai
Scope {
    id: root

    required property ShellScreen screen
    readonly property var monitor: Hyprland.monitorFor(screen)
    readonly property bool here: screen !== null && (Panels.screenName === "" || Panels.screenName === screen.name)

    // Wallpaper
    PanelWindow {
        screen: root.screen
        WlrLayershell.layer: WlrLayer.Background
        WlrLayershell.namespace: "tams-wallpaper"
        exclusionMode: ExclusionMode.Ignore
        anchors { top: true; bottom: true; left: true; right: true }
        color: Theme.frame
        Image {
            anchors.fill: parent
            source: Settings.wallpaper
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            sourceSize: root.screen ? Qt.size(root.screen.width, root.screen.height) : Qt.size(0, 0)
        }
    }

    // Bingkai atas + bar
    PanelWindow {
        id: top
        screen: root.screen
        WlrLayershell.namespace: "tams-bar"
        anchors { top: true; left: true; right: true }
        implicitHeight: Theme.barHeight
        exclusiveZone: Theme.barHeight
        color: Theme.frame
        Bar { anchors.fill: parent; monitor: root.monitor }
        // "Tetap menyala": tahan kunci / layar mati selama sakelarnya nyala
        IdleInhibitor { window: top; enabled: Idle.caffeine }
    }

    // Sisi kiri, kanan, bawah
    component Edge: PanelWindow {
        screen: root.screen
        WlrLayershell.namespace: "tams-frame"
        color: Theme.frame
        exclusiveZone: Theme.edge
        implicitWidth: Theme.edge
        implicitHeight: Theme.edge
    }
    Edge { anchors { left: true; top: true; bottom: true } }
    Edge { anchors { right: true; top: true; bottom: true } }
    Edge { anchors { bottom: true; left: true; right: true } }

    // Lapisan atas: sudut + panel. Hanya area panel yang menerima klik (mask).
    PanelWindow {
        id: overlay
        screen: root.screen
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "tams-overlay"
        readonly property bool panelOpen: launcher.open || dashboard.open || settings.open || keysPanel.open
        // Exclusive selama ada panel terbuka: keyboard tetap ke panel walau kursor bergeser ke jendela lain
        // (follow_mouse). Dulu OnDemand + HyprlandFocusGrab: kursor goyang -> fokus pindah -> grab lepas ->
        // dashboard tertutup, ketikan sandi WiFi / pilihan suara & Bluetooth hilang.
        WlrLayershell.keyboardFocus: panelOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        exclusionMode: ExclusionMode.Ignore
        anchors { top: true; bottom: true; left: true; right: true }
        color: "transparent"

        // Saat panel terbuka seluruh layar di bawah bar menerima klik (untuk "klik di luar = tutup");
        // bar tetap bisa diklik karena tidak termasuk area ini.
        mask: Region {
            Region { x: 0; y: Theme.barHeight; width: overlay.panelOpen ? overlay.width : 0; height: overlay.panelOpen ? overlay.height - Theme.barHeight : 0 }
            Region { item: dashboard }
            Region { item: launcher }
            Region { item: settings }
            Region { item: keysPanel }
            Region { item: popups }
        }

        // Klik di luar panel = tutup (menggantikan HyprlandFocusGrab)
        MouseArea {
            anchors.fill: parent
            anchors.topMargin: Theme.barHeight
            enabled: overlay.panelOpen
            acceptedButtons: Qt.AllButtons
            function inside(p, mx, my) { return p.visible && p.width > 0 && p.height > 0 && mx >= p.x && mx < p.x + p.width && my >= p.y && my < p.y + p.height }
            onPressed: mouse => {
                const mx = mouse.x, my = mouse.y + Theme.barHeight
                if (inside(dashboard, mx, my) || inside(launcher, mx, my) || inside(settings, mx, my) || inside(keysPanel, mx, my) || inside(popups, mx, my)) { mouse.accepted = false; return }
                Panels.closeAll()
            }
        }

        // Sudut cekung di ke-4 sudut dalam bingkai
        Corner { corner: "tl"; x: Theme.edge; y: Theme.barHeight }
        Corner { corner: "tr"; x: overlay.width - Theme.edge - size; y: Theme.barHeight }
        Corner { corner: "bl"; x: Theme.edge; y: overlay.height - Theme.edge - size }
        Corner { corner: "br"; x: overlay.width - Theme.edge - size; y: overlay.height - Theme.edge - size }

        Dashboard {
            id: dashboard
            open: Panels.dashboard && root.here
            anchors.horizontalCenter: parent.horizontalCenter
            y: Theme.barHeight
        }

        Launcher {
            id: launcher
            open: Panels.launcher && root.here
            x: Theme.edge
            y: Theme.barHeight
            height: overlay.height - Theme.barHeight - Theme.edge
        }

        SettingsPanel {
            id: settings
            open: Panels.settings && root.here
            here: root.here
            x: overlay.width - Theme.edge - width
            y: Theme.barHeight
            height: overlay.height - Theme.barHeight - Theme.edge
        }

        KeysPanel {
            id: keysPanel
            open: Panels.keys && root.here
            panelWidth: Math.min(1100, overlay.width - 2 * Theme.edge - 2 * Theme.panelRadius - 40)
            maxHeight: overlay.height - Theme.barHeight - Theme.edge - 24
            anchors.horizontalCenter: parent.horizontalCenter
            y: overlay.height - Theme.edge - height
        }

        Popups {
            id: popups
            visible: root.screen !== null && (root.screen.name === Panels.activeScreen() || Panels.activeScreen() === "")
            x: overlay.width - Theme.edge - width
            y: Theme.barHeight
        }

        Osd {
            x: overlay.width - Theme.edge - width
            anchors.verticalCenter: parent.verticalCenter
            visible: root.screen !== null && (root.screen.name === Panels.activeScreen() || Panels.activeScreen() === "")
        }
    }

}
