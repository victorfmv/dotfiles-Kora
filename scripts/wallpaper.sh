#!/usr/bin/env bash
# Wallpaper de Hyprland Kora (independiente del de Caelestia).
#   wallpaper.sh        -> pone el último elegido
#   wallpaper.sh pick   -> elegir con fuzzel (Super+Shift+W)
# Si hay un video con el mismo nombre en ~/Vídeos/wallpapers, lo reproduce animado.
IMGS="$HOME/Imágenes/wallpapers"
VIDEOS="$HOME/Vídeos/wallpapers"
STATE="$HOME/.local/state/hypr-kora/wallpaper"
mkdir -p "$(dirname "$STATE")"

if [ "$1" = pick ]; then
    pkill fuzzel && exit 0
    name=$(ls "$IMGS" | "$HOME/.config/hypr-kora/scripts/fuzzel.sh" --dmenu --prompt "󰸉  " --placeholder "Elegir wallpaper…") || exit 0
    echo "$IMGS/$name" > "$STATE"
fi

img=$(cat "$STATE" 2>/dev/null)
[ -f "$img" ] || img=$(ls -d "$IMGS"/* 2>/dev/null | head -1)
[ -f "$img" ] || exit 0
echo "$img" > "$STATE"   # la vista de workspaces lo lee de aquí

base=$(basename "${img%.*}")
media="$img"
for ext in mp4 webm mkv mov; do
    [ -f "$VIDEOS/$base.$ext" ] && media="$VIDEOS/$base.$ext" && break
done

pkill -x mpvpaper; sleep 0.3; pkill -9 -x mpvpaper 2>/dev/null
exec mpvpaper -f -o "no-audio loop hwdec=auto-safe panscan=1.0 image-display-duration=inf" '*' "$media"
