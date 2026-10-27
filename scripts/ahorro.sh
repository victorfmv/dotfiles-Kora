#!/usr/bin/env bash
# Ahorro de batería automático (se lanza al iniciar Hyprland Kora, ver config/autostart.lua).
#   Con batería:  pantalla a 60 Hz, fondo fijo (sin video), modo "power-saver"
#   Con cargador: pantalla a 240 Hz, fondo animado, modo "balanced"
AC=/sys/class/power_supply/AC/online
K="$HOME/.config/hypr-kora"

aplicar() {
    if [ "$1" = 1 ]; then hz=240; perfil=balanced; else hz=60; perfil=power-saver; fi
    hyprctl eval "hl.monitor({ output = MONITOR1, mode = \"2560x1600@$hz\", position = \"0x0\", scale = \"1.25\" })" >/dev/null
    powerprofilesctl set "$perfil" 2>/dev/null
    "$K/scripts/wallpaper.sh"
}

# Una sola copia corriendo
exec 9>"${XDG_RUNTIME_DIR:-/tmp}/kora-ahorro.lock"
flock -n 9 || exit 0

antes=""
while :; do
    ahora=$(cat "$AC" 2>/dev/null)
    if [ -n "$ahora" ] && [ "$ahora" != "$antes" ]; then
        # Al iniciar sesión el fondo y la pantalla ya salen bien; solo se toca el modo de energía
        if [ -z "$antes" ]; then
            [ "$ahora" = 1 ] && powerprofilesctl set balanced 2>/dev/null || powerprofilesctl set power-saver 2>/dev/null
        else
            aplicar "$ahora"
        fi
        antes=$ahora
    fi
    sleep 3
done
