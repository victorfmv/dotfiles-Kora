# dotfiles-Kora · Hyprland Kora

Mi escritorio de Linux: **Hyprland** con config en Lua, **Waybar**, paneles hechos en **Quickshell** y colores que cambian solos según el wallpaper.

> 🇬🇧 *Hyprland rice (Lua config) with Waybar, custom Quickshell panels and per-wallpaper color themes. Clone it and run `./instalar.sh` on any Arch-based distro. Docs are in Spanish.*

## Qué trae

- **Hyprland Kora**: layout `scrolling` tipo niri (las ventanas van en fila), gestos de 3 y 4 dedos y ventanas con efecto de vidrio difuminado.
- **Temas por wallpaper**: al cambiar de fondo cambian también los colores de la barra, los paneles, los bordes, el lanzador y la pantalla de bloqueo. Todo en vivo, sin reiniciar nada.
- **Wallpapers animados**: si hay un video con el mismo nombre que la imagen, se reproduce con `mpvpaper`. Con batería se queda la imagen fija para ahorrar.
- **Quickshell propio**:
  - `centro/`: centro de control y notificaciones (`Super + X`).
  - `overview/`: vista de todos los workspaces (`Super + Shift + Tab`).
  - `fondos/`: selector de wallpapers en panal de hexágonos (`Super + Shift + W`).
- **Waybar** lisa: workspaces como puntos, visualizador de audio (cava) y panel de batería.
- **Terminales** kitty y alacritty, que abren siempre **bash**, con un saludo en fastfetch que usa los colores del tema.

## Instalar

Funciona en **Arch y derivadas** (CachyOS, EndeavourOS, Manjaro…).

```bash
git clone https://github.com/victorfmv/dotfiles-Kora.git ~/dotfiles
cd ~/dotfiles
./instalar.sh
```

El instalador hace esto:

1. Instala solo los paquetes que faltan. Usa `pacman`, y `paru` o `yay` para los del AUR.
2. Enlaza las configs desde el repo a tu home (`~/.config/hypr-kora`, `kitty`, `alacritty`, `~/.bashrc`…).
3. **No borra nada**: lo que ya tenías se mueve a `~/.dotfiles-respaldo/<fecha>/`.
4. Te pregunta cómo quieres que te salude el panel.
5. Registra la sesión **Hyprland Kora** en la pantalla de inicio.

Luego cierra sesión y elige **Hyprland Kora**.

Si ya tienes todo instalado y solo quieres los enlaces, usa `./instalar.sh --sin-paquetes`.

> No toca `~/.config/hypr`: si ya usas otro Hyprland (Caelestia, HyDE, etc.), sigue ahí como otra sesión.

## Wallpapers

Los fondos **no vienen en el repo**. Pon los tuyos aquí:

| Carpeta | Qué va |
|---|---|
| `~/Imágenes/wallpapers/` | Imágenes (`.png`, `.jpg`) |
| `~/Vídeos/wallpapers/` | Videos opcionales con **el mismo nombre** que la imagen (`.mp4`, `.webm`) |

Si pones solo un video, la imagen para el selector se saca sola.

Para que un fondo use un tema de colores, agrégalo a `hypr-kora/temas/fondos.json`:

```json
{ "mi-fondo": "galaxia" }
```

Temas incluidos: `ceniza`, `cielo`, `dorado`, `dragon`, `galaxia`, `makima`, `tinta`. Para cambiarlo a mano: `~/.config/hypr-kora/scripts/tema.py <tema>`.

## Atajos

`Super` es la tecla de Windows. Todos están en [`hypr-kora/config/binds.lua`](hypr-kora/config/binds.lua).

### Apps

| Atajo | Acción |
|---|---|
| `Super` (soltar) | Lanzador de apps (fuzzel) |
| `Super + Enter` | Terminal (kitty) |
| `Super + W` | Navegador (Brave) |
| `Super + E` | Archivos (Dolphin) |
| `Super + C` | Editor de código (VSCodium) |
| `Super + T` | Editor de texto |
| `Tecla calculadora` | Calculadora |
| `Ctrl + Shift + Esc` | Monitor del sistema (btop) |

### Ventanas

| Atajo | Acción |
|---|---|
| `Super + Q` | Cerrar ventana |
| `Super + Esc` | Forzar cierre (clic en la ventana) |
| `Super + F` | Pantalla completa |
| `Super + H` | Maximizar (deja la barra) |
| `Super + Alt + Espacio` | Flotante / mosaico |
| `Super + J` | Ventana a media pantalla / completa |
| `Super + ← / →` | Ventana anterior / siguiente (fila tipo niri) |
| `Alt + Tab` | Cambiar de ventana |
| `Super + Shift + ← → ↑ ↓` | Mover la ventana |
| `Super + clic izquierdo` (arrastrar) | Mover ventana |
| `Super + clic derecho` (arrastrar) | Cambiar tamaño |
| `Super + Tab` | Ver todas las ventanas del workspace |

### Workspaces

| Atajo | Acción |
|---|---|
| `Super + 1…0` | Ir al workspace 1…10 |
| `Super + ↑ / ↓` | Workspace de arriba / abajo |
| `Super + Shift + 1…0` | Mandar la ventana al workspace 1…10 |
| `Super + Shift + Alt + 1…0` | Mandar la ventana sin seguirla |
| `Super + Ctrl + ← / →` | Workspace anterior / siguiente del monitor |
| `Super + Ctrl + Shift + ← / →` | Mover la ventana al workspace anterior / siguiente |
| `Super + Ctrl + ↓` | Primer workspace vacío |
| `Super + Shift + Tab` · `Super + rueda` | Vista de todos los workspaces con sus ventanas |
| `Super + Shift + rueda` | Mover la ventana a otro monitor |

### Espacios especiales (se abren encima y se esconden)

| Atajo | Espacio | Con `Shift`: mandar la ventana ahí |
|---|---|---|
| `Super + M` | Música (Spotify) | `Super + Shift + M` |
| `Super + D` | Discord | `Super + Shift + D` |
| `Super + O` | OBS | `Super + Shift + O` |
| `Super + G` | Juegos | `Super + Shift + G` |
| `Super + S` | Steam | `Super + Shift + S` |

### Escritorio

| Atajo | Acción |
|---|---|
| `Super + X` (o `Super + A`) | Centro de control y notificaciones |
| `Super + Shift + A` | Borrar todas las notificaciones |
| `Super + Shift + W` | Elegir wallpaper (panal de hexágonos: flechas/ratón + Enter, Esc cierra) |
| `Super + V` | Historial del portapapeles |
| `Super + P` | Selector de color (copia el hex) |
| `Impr` (`F10` en la laptop) / `Super + Impr` | Captura de área / pantalla completa (se guarda en `~/Imágenes/Capturas`; si ya hay una abierta, se ignora) |
| `Super + L` | Bloquear pantalla |
| `Super + Alt + C` | Menú: bloquear, cerrar sesión, suspender, reiniciar, apagar |
| `Super + Shift + B` | Recargar Waybar si se traba |
| `Super + +` / `Super + -` | Lupa (acercar / alejar) |
| Ratón sobre el reloj | Calendario: rueda = cambiar de mes, clic derecho = ver el año, clic izquierdo = segundos |
| `Alt + F6` | Ventiladores al máximo / automático (solo Alienware, con `~/.local/bin/ventiladores`) |

### Teclas de la laptop

Volumen, silenciar, micrófono, play/pausa, siguiente/anterior y brillo funcionan con sus teclas (también con la pantalla bloqueada).

### Gestos del touchpad

| Gesto | Acción |
|---|---|
| 3 dedos ← → | Recorrer ventanas |
| 3 dedos ↑ ↓ | Cambiar de workspace |
| Pellizco con 3 dedos | Vista de todos los workspaces (abrir / cerrar) |
| 4 dedos ↑ | Pantalla completa |
| 4 dedos ← | Flotante |

### En la barra

| Clic en… | Abre |
|---|---|
| Batería | Panel de batería y modo de energía (Ahorro / Balanceado / Rendimiento) |
| Engrane del centro de control | Ajustes: redes, bluetooth, sonido, apariencia, monitor del sistema y apps de CachyOS (actualizar, kernel, mantenimiento) |

Sin cargador, la pantalla baja sola a 60 Hz, el fondo se queda en imagen fija y se activa el modo ahorro. Al conectar el cargador regresa todo.

## Ajustarlo a tu equipo

Está hecho para mi laptop. Revisa esto:

| Archivo | Qué cambiar |
|---|---|
| `hypr-kora/config/monitors.lua` | Resolución, Hz y escala de tu pantalla (viene `2560x1600@240`, escala 1.25) |
| `hypr-kora/scripts/ahorro.sh` | Cambia a 60 Hz con batería: pon tu resolución o quítalo de `config/autostart.lua` |
| `hypr-kora/config/variables.lua` | Apps por defecto (navegador, archivos, editor…) |
| `hypr-kora/config/inputs.lua` | Distribución del teclado y touchpad |

Para revisar la config sin arrancar Hyprland:

```bash
Hyprland --verify-config -c ~/.config/hypr-kora/hyprland.lua
```

## Estructura

```
dotfiles/
├── instalar.sh      instalador (paquetes + enlaces + sesión)
├── hypr-kora/       Hyprland, Waybar, Quickshell, fuzzel, hyprlock, temas y scripts
├── kitty/           terminal kitty (bash siempre)
├── alacritty/       terminal alacritty (bash siempre)
├── bash/            .bashrc y .bash_profile
└── bin/             saludo de la terminal (terminal-logo)
```

## Mantenerlo al día

Las configs en tu home son **enlaces al repo**: lo que cambies en `~/.config/hypr-kora` ya está dentro de `~/dotfiles`.

```bash
cd ~/dotfiles
git add -A && git commit -m "lo que cambié"
git push        # subirlo
git pull        # bajar cambios en otra compu
```

## Desinstalar

Borra los enlaces (`~/.config/hypr-kora`, `~/.config/kitty`, `~/.config/alacritty`, `~/.bashrc`, `~/.bash_profile`) y regresa tus archivos desde `~/.dotfiles-respaldo/`. Para quitar la sesión de la pantalla de inicio:

```bash
sudo rm /usr/share/wayland-sessions/hyprland-kora.desktop
```

## Licencia

[MIT](LICENSE): úsalo, cópialo y cámbialo como quieras.
