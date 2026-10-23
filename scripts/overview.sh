#!/usr/bin/env bash
# Abre/cierra la vista de workspaces (Quickshell). Si no está corriendo, la arranca.
#   overview.sh [toggle|open|close]   ·   overview.sh scroll 1|-1  (Super + rueda)
QS="$HOME/.config/hypr-kora/overview"
[ $# -eq 0 ] && set -- toggle
if ! timeout 2 qs -p "$QS" ipc call overview "$@" 2>/dev/null; then
    setsid -f qs -p "$QS" >/dev/null 2>&1
    for _ in $(seq 20); do
        sleep 0.1
        timeout 2 qs -p "$QS" ipc call overview "$@" 2>/dev/null && break
    done
fi
