#!/usr/bin/env bash
# Instala los dotfiles de Hyprland Kora.
#   ./instalar.sh                 paquetes + enlaces + sesión en la pantalla de inicio
#   ./instalar.sh --sin-paquetes  solo enlaces y sesión (si ya tienes todo instalado)
# Lo que ya exista en tu home se mueve a ~/.dotfiles-respaldo/<fecha>/ (no se borra nada).
set -e
DOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RESPALDO="$HOME/.dotfiles-respaldo/$(date +%F-%H%M%S)"

verde() { printf '\033[1;32m%s\033[0m\n' "$*"; }
aviso() { printf '\033[1;33m%s\033[0m\n' "$*"; }

# ───────────── Paquetes (Arch y derivadas: CachyOS, EndeavourOS, Manjaro…) ─────────────
PAQUETES=(
    # Hyprland y lo que lo rodea
    hyprland hyprlock hypridle hyprpicker hyprpolkitagent xdg-desktop-portal-hyprland uwsm
    quickshell waybar fuzzel mako cava
    # Wallpapers animados, capturas y portapapeles
    mpvpaper mpv ffmpeg imagemagick grim slurp wl-clipboard cliphist
    # Audio, brillo, energía, red y bluetooth
    pipewire wireplumber pavucontrol playerctl brightnessctl power-profiles-daemon
    networkmanager nm-connection-editor bluez bluez-utils blueman
    # Utilidades
    libnotify mission-center nwg-look fastfetch xorg-xhost acl python python-pillow
    # Terminales
    kitty alacritty
    # Fuentes
    ttf-jetbrains-mono-nerd ttf-cascadia-code-nerd ttf-rubik-vf
)

instalar_paquetes() {
    if ! command -v pacman >/dev/null; then
        aviso "No es una distro tipo Arch: instala a mano los paquetes de la lista PAQUETES de este script."
        return
    fi
    # pacman -T dice cuáles faltan (cuenta también versiones -git que ya los proveen)
    mapfile -t faltan < <(pacman -T "${PAQUETES[@]}" || true)
    [ ${#faltan[@]} -eq 0 ] && { verde "Paquetes: ya está todo."; return; }

    oficiales=() aur=()
    for p in "${faltan[@]}"; do
        if pacman -Si "$p" >/dev/null 2>&1; then oficiales+=("$p"); else aur+=("$p"); fi
    done
    [ ${#oficiales[@]} -gt 0 ] && sudo pacman -S --needed "${oficiales[@]}"
    if [ ${#aur[@]} -gt 0 ]; then
        ayudante=$(command -v paru || command -v yay || true)
        if [ -n "$ayudante" ]; then
            "$ayudante" -S --needed "${aur[@]}"
        else
            aviso "Estos están en el AUR y no tienes paru ni yay: ${aur[*]}"
        fi
    fi
    sudo systemctl enable --now power-profiles-daemon bluetooth 2>/dev/null || true
}

# ───────────── Enlaces ─────────────
enlazar() {   # enlazar <origen en el repo> <destino en tu home>
    local origen="$DOT/$1" destino="$2"
    if [ -L "$destino" ] && [ "$(readlink -f "$destino")" = "$(readlink -f "$origen")" ]; then
        return
    fi
    mkdir -p "$(dirname "$destino")"
    if [ -e "$destino" ] || [ -L "$destino" ]; then
        mkdir -p "$RESPALDO"
        mv "$destino" "$RESPALDO/"
        aviso "Respaldo: $destino → $RESPALDO/"
    fi
    ln -s "$origen" "$destino"
    echo "  $destino → $origen"
}

[ "$1" = --sin-paquetes ] || instalar_paquetes

verde "Enlazando configs…"
enlazar hypr-kora                "$HOME/.config/hypr-kora"
enlazar kitty                    "$HOME/.config/kitty"
enlazar alacritty                "$HOME/.config/alacritty"
enlazar bash/bashrc              "$HOME/.bashrc"
enlazar bash/bash_profile        "$HOME/.bash_profile"
enlazar bin/terminal-logo        "$HOME/.local/bin/terminal-logo"
enlazar bin/terminal-logo-ascii  "$HOME/.local/bin/terminal-logo-ascii"

# Carpetas que usan los scripts (los fondos no vienen en el repo: pon los tuyos aquí)
mkdir -p "$HOME/Imágenes/wallpapers" "$HOME/Vídeos/wallpapers" "$HOME/Imágenes/Capturas" \
         "$HOME/.local/state/hypr-kora"

# Nombre que sale en el panel y en el saludo de la terminal
NOMBRE="$HOME/.local/state/hypr-kora/nombre"
if [ ! -s "$NOMBRE" ] && [ -t 0 ]; then
    read -rp "¿Cómo quieres que te salude? [$USER] " n
    echo "${n:-$USER}" > "$NOMBRE"
fi

# ───────────── Sesión en la pantalla de inicio ─────────────
verde "Registrando la sesión «Hyprland Kora»…"
sed "s|@HOME@|$HOME|g" "$DOT/hypr-kora/hyprland-kora.desktop" \
    | sudo install -Dm 644 /dev/stdin /usr/share/wayland-sessions/hyprland-kora.desktop

if command -v Hyprland >/dev/null; then
    Hyprland --verify-config -c "$HOME/.config/hypr-kora/hyprland.lua" >/dev/null 2>&1 \
        && verde "Config de Hyprland revisada: sin errores." \
        || aviso "Hyprland marcó errores: corre  Hyprland --verify-config -c ~/.config/hypr-kora/hyprland.lua"
fi

verde "Listo. Cierra sesión y elige «Hyprland Kora» en la pantalla de inicio."
echo "Pon tus fondos en ~/Imágenes/wallpapers (y videos con el mismo nombre en ~/Vídeos/wallpapers)."
