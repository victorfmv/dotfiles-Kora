#!/usr/bin/env bash
# Abre/cierra el centro de control y notificaciones (Super + X). Si no corre, lo arranca.
# Otro panel del mismo Quickshell: centro.sh --target energia toggle <x>
QS="$HOME/.config/hypr-kora/centro"
T=centro
[ "$1" = --target ] && { T=$2; shift 2; }
[ $# -eq 0 ] && set -- toggle
if ! timeout 2 qs -p "$QS" ipc call "$T" "$@" 2>/dev/null; then
    setsid -f qs -p "$QS" >/dev/null 2>&1
    for _ in $(seq 20); do
        sleep 0.1
        timeout 2 qs -p "$QS" ipc call "$T" "$@" 2>/dev/null && break
    done
fi
