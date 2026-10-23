#!/usr/bin/env bash
# Abre/cierra la vista de workspaces (Quickshell). Si no está corriendo, la arranca.
QS="$HOME/.config/hypr-kora/overview"
accion="${1:-toggle}"
if ! qs -p "$QS" ipc call overview "$accion" 2>/dev/null; then
    setsid -f qs -p "$QS" >/dev/null 2>&1
    for _ in $(seq 20); do
        sleep 0.1
        qs -p "$QS" ipc call overview "$accion" 2>/dev/null && break
    done
fi
