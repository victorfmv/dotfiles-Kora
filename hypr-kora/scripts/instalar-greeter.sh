#!/usr/bin/env bash
# Una sola vez, con sudo: la pantalla de inicio lee el greeter.toml que genera
# scripts/greeter-sync.py, para que cambie sola con cada wallpaper.
#   sudo bash ~/.config/hypr-kora/scripts/instalar-greeter.sh
set -e
U=${SUDO_USER:-$USER}
H=/home/$U
DIR=/var/lib/noctalia-greeter
GEN=$H/.local/state/hypr-kora/greeter

[ -f "$GEN/greeter.toml" ] || { echo "Primero corre (sin sudo): ~/.config/hypr-kora/scripts/greeter-sync.py"; exit 1; }

# El usuario greeter solo puede ATRAVESAR tu home (no listarlo ni leer otras cosas)
setfacl -m u:greeter:x "$H"

if [ -e "$DIR/greeter.toml" ] && [ ! -L "$DIR/greeter.toml" ]; then
    cp -a "$DIR/greeter.toml" "$DIR/greeter.toml.bak-$(date +%F)"
    echo "Respaldo: $DIR/greeter.toml.bak-$(date +%F)"
fi
ln -sfn "$GEN/greeter.toml" "$DIR/greeter.toml"
rm -f "$DIR/wallpaper-visor-dorado.png"

if sudo -u greeter test -r "$GEN/greeter.toml" && sudo -u greeter test -r "$GEN/wallpaper.png"; then
    echo "Listo. La pantalla de inicio usará el wallpaper y colores de Kora (se ve al cerrar sesión o reiniciar)."
else
    echo "Aviso: el usuario greeter no puede leer $GEN"
fi
