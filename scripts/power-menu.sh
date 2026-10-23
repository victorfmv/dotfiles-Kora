#!/usr/bin/env bash
# Menú de sesión (Super+Alt+C)
F="$HOME/.config/hypr-kora/scripts/fuzzel.sh"
pkill fuzzel && exit 0
choice=$(printf '󰌾  Bloquear\n󰍃  Cerrar sesión\n󰤄  Suspender\n󰜉  Reiniciar\n󰐥  Apagar\n' \
    | "$F" --dmenu --prompt "⏻  " --lines 5 --width 25)
case "$choice" in
    *Bloquear*)      hyprlock -c "$HOME/.config/hypr-kora/hyprlock.conf" ;;
    *Cerrar*)        uwsm stop 2>/dev/null || hyprctl dispatch exit ;;
    *Suspender*)     systemctl suspend ;;
    *Reiniciar*)     systemctl reboot ;;
    *Apagar*)        systemctl poweroff ;;
esac
