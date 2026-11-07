#!/usr/bin/env bash
# tams-shell: tangkap layar. Dipanggil oleh services/Screenshot.qml.
#   screenshot.sh <folder> <area|screen|all> [layar aktif] [kotak jendela "X,Y WxH" per baris]
dir="$1"; mode="$2"; mon="$3"; boxes="$4"

sleep 0.35   # tunggu panel selesai menutup supaya tidak ikut terfoto
mkdir -p "$dir" || exit 1
f="$dir/Screenshot_$(date +%Y-%m-%d_%H-%M-%S).png"

case "$mode" in
    area)
        opts=(-d -b 00000066 -c ffffffcc -w 2)
        if [ -n "$boxes" ]; then g=$(printf '%s\n' "$boxes" | slurp "${opts[@]}"); else g=$(slurp "${opts[@]}"); fi
        [ -n "$g" ] || exit 0          # dibatalkan (Esc / klik kanan)
        grim -g "$g" "$f" ;;
    screen)
        if [ -n "$mon" ]; then grim -o "$mon" "$f"; else grim "$f"; fi ;;
    *)
        grim "$f" ;;
esac || { notify-send -a Screenshot -u critical "Screenshot gagal" "grim tidak bisa menangkap layar"; exit 1; }

command -v wl-copy >/dev/null && wl-copy --type image/png < "$f"

# Notifikasi dengan pratinjau; tunggu tombolnya diklik (paling lama 10 menit)
a=$(timeout 600 notify-send -a Screenshot -i "$f" -h "string:image-path:$f" \
    -A open=Buka -A folder="Buka folder" --wait \
    "Screenshot disimpan" "Di ${dir/#$HOME/\~} · disalin ke clipboard")
case "$a" in
    open) xdg-open "$f" ;;
    folder) xdg-open "$dir" ;;
esac
