# tams-shell

**A "frame" style Hyprland shell**: the screen gets a thin frame with rounded inner corners,
system info lives in the top frame, and every panel *grows out of the frame* instead of
floating over the screen. Solid colors, no glass, no gradients.

Built with [Quickshell](https://quickshell.org), written from scratch, MIT licensed.

🇮🇩 Bahasa Indonesia: [README.md](README.md) · 💖 Support development on **[Saweria](https://saweria.co/tamsrich)**

![Desktop](docs/desktop.jpg)

| Dashboard (click the clock / `Super + A`) | Launcher (`Super + Space`) |
|---|---|
| ![Dashboard](docs/dashboard.jpg) | ![Launcher](docs/launcher.jpg) |

## Features

- **Top frame**: logo, workspace numbers (click to switch), window title, clock, CPU, RAM, Wi-Fi, volume, battery.
- **Dashboard** from the top frame: big clock, media player (MPRIS), Wi-Fi / Bluetooth / Do-not-disturb /
  Night light toggles, volume & brightness sliders, notification list, lock / log out / reboot / power off.
- **Wi-Fi without a terminal**: click Wi-Fi in the top frame (or "WiFi" in the dashboard) to scan nearby
  networks, join a new one with its password, disconnect or forget. Needs NetworkManager (wpa_supplicant or iwd backend).
- **Launcher** from the left edge: search apps, `=` to calculate, `>` to run a command. Fully keyboard driven.
- **Notifications** slide out of the right edge (built-in notification server, no dunst/mako needed).
- **Volume & brightness OSD** on the right edge.
- Multi-monitor: one frame per screen, panels open on the focused screen.

## Install

Requires **Arch Linux** (or CachyOS, EndeavourOS, …) with **Hyprland**.

```bash
sudo pacman -S --needed git
git clone https://github.com/tammysuryana/tams-shell.git ~/tams-shell
cd ~/tams-shell
./install.sh        # --no-pkgs, --link (symlink for development), --uninstall
qs -c tams          # try it right away
```

The installer installs official-repo packages only, copies the shell to `~/.config/quickshell/tams`,
and (after asking, with a backup) hooks it into `hyprland.lua` or `hyprland.conf`.
Disable any other bar/shell you were running.

## Keys & IPC

`Super + Space` launcher · `Super + A` dashboard · `Super + I` / `Super + Esc` settings · `Esc` or click outside to close.

```bash
qs -c tams ipc call tams launcher | dashboard | wifi | settings | wallpaper | lock | close
```

Hyprland binds use `global, tams:launcher`, `global, tams:dashboard` and `global, tams:settings`.

## Settings

Open the **Settings** panel with `Super + I`, `Super + Esc` or the cog in the dashboard; every change applies instantly:
dark / light theme, colors picked by hand or **generated from the wallpaper** (frame, panels and window borders follow;
GTK/Chromium apps follow dark/light),
window gaps (inner/outer), border width, corner rounding, inactive window opacity, blur, animations,
accent color, side frame width, workspace count, terminal and wallpaper (click one from `~/Pictures`, or **Pilih file lain…** to pick any file).
Window settings are applied to the running Hyprland via `hyprctl` (and re-applied after a config reload);
your Hyprland config files are not modified.

Everything is stored in `~/.config/tams/settings.json` (live-reloaded, can be edited by hand):
`wallpaper`, `terminal`, `workspaces`, `mode` (`dark`/`light`), `colorSource` (`manual`/`wallpaper`), `accent`, `edge`, `gapsIn`, `gapsOut`, `border`, `rounding`,
`blur`, `animations`, `inactiveOpacity`. Other colors and fonts: `config/Theme.qml`.

## License

[MIT](LICENSE) © 2026 tams. Bundled Inter font under the SIL OFL 1.1.
