#!/usr/bin/env python3
# Ventana enfocada para Waybar: ícono + título. A diferencia de "hyprland/window",
# también sigue a las ventanas de los workspaces especiales (Steam, música, juegos…).
import html, json, os, socket, subprocess

LARGO = 26
ICONOS = {  # clase (en minúsculas, empieza con) -> ícono Nerd Font
    "kitty": "", "foot": "", "alacritty": "",
    "brave": "", "firefox": "", "chromium": "",
    "steam": "", "steam_app": "\U000F0297", "gamescope": "\U000F0297",
    "spotify": "", "vesktop": "", "discord": "",
    "com.obsproject": "\U000F044B", "obs": "\U000F044B",
    "codium": "\U000F0A1E", "code": "\U000F0A1E", "vscodium": "\U000F0A1E",
    "org.kde.dolphin": "", "dolphin": "", "nautilus": "",
    "org.gnome.texteditor": "", "mpv": "", "vlc": "\U000F057C",
}


def icono(clase):
    c = clase.lower()
    for k in sorted(ICONOS, key=len, reverse=True):
        if c.startswith(k):
            return ICONOS[k]
    return ""  # ventana genérica


def pintar():
    try:
        w = json.loads(subprocess.run(["hyprctl", "activewindow", "-j"],
                                      capture_output=True, text=True).stdout or "{}")
    except Exception:
        w = {}
    titulo = (w.get("title") or "").strip()
    if not w.get("class") and not titulo:
        texto, tip = "\U000F01C4  Escritorio", "Escritorio"
    else:
        corto = titulo if len(titulo) <= LARGO else titulo[:LARGO - 1] + "…"
        texto = f"{icono(w.get('class', ''))}  {html.escape(corto or w.get('class', ''))}"
        tip = html.escape(titulo)
    print(json.dumps({"text": texto, "tooltip": tip}), flush=True)


pintar()
ruta = f"{os.environ['XDG_RUNTIME_DIR']}/hypr/{os.environ['HYPRLAND_INSTANCE_SIGNATURE']}/.socket2.sock"
s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
s.connect(ruta)
eventos = (b"activewindow>>", b"windowtitle", b"closewindow", b"activespecial", b"workspace>>")
buf = b""
while True:
    datos = s.recv(4096)
    if not datos:
        break
    buf += datos
    *lineas, buf = buf.split(b"\n")
    if any(l.startswith(eventos) for l in lineas):
        pintar()
