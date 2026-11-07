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

// Bingkai satu layar:
//  - bingkai atas (berisi bar) + kiri/kanan/bawah tipis, masing-masing memesan ruang (exclusive zone)
//  - lapisan atas tembus-klik: sudut cekung + semua panel yang "tumbuh" dari bingkai
Scope {
    id: root

    required property ShellScreen screen
    readonly property var monitor: Hyprland.monitorFor(screen)
    readonly property bool here: Panels.screenName === "" || Panels.screenName === screen.name

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
            sourceSize: Qt.size(root.screen.width, root.screen.height)
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
        // OnDemand, bukan Exclusive: di Hyprland fokus Exclusive langsung membatalkan HyprlandFocusGrab
        // di bawah -> launcher tertutup lagi begitu dibuka. Fokus keyboard tetap didapat lewat grab.
        // Dashboard juga butuh keyboard (kolom kata sandi WiFi).
        WlrLayershell.keyboardFocus: launcher.open || dashboard.open || settings.open ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
        exclusionMode: ExclusionMode.Ignore
        anchors { top: true; bottom: true; left: true; right: true }
        color: "transparent"

        mask: Region {
            Region { item: dashboard }
            Region { item: launcher }
            Region { item: settings }
            Region { item: popups }
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
            x: overlay.width - Theme.edge - width
            y: Theme.barHeight
            height: overlay.height - Theme.barHeight - Theme.edge
        }

        Popups {
            id: popups
            visible: root.screen.name === Panels.activeScreen() || Panels.activeScreen() === ""
            x: overlay.width - Theme.edge - width
            y: Theme.barHeight
        }

        Osd {
            x: overlay.width - Theme.edge - width
            anchors.verticalCenter: parent.verticalCenter
            visible: root.screen.name === Panels.activeScreen() || Panels.activeScreen() === ""
        }
    }

    // Klik di luar panel = tutup
    HyprlandFocusGrab {
        active: (Panels.dashboard || Panels.launcher || Panels.settings) && root.here
        windows: [overlay, top]
        onCleared: Panels.closeAll()
    }
}
