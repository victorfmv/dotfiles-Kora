#!/usr/bin/env bash
# Abre el Monitor del sistema (clic en CPU/RAM/disco/temperatura de Waybar).
# Si no está instalado, lo instala con la ventanita de contraseña (pkexec), sin terminal.
if ! command -v mission-center >/dev/null; then
    notify-send -a "Monitor" "󰄨  Instalando el Monitor del sistema" "Pon tu contraseña en la ventanita. Se abre solo al terminar."
    if ! pkexec pacman -S --needed --noconfirm mission-center; then
        notify-send -a "Monitor" "󰄨  No se instaló el Monitor" "Se canceló o no hay internet. Inténtalo otra vez."
        exit 1
    fi
fi
exec mission-center
