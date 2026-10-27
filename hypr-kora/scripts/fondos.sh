#!/usr/bin/env bash
# Abre/cierra el selector de wallpapers (Quickshell, panal de hexágonos). Si no está corriendo, lo arranca.
#   fondos.sh [toggle|open|close]
QS="$HOME/.config/hypr-kora/fondos"
[ $# -eq 0 ] && set -- toggle
if ! timeout 2 qs -p "$QS" ipc call fondos "$@" 2>/dev/null; then
    setsid -f qs -p "$QS" >/dev/null 2>&1
    for _ in $(seq 20); do
        sleep 0.1
        timeout 2 qs -p "$QS" ipc call fondos "$@" 2>/dev/null && break
    done
fi
