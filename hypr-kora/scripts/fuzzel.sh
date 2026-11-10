#!/usr/bin/env bash
# fuzzel con la config de Hyprland Kora (la del modo Familiar si está prendido)
conf="$HOME/.config/hypr-kora/fuzzel/fuzzel.ini"
[ -e "$HOME/.local/state/hypr-kora/familiar" ] && conf="$HOME/.config/hypr-kora/fuzzel/familiar.ini"
exec fuzzel --config "$conf" "$@"
