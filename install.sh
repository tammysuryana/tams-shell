#!/usr/bin/env bash
# tams-shell — installer.
#
#   git clone https://github.com/tammysuryana/tams-shell.git ~/tams-shell
#   cd ~/tams-shell && ./install.sh
#
# Opsi:
#   ./install.sh              pasang paket + shell + sambungkan ke Hyprland
#   ./install.sh --no-pkgs    tanpa memasang paket
#   ./install.sh --link       pasang shell sebagai symlink ke repo ini (untuk mengembangkan)
#   ./install.sh --uninstall  copot tams-shell
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CFG="${XDG_CONFIG_HOME:-$HOME/.config}"
DEST="$CFG/quickshell/tams"
HYPR="$CFG/hypr"

G='\033[0;32m'; Y='\033[1;33m'; R='\033[0;31m'; C='\033[0;36m'; B='\033[1m'; N='\033[0m'
ok()   { echo -e "${G}  ✓ $*${N}"; }
warn() { echo -e "${Y}  ! $*${N}"; }
die()  { echo -e "${R}✗ $*${N}"; exit 1; }
tanya() { local a; read -r -p "$(echo -e "${Y}$1 [Y/n]: ${N}")" a || a=""; [[ ! "$a" =~ ^[Nn]$ ]]; }

PKGS=1; LINK=0
for a in "$@"; do
  case "$a" in
    --no-pkgs) PKGS=0 ;;
    --link) LINK=1 ;;
    --uninstall)
      rm -rf "$DEST" && ok "shell dihapus dari $DEST"
      for f in "$HYPR/hyprland.lua" "$HYPR/hyprland.conf"; do
        [ -f "$f" ] && sed -i '/tams-shell/d' "$f"
      done
      rm -f "$HYPR/tams-shell.lua" "$HYPR/tams-shell.conf"
      ok "baris tams-shell di config Hyprland dihapus"
      echo "Selesai. Jalankan shell lamamu lagi, atau logout lalu login."
      exit 0 ;;
    -h|--help) sed -n '2,11p' "$0"; exit 0 ;;
    *) die "opsi tidak dikenal: $a" ;;
  esac
done

[ "$(id -u)" -eq 0 ] && die "Jangan jalankan dengan sudo. Jalankan sebagai user biasa: ./install.sh"
command -v pacman >/dev/null || die "Installer ini untuk Arch Linux dan turunannya."

echo -e "${C}${B}tams-shell — installer${N}"

# 1. Paket (semua dari repo resmi Arch)
if [ $PKGS -eq 1 ]; then
  echo -e "\n${B}1/3 Paket${N}"
  sudo pacman -S --needed --noconfirm \
    quickshell qt6-svg qt6-imageformats hyprland hyprsunset hyprlock \
    ttf-jetbrains-mono-nerd networkmanager brightnessctl bluez bluez-utils \
    pipewire wireplumber libnotify
  ok "paket terpasang"
fi

# 2. Shell
echo -e "\n${B}2/3 Shell${N}"
mkdir -p "$CFG/quickshell"
if [ -e "$DEST" ] || [ -L "$DEST" ]; then
  mv "$DEST" "$DEST.bak-$(date +%Y%m%d-%H%M%S)"
  warn "shell lama dipindah ke $DEST.bak-*"
fi
if [ $LINK -eq 1 ]; then
  ln -s "$REPO/shell" "$DEST" && ok "shell -> $DEST (symlink ke repo)"
else
  cp -r "$REPO/shell" "$DEST" && ok "shell -> $DEST"
fi
# Pengaturan bawaan (sama dengan services/Settings.qml); yang sudah ada tidak ditimpa
SET="$CFG/tams/settings.json"
if [ ! -f "$SET" ]; then
  mkdir -p "$CFG/tams"
  printf '{\n    "terminal": "kitty",\n    "wallpaper": "",\n    "workspaces": 5,\n    "mode": "dark",\n    "colorSource": "manual",\n    "accent": "#e0af68",\n    "edge": 10,\n    "gapsIn": 2,\n    "gapsOut": 2,\n    "border": 2,\n    "rounding": 12,\n    "blur": true,\n    "animations": true,\n    "inactiveOpacity": 1\n}\n' > "$SET"
  ok "pengaturan -> $SET"
fi

# 3. Sambungkan ke Hyprland (shortcut + jalan otomatis)
echo -e "\n${B}3/3 Hyprland${N}"
mkdir -p "$HYPR"
if [ -f "$HYPR/hyprland.lua" ]; then
  cp "$REPO/hypr/tams-shell.lua" "$HYPR/tams-shell.lua"
  if ! grep -q 'require("tams-shell")' "$HYPR/hyprland.lua"; then
    if tanya "Tambahkan tams-shell ke ~/.config/hypr/hyprland.lua?"; then
      cp "$HYPR/hyprland.lua" "$HYPR/hyprland.lua.bak-tams-shell"
      printf '\n-- tams-shell\nrequire("tams-shell")\n' >> "$HYPR/hyprland.lua"
      ok "hyprland.lua memuat tams-shell (cadangan: hyprland.lua.bak-tams-shell)"
    fi
  else
    ok "hyprland.lua sudah memuat tams-shell"
  fi
else
  cp "$REPO/hypr/tams-shell.conf" "$HYPR/tams-shell.conf"
  touch "$HYPR/hyprland.conf"
  if ! grep -q 'tams-shell.conf' "$HYPR/hyprland.conf"; then
    if tanya "Tambahkan tams-shell ke ~/.config/hypr/hyprland.conf?"; then
      cp "$HYPR/hyprland.conf" "$HYPR/hyprland.conf.bak-tams-shell"
      printf '\n# tams-shell\nsource = ~/.config/hypr/tams-shell.conf\n' >> "$HYPR/hyprland.conf"
      ok "hyprland.conf memuat tams-shell (cadangan: hyprland.conf.bak-tams-shell)"
    fi
  else
    ok "hyprland.conf sudah memuat tams-shell"
  fi
fi

# Shell/bar lain yang ikut jalan akan tumpang tindih
for other in waybar ags eww noctalia-shell; do
  pgrep -x "$other" >/dev/null && warn "$other sedang jalan — matikan dari config Hyprland supaya tidak tumpang tindih dengan tams-shell"
done
if pgrep -x qs >/dev/null || pgrep -x quickshell >/dev/null; then
  warn "ada shell quickshell lain yang jalan — hapus 'qs -c ...' lamanya dari config Hyprland"
fi

echo -e "\n${G}${B}Selesai!${N}"
echo "  Coba sekarang tanpa logout:   qs -c tams"
echo "  Launcher: Super + Space · Dashboard: Super + A atau klik jam"
echo "  Pengaturan: ~/.config/tams/settings.json"
echo
echo -e "${C}Terima kasih sudah memakai tams-shell! 💖${N} Dukung di ${B}https://saweria.co/tamsrich${N}"
