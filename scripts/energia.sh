#!/usr/bin/env bash
# Menú de modo de energía (clic en la batería de Waybar)
F="$HOME/.config/hypr-kora/scripts/fuzzel.sh"
pkill fuzzel && exit 0
actual=$(powerprofilesctl get)
marca() { [ "$actual" = "$1" ] && echo "  ●"; }
choice=$(printf '󰓅  Rendimiento%s\n󰾅  Balanceado%s\n󰾆  Ahorro%s\n' \
    "$(marca performance)" "$(marca balanced)" "$(marca power-saver)" \
    | "$F" --dmenu --prompt "󰂄  " --placeholder "Modo de energía…" --lines 3 --width 25)
case "$choice" in
    *Rendimiento*) perfil=performance; nombre=Rendimiento ;;
    *Balanceado*)  perfil=balanced;    nombre=Balanceado ;;
    *Ahorro*)      perfil=power-saver; nombre=Ahorro ;;
    *) exit 0 ;;
esac
powerprofilesctl set "$perfil" && notify-send -a "Energía" "Modo de energía" "$nombre"
