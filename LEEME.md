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
| `mako/config` | Notificaciones |
| `fuzzel/fuzzel.ini` | Lanzador y menús |
| `hyprlock.conf`, `hypridle.conf` | Bloqueo e inactividad |
| `scripts/` | Portapapeles, menú de apagado, capturas, wallpaper |

## Atajos principales
| Atajo | Acción |
|---|---|
| Super (soltar) | Lanzador (fuzzel) |
| Super + Enter / W / E / C | Terminal / Brave / Dolphin / VSCodium |
| Super + Q | Cerrar ventana |
| Super + 1…0 | Workspaces |
| Super + M / D / O / G / S | Música / Discord / OBS / Juegos / Steam |
| Super + V | Portapapeles |
| Super + L | Bloquear |
| Super + Alt + C | Menú apagar/reiniciar |
| Super + Shift + W | Elegir wallpaper |
| Super + A / Shift+A | Ver última notificación / borrar todas |
| Super + Shift + B | Recargar Waybar |
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
