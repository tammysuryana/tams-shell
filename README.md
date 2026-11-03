# tams-shell

**Shell Hyprland bergaya "bingkai"**: layar dibingkai tipis dengan sudut dalam melengkung,
info sistem hidup di bingkai atas, dan semua panel *tumbuh keluar dari bingkai*,
bukan melayang di atas layar. Warna solid, tanpa kaca, tanpa gradien.

Dibuat dengan [Quickshell](https://quickshell.org), ditulis dari nol, lisensi MIT.

🇬🇧 English: [README.en.md](README.en.md) · 💖 Dukung pengembangannya di **[Saweria](https://saweria.co/tamsrich)**

![Desktop](docs/desktop.jpg)

| Dashboard (klik jam / `Super + A`) | Launcher (`Super + Space`) |
|---|---|
| ![Dashboard](docs/dashboard.jpg) | ![Launcher](docs/launcher.jpg) |

---

## Fitur

- **Bingkai atas**: logo, nomor workspace (klik untuk pindah), judul jendela, jam,
  CPU, RAM, WiFi, volume, baterai.
- **Dashboard** keluar dari bingkai atas: jam besar, pemutar musik (Spotify, browser, dll.),
  sakelar WiFi / Bluetooth / Jangan ganggu / Lampu malam, slider volume & kecerahan,
  daftar notifikasi, tombol kunci / keluar / ulang / matikan.
- **Launcher** keluar dari sisi kiri: cari aplikasi, `=` untuk menghitung (`=1920*1080`),
  `>` untuk menjalankan perintah. Bisa dipakai penuh dengan keyboard.
- **Notifikasi** keluar dari sisi kanan bingkai (server notifikasi bawaan, tidak perlu dunst/mako).
- **Indikator volume & kecerahan** muncul di sisi kanan saat diubah.
- Banyak monitor: tiap layar punya bingkai sendiri, panel muncul di layar yang aktif.
- Teks bahasa Indonesia, nama hari/bulan ikut bahasa sistem.

---

## Pasang

Butuh **Arch Linux** (atau turunannya: CachyOS, EndeavourOS, …) dengan **Hyprland**.

```bash
sudo pacman -S --needed git
git clone https://github.com/tammysuryana/tams-shell.git ~/tams-shell
cd ~/tams-shell
./install.sh
```

Installer akan:
1. Memasang paket yang dibutuhkan. Semuanya dari repo resmi Arch: `quickshell`, `ttf-jetbrains-mono-nerd`,
   `brightnessctl`, `hyprsunset`, `networkmanager`, `bluez`, `pipewire`, dll.
2. Menyalin shell ke `~/.config/quickshell/tams`.
3. Menyambungkan ke Hyprland: jalan otomatis saat login + shortcut. Sebelum mengubah `hyprland.lua` /
   `hyprland.conf`, installer bertanya dulu dan membuat cadangan.

Coba langsung tanpa logout:

```bash
qs -c tams
```

> ⚠️ Kalau kamu sudah memakai bar/shell lain (misalnya waybar), matikan dulu
> dari config Hyprland supaya tidak tumpang tindih.

**Copot:** `./install.sh --uninstall`

---

## Tombol & perintah

| Tombol | Fungsi |
|---|---|
| `Super + Space` | Buka/tutup launcher |
| `Super + A` | Buka/tutup dashboard |
| Klik jam | Dashboard |
| Klik logo | Launcher |
| `Esc` / klik di luar panel | Tutup panel |

Dari terminal / skrip:

```bash
qs -c tams ipc call tams launcher    # buka/tutup launcher
qs -c tams ipc call tams dashboard   # buka/tutup dashboard
qs -c tams ipc call tams close       # tutup semua panel
```

Shortcut Hyprland memakai `global, tams:launcher` dan `global, tams:dashboard`, jadi bebas dipasang
ke tombol lain.

---

## Pengaturan

File `~/.config/tams/settings.json` (dibuat otomatis saat pertama jalan, berubah langsung tanpa restart):

```json
{
  "wallpaper": "/home/kamu/Gambar/wallpaper.jpg",
  "terminal": "kitty",
  "workspaces": 5
}
```

- `wallpaper`: kosongkan (`""`) untuk wallpaper bawaan.
- `workspaces`: jumlah nomor workspace yang selalu tampil.

Warna, tebal bingkai, dan font ada di `~/.config/quickshell/tams/config/Theme.qml`.

---

## Kalau ada masalah

| Masalah | Solusi |
|---|---|
| Bingkai tidak muncul | Jalankan `qs -c tams` di terminal dan baca pesan errornya |
| Ikon jadi kotak-kotak | `sudo pacman -S ttf-jetbrains-mono-nerd` |
| Shortcut `Super + Space` tidak jalan | Pastikan `~/.config/hypr/tams-shell.lua` (atau `.conf`) dimuat oleh config Hyprland |
| Dua bar tumpang tindih | Matikan bar/shell lama di config Hyprland |
| Slider kecerahan tidak ada | Normal di PC desktop (tidak ada lampu layar yang bisa diatur) |

---

## Dukung

tams-shell gratis. Kalau bermanfaat, dukung pengembangannya lewat **[Saweria](https://saweria.co/tamsrich)** 💖,
kasih ⭐, atau laporkan masalah di [Issues](https://github.com/tammysuryana/tams-shell/issues).

## Lisensi

[MIT](LICENSE) © 2026 tams. Font Inter disertakan dengan lisensi SIL OFL 1.1 (`shell/assets/fonts/LICENSE-Inter.txt`).
