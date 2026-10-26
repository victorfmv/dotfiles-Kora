#!/usr/bin/env bash
# Wallpaper de Hyprland Kora (independiente del de Caelestia).
#   wallpaper.sh        -> pone el último elegido
#   wallpaper.sh pick   -> elegir en el panal de hexágonos (Super+Shift+W, fondos/shell.qml)
#   wallpaper.sh set <imagen> -> poner esa imagen (lo usa el panal)
# Si hay un video con el mismo nombre en ~/Vídeos/wallpapers, lo reproduce animado.
IMGS="$HOME/Imágenes/wallpapers"
VIDEOS="$HOME/Vídeos/wallpapers"
STATE="$HOME/.local/state/hypr-kora/wallpaper"
mkdir -p "$(dirname "$STATE")"

# Videos sin imagen: sacarle una para la lista (y para el panel / vista de workspaces)
for v in "$VIDEOS"/*.{mp4,webm,mkv,mov}; do
    [ -f "$v" ] || continue
    b=$(basename "${v%.*}")
    ls "$IMGS/$b".* >/dev/null 2>&1 || ffmpeg -v error -y -ss 1 -i "$v" -frames:v 1 "$IMGS/$b.png"
done

if [ "$1" = pick ]; then
    exec "$HOME/.config/hypr-kora/scripts/fondos.sh" toggle
elif [ "$1" = set ] && [ -f "$2" ]; then
    echo "$2" > "$STATE"
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

# Colores del tema que va con este fondo (temas/fondos.json; si no está, "dorado")
tema=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1])).get(sys.argv[2], "dorado"))' \
    "$HOME/.config/hypr-kora/temas/fondos.json" "$base" 2>/dev/null)
"$HOME/.config/hypr-kora/scripts/tema.py" "${tema:-dorado}" >/dev/null
# La pantalla de inicio (login) usa el mismo fondo y colores
"$HOME/.config/hypr-kora/scripts/greeter-sync.py" >/dev/null 2>&1 &

# El nuevo se lanza encima del viejo y el viejo se quita cuando el nuevo ya se ve:
# así nunca queda la pantalla en negro mientras cambia.
viejos=$(pgrep -x mpvpaper)
setsid -f mpvpaper -f -o "no-audio loop hwdec=auto-safe panscan=1.0 image-display-duration=inf" '*' "$media" >/dev/null 2>&1
[ -n "$viejos" ] || exit 0
sleep 0.6
kill $viejos 2>/dev/null; sleep 0.3; kill -9 $viejos 2>/dev/null
exit 0
