#!/usr/bin/env bash
# Lanzador de Hyprland Kora.
# - Modo Familiar y sin opciones (Super, logo de la barra): lanzador propio estilo Caelestia (lanzador/)
# - Con opciones (--dmenu de los menús de apagar y portapapeles): fuzzel, con su estilo de vidrio
K="$HOME/.config/hypr-kora"
if [ -e "$HOME/.local/state/hypr-kora/familiar" ]; then
    if [ $# -eq 0 ]; then
        qs -p "$K/lanzador" ipc call lanzador toggle 2>/dev/null || {
            setsid -f qs -p "$K/lanzador" >/dev/null 2>&1; sleep 0.6
            qs -p "$K/lanzador" ipc call lanzador open
        }
        exit 0
    fi
    exec fuzzel --config "$K/fuzzel/familiar.ini" "$@"
fi
exec fuzzel --config "$K/fuzzel/fuzzel.ini" "$@"
