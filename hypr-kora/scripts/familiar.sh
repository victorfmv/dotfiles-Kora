#!/usr/bin/env bash
# Modo Familiar (estética tipo macOS): dock abajo, barra en islas redondas, ventanas más
# redondeadas con sombra suave. Todo con los colores del fondo actual. Se quita igual de fácil.
#   familiar.sh            → prender/apagar
#   familiar.sh on | off   → forzar
#   familiar.sh arrancar   → (autostart) levanta el dock si el modo está prendido
K="$HOME/.config/hypr-kora"
EST="$HOME/.local/state/hypr-kora/familiar"

dock_on()  { pgrep -f "^qs -p \S*/hypr-kora/dock$" >/dev/null || setsid -f qs -p "$K/dock" >/dev/null 2>&1; }
dock_off() { pkill -f "^qs -p \S*/hypr-kora/dock$"; }

case "${1:-toggle}" in
    arrancar) [ -e "$EST" ] && dock_on; exit 0 ;;
    on)  modo=on ;;
    off) modo=off ;;
    *)   [ -e "$EST" ] && modo=off || modo=on ;;
esac

if [ "$modo" = on ]; then
    mkdir -p "$(dirname "$EST")"; touch "$EST"
    dock_on
else
    rm -f "$EST"
    dock_off
fi
hyprctl reload >/dev/null          # config/familiar.lua: esquinas, sombras, bordes, márgenes
setsid -f "$K/scripts/barra.sh" >/dev/null 2>&1
echo "Modo Familiar: $modo"
