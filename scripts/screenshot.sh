#!/usr/bin/env bash
# Capturas: "area" (Impr) o "full" (Super+Impr). Se guardan y se copian.
dir="$HOME/Imágenes/Capturas"; mkdir -p "$dir"
file="$dir/$(date +%Y-%m-%d_%H-%M-%S).png"
case "$1" in
    full) grim "$file" ;;
    *)    grim -g "$(slurp)" "$file" || exit 1 ;;
esac
wl-copy < "$file"
notify-send -i "$file" "Captura guardada" "$file"
