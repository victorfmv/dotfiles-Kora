#!/usr/bin/env bash
# Abre/cierra el panel de batería y modo de energía (clic en la batería de Waybar), centrado donde está el cursor
x=$(hyprctl cursorpos | cut -d, -f1)
exec ~/.config/hypr-kora/scripts/centro.sh --target energia toggle "${x:-1900}"
