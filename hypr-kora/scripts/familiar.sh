#!/usr/bin/env bash
# Modo Familiar (estética tipo macOS): barra en islas redondas, ventanas más
# redondeadas con sombra suave. Todo con los colores del fondo actual. Se quita igual de fácil.
#   familiar.sh            → prender/apagar
#   familiar.sh on | off   → forzar
K="$HOME/.config/hypr-kora"
EST="$HOME/.local/state/hypr-kora/familiar"

case "${1:-toggle}" in
    on)  modo=on ;;
    off) modo=off ;;
    *)   [ -e "$EST" ] && modo=off || modo=on ;;
esac

if [ "$modo" = on ]; then
    mkdir -p "$(dirname "$EST")"; touch "$EST"
else
    rm -f "$EST"
fi
hyprctl reload >/dev/null          # config/familiar.lua: esquinas, sombras, bordes, márgenes
setsid -f "$K/scripts/barra.sh" >/dev/null 2>&1
echo "Modo Familiar: $modo"
