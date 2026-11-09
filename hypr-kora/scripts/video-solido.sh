#!/usr/bin/env bash
# Navegador transparente, pero sólido mientras suena un video (modo Familiar, config/familiar.lua).
# Hyprland solo puede transparentar la ventana COMPLETA, así que escucha a los reproductores
# MPRIS y le pone la etiqueta "video" a las ventanas del navegador cuando alguno está en Playing.
exec 8>"${XDG_RUNTIME_DIR:-/tmp}/kora-video-solido.lock"
flock -n 8 || exit 0   # una sola copia

NAVS='^(brave|chromium|chrome|firefox|zen)'
CLASES='^(brave-browser|chromium|google-chrome|firefox|zen)$'
estado=""

aplicar() {
    local ahora=no p signo a
    for p in $(playerctl -l 2>/dev/null | grep -E "$NAVS"); do
        [ "$(playerctl -p "$p" status 2>/dev/null)" = Playing ] && ahora=si
    done
    [ "$ahora" = "$estado" ] && return
    estado=$ahora
    [ "$ahora" = si ] && signo=+ || signo=-
    for a in $(hyprctl clients -j | jq -r --arg c "$CLASES" '.[] | select(.class | test($c)) | .address'); do
        hyprctl dispatch "hl.dsp.window.tag({ tag = '${signo}video', window = 'address:$a' })" >/dev/null
    done
}

aplicar
playerctl -a --follow status 2>/dev/null | while read -r _; do aplicar; done
