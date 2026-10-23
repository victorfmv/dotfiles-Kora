#!/usr/bin/env python3
# Puntos de workspaces para Waybar, en grupos de 5 como Caelestia:
# en el 1-5 se ven 1-5, en el 6 los puntos pasan a ser 6-10, etc.
import json, os, socket, subprocess

GRUPO = 5
ORO, BLANCO, GRIS = "#e44b43", "#d1dcef", "#39404c"
ICONOS = {"music": "\U000F04C7", "discord": "\U000F066F", "obs": "\U000F044B", "gaming": "\U000F02B4", "steam": "\U000F04D3"}


def hypr(cmd):
    return json.loads(subprocess.run(["hyprctl", cmd, "-j"], capture_output=True, text=True).stdout)


def pintar():
    activo = hypr("activeworkspace")["id"]
    usados = {w["id"]: w for w in hypr("workspaces")}
    inicio = (max(activo, 1) - 1) // GRUPO * GRUPO + 1

    puntos = []
    for i in range(inicio, inicio + GRUPO):
        if i == activo:
            puntos.append(f"<span color='{ORO}' size='12pt'></span>")
        elif i in usados and usados[i]["windows"] > 0:
            puntos.append(f"<span color='{BLANCO}' size='10pt'></span>")
        else:
            puntos.append(f"<span color='{GRIS}' size='10pt'></span>")

    especiales = [ICONOS.get(w["name"].removeprefix("special:"), "")
                  for w in usados.values() if w["name"].startswith("special:")]
    texto = "   ".join(puntos)
    if especiales:
        texto += "    " + "   ".join(f"<span color='{BLANCO}'>{e}</span>" for e in especiales)

    print(json.dumps({"text": texto, "tooltip": f"Workspace {activo}"}), flush=True)


pintar()
ruta = f"{os.environ['XDG_RUNTIME_DIR']}/hypr/{os.environ['HYPRLAND_INSTANCE_SIGNATURE']}/.socket2.sock"
s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
s.connect(ruta)
eventos = ("workspace", "focusedmon", "createworkspace", "destroyworkspace",
           "openwindow", "closewindow", "movewindow", "activespecial")
buf = b""
while True:
    buf += s.recv(4096)
    *lineas, buf = buf.split(b"\n")
    if any(l.split(b">>")[0].decode(errors="ignore").startswith(eventos) for l in lineas):
        pintar()
