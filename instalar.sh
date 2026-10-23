#!/usr/bin/env bash
# Instala lo que necesita Hyprland Kora y registra la sesión en la pantalla de inicio.
# Correr una vez:  bash ~/.config/hypr-kora/instalar.sh
set -e
sudo pacman -S --needed waybar mako hyprlock hypridle playerctl pavucontrol libnotify
sudo install -m 644 "$HOME/.config/hypr-kora/hyprland-kora.desktop" /usr/share/wayland-sessions/hyprland-kora.desktop
echo "Listo. Cierra sesión y elige «Hyprland Kora» en la pantalla de inicio."
