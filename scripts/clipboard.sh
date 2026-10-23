#!/usr/bin/env bash
# Historial del portapapeles (Super+V)
F="$HOME/.config/hypr-kora/scripts/fuzzel.sh"
pkill fuzzel && exit 0
cliphist list | "$F" --dmenu --prompt "󰅌  " | cliphist decode | wl-copy
