# Hyprland Kora

Hyprland personalizado de Victor, **aparte** de Caelestia (`~/.config/hypr`, que no se toca).
Mismo programa Hyprland, otra config: `start-hyprland -- -c ~/.config/hypr-kora/hyprland.lua`.
Se elige en la pantalla de inicio como **Hyprland Kora** (`/usr/share/wayland-sessions/hyprland-kora.desktop`).

## Archivos
| Archivo | Qué hace |
|---|---|
| `hyprland.lua` | Punto de entrada, carga todo `config/` |
| `config/colors.lua` | Paleta `KORA` (dorado). Waybar/mako/fuzzel/hyprlock repiten estos hex |
| `config/variables.lua` | Apps por defecto (kitty, brave, codium…) y monitores |
| `config/binds.lua` | Atajos |
| `config/autostart.lua` | Lo que se abre al iniciar (waybar, mako, hypridle, wallpaper…) |
| `config/decorations.lua` | Bordes, gaps, blur, opacidad |
| `config/windowrules.lua` | Reglas de ventanas (Spotify→music, Discord, OBS…) |
| `config/workspaces.lua` | Workspaces y espacios especiales |
| `config/monitors.lua` | eDP-1 2560x1600@240 escala 1.25 + externos a la derecha |
| `waybar/` | Barra (`config.jsonc` + `style.css`) |
| `centro/` | Centro de control y notificaciones (Quickshell, reemplaza a mako): Super+X |
| `mako/config` | (ya no se usa; quedó por si se quiere volver a mako) |
| `fuzzel/fuzzel.ini` | Lanzador y menús |
| `hyprlock.conf`, `hypridle.conf` | Bloqueo e inactividad |
| `scripts/` | Portapapeles, menú de apagado, capturas, wallpaper, workspaces de Waybar, vistas |
| `overview/shell.qml` | Vista de todos los workspaces (Quickshell) |
| `fondos/shell.qml` | Selector de wallpapers: panal de hexágonos animado (Quickshell, `scripts/fondos.sh`) |

## Atajos principales
| Atajo | Acción |
|---|---|
| Super (soltar) | Lanzador (fuzzel) |
| Super + Enter / W / E / C | Terminal / Brave / Dolphin / VSCodium |
| Super + Q | Cerrar ventana |
| Super + 1…0 | Workspaces |
| Super + ← / → | Ventana anterior / siguiente (fila horizontal tipo niri) |
| Super + ↑ / ↓ | Workspace de arriba / abajo |
| Super + J | Ventana a media pantalla / completa |
| Super + Tab | Vista de la fila: ver todas las ventanas del workspace |
| Super + Shift + Tab · pellizco 3 dedos · Super + rueda | Alejamiento: todos los workspaces con sus ventanas (Quickshell, `overview/shell.qml`) |
| 3 dedos ← → | Recorrer ventanas · 3 dedos ↑ ↓: cambiar workspace |
| 4 dedos ↑ / ← | Pantalla completa / flotante |
| Super + M / D / O / G / S | Música / Discord / OBS / Juegos / Steam |
| Super + V | Portapapeles |
| Super + L | Bloquear |
| Super + Alt + C | Menú apagar/reiniciar |
| Super + Shift + W | Elegir wallpaper: panal de hexágonos animado (flechas/ratón + Enter, Esc cierra) |
| Super + X (o A) / Super + Shift + A | Centro de control y notificaciones / borrar todas |
| Super + Shift + B | Recargar Waybar |
| Alt + F6 (con o sin Fn) | Ventiladores al máximo / automático (`~/.local/bin/ventiladores`, no cambia el modo de energía) |
| Clic en la batería | Panel de batería y modo de energía (Ahorro / Balanceado / Rendimiento) que sale bajo la barra (`centro/Energia.qml`, `scripts/energia.sh`) |
| Impr / Super + Impr | Captura de área / pantalla completa |

## Si algo se rompe
- **Revisar la config sin arrancar:** `Hyprland --verify-config -c ~/.config/hypr-kora/hyprland.lua`
- **Ver errores en vivo:** `hyprctl configerrors`
- **Historial de cambios:** `git -C ~/.config/hypr-kora log --oneline`
- **Volver a la última versión buena:** `git -C ~/.config/hypr-kora checkout -- .` (descarta cambios sin guardar)
- **Pantalla negra al entrar:** Ctrl+Alt+F3, entra con tu usuario y corre el verify-config de arriba. O simplemente cierra sesión y entra a Caelestia.
- Logs de Hyprland: `$XDG_RUNTIME_DIR/hypr/*/hyprland.log`

## Regla de trabajo
Cada cambio = un commit en git (nada de `.bak`). Cambios de Caelestia van en `~/.config/hypr`, NO aquí.

## Temas de colores

Cada fondo puede tener su propia paleta. Al elegir un fondo (Super+Shift+W o el botón del panel) se ponen sus colores solos en Waybar, el panel, la vista de workspaces, el bloqueo, los bordes y fuzzel.

El cambio es en vivo: Waybar **no se reinicia** (recarga `style.css` sola con `reload_style_on_change`; `workspaces.py` relee sus colores con SIGUSR1 y `cava-waybar.sh` cada segundo). No poner colores en `waybar/config.jsonc`: ahí no se recargan.

- `temas/<nombre>.json`: cada tema.

  | Fondo | Tema |
  |---|---|
  | angel-de-ceniza | ceniza: blanco y negro, acento plateado |
  | visor-dorado | dorado: el original |
  | dragon-de-tormenta | dragon: carmesí sobre azul pizarra |
  | mirada-al-cielo | cielo: azul celeste |
  | ojos-de-galaxia | galaxia: violeta sobre índigo |
  | makima-control | makima: cobre y ámbar |
  | samurai-errante | tinta: grises con toque jade |
- `temas/fondos.json`: qué tema usa cada fondo (nombre del archivo sin extensión). Si un fondo no aparece, usa `dorado`.
- `scripts/tema.py <nombre>`: cambia el tema a mano. `scripts/tema.py` solo dice cuál está puesto.
- `temas/base.json`: todos los colores del tema dorado. Si agregas colores nuevos, ponlos en su versión dorada, con `tema.py dorado` activo, y corre `tema.py --base`.

Para agregar un fondo animado, basta con guardar el `.mp4` en `~/Vídeos/wallpapers/`: la imagen para la lista se saca sola.
