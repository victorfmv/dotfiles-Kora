#!/usr/bin/env bash
# Cambia el modo de energía (lo llama el menú de la batería en Waybar): energia.sh performance|balanced|power-saver
case "$1" in
    performance) nombre=Rendimiento ;;
    balanced)    nombre=Balanceado ;;
    power-saver) nombre=Ahorro ;;
    *) exit 1 ;;
esac
powerprofilesctl set "$1" && notify-send -a "Energía" "Modo de energía" "$nombre"
