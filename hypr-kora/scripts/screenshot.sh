#!/usr/bin/env bash
# Capturas: "area" (Impr) o "full" (Super+Impr). Se guardan y se copian.
# Si ya hay una captura en curso, ignorar (evita apilar selectores de slurp).
exec 9>"${XDG_RUNTIME_DIR:-/tmp}/screenshot.lock"
flock -n 9 || exit 0

dir="$HOME/Imágenes/Capturas"; mkdir -p "$dir"
file="$dir/$(date +%Y-%m-%d_%H-%M-%S).png"
case "$1" in
    full) grim "$file" ;;
    *)    grim -g "$(slurp)" "$file" || exit 1 ;;
esac
wl-copy < "$file"
notify-send -i "$file" "Captura guardada" "$file"
