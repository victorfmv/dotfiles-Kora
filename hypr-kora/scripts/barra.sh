#!/usr/bin/env bash
# Lanza (o relanza) Waybar con el estilo del modo actual: normal o Familiar (scripts/familiar.sh)
K="$HOME/.config/hypr-kora"
pkill -x waybar && sleep 0.4
if [ -e "$HOME/.local/state/hypr-kora/familiar" ]; then
    exec waybar -c "$K/waybar/familiar.jsonc" -s "$K/waybar/familiar.css"
else
    exec waybar -c "$K/waybar/config.jsonc" -s "$K/waybar/style.css"
fi
