#!/usr/bin/env python3
"""Cambia la paleta de colores de toda la config de Hyprland Kora.

    tema.py <nombre>     aplica temas/<nombre>.json (y recarga Waybar, Hyprland y Quickshell)
    tema.py              dice qué tema está puesto
    tema.py --base       re-escanea los colores (solo con el tema "dorado" puesto)

Cómo funciona: temas/base.json guarda todos los colores del tema dorado original.
Cada tema dice cómo transformarlos: los dorados ("acento") cambian de tono y los
cremas/cafés ("neutros") se tiñen de otro tono, respetando qué tan claros u oscuros son.
Para pasar de un tema a otro se convierte cada color del tema actual al del nuevo.
"""
import colorsys, json, os, re, subprocess, sys
from pathlib import Path

K = Path.home() / ".config/hypr-kora"
TEMAS = K / "temas"
ESTADO = Path.home() / ".local/state/hypr-kora/tema"
ARCHIVOS = ["config/colors.lua", "hyprlock.conf", "scripts/workspaces.py", "scripts/cava-waybar.sh", "waybar/config.jsonc",
            "waybar/style.css", "fuzzel/fuzzel.ini", "mako/config"] + \
           [str(p.relative_to(K)) for p in sorted((K / "centro").glob("*.qml"))] + \
           [str(p.relative_to(K)) for p in sorted((K / "overview").glob("*.qml"))]

HEX = re.compile(r"(?<![0-9A-Za-z_])(#?)([0-9a-fA-F]{6})(?=(?:[0-9a-fA-F]{2})?(?![0-9A-Za-z_]))")
QT = re.compile(r"Qt\.rgba\(\s*([\d.]+)\s*,\s*([\d.]+)\s*,\s*([\d.]+)\s*,")
INT = re.compile(r"(?<!Qt\.)\brgba?\(\s*(\d{1,3})\s*,\s*(\d{1,3})\s*,\s*(\d{1,3})\s*([,)])")


# ───────────── transformación de un color ─────────────
def transformar(rgb, tema, hexkey=None):
    """rgb en 0..1 del tema dorado -> rgb del tema dado."""
    if hexkey and hexkey in tema.get("especiales", {}):
        h = tema["especiales"][hexkey]
        return tuple(int(h[i:i + 2], 16) / 255 for i in (0, 2, 4))
    if tema.get("acento_h") is None:          # tema base: no cambia nada
        return rgb
    h, l, s = colorsys.rgb_to_hls(*rgb)
    grados = h * 360
    intensidad = max(rgb) - min(rgb)          # 0 = gris/blanco, 1 = color puro
    if intensidad >= 0.25 and 25 <= grados <= 55:      # dorados -> acento
        h = tema["acento_h"] / 360
        s = min(1, s * tema.get("acento_s", 1))
        l = min(1, max(0, l + tema.get("acento_l", 0)))
    elif s > 0 and 15 <= grados <= 60:        # cremas, cafés y grises cálidos -> neutros
        h = tema["neutro_h"] / 360
        s = min(1, s * tema.get("neutro_s", 1))
    return colorsys.hls_to_rgb(h, l, s)


def a_hex(rgb):
    return "".join(f"{round(max(0, min(1, c)) * 255):02x}" for c in rgb)


def tabla(base, tema):
    """Para cada color base: su versión en el tema (sin repetidos, para poder regresar)."""
    usados, t = {}, {"hex": {}, "qt": {}, "int": {}}
    for clase in ("hex", "qt", "int"):
        for k in base[clase]:
            if clase == "hex":
                rgb = tuple(int(k[i:i + 2], 16) / 255 for i in (0, 2, 4))
            elif clase == "qt":
                rgb = tuple(float(x) for x in k.split(","))
            else:
                rgb = tuple(int(x) / 255 for x in k.split(","))
            nuevo = transformar(rgb, tema, k if clase == "hex" else a_hex(rgb))
            if clase == "hex":
                v = a_hex(nuevo)
                # dos colores distintos no pueden quedar iguales: se mueve un poquito el azul
                while usados.get(("hex", v), k) != k:
                    v = v[:4] + f"{(int(v[4:], 16) + 1) % 256:02x}"
                usados[("hex", v)] = k
            elif clase == "qt":
                v = ",".join(f"{c:.3f}" for c in nuevo) if tema.get("acento_h") is not None else k
                v = norm_qt(v)
                while usados.get(("qt", v), k) != k:
                    p = [float(x) for x in v.split(",")]; p[2] = min(1, p[2] + 0.002); v = norm_qt(",".join(map(str, p)))
                usados[("qt", v)] = k
            else:
                v = ",".join(str(round(c * 255)) for c in nuevo)
                while usados.get(("int", v), k) != k:
                    p = v.split(","); p[2] = str((int(p[2]) + 1) % 256); v = ",".join(p)
                usados[("int", v)] = k
            t[clase][k] = v
    return t


def norm_qt(s):
    return ",".join(f"{float(x):.3f}".rstrip("0").rstrip(".") or "0" for x in s.split(","))


def fmt_qt(v):
    return ", ".join(v.split(","))


# ───────────── escanear / aplicar ─────────────
def escanear():
    base = {"hex": set(), "qt": set(), "int": set()}
    for f in ARCHIVOS:
        p = K / f
        if not p.exists():
            continue
        txt = p.read_text()
        base["hex"] |= {m.group(2).lower() for m in HEX.finditer(txt)}
        base["qt"] |= {norm_qt(",".join(m.groups())) for m in QT.finditer(txt)}
        base["int"] |= {",".join(m.groups()[:3]) for m in INT.finditer(txt)}
    base = {k: sorted(v) for k, v in base.items()}
    (TEMAS / "base.json").write_text(json.dumps(base, indent=1) + "\n")
    print(f"base: {sum(map(len, base.values()))} colores")


def cargar(nombre):
    return json.loads((TEMAS / f"{nombre}.json").read_text())


def aplicar(nuevo):
    actual = ESTADO.read_text().strip() if ESTADO.exists() else "dorado"
    if actual == nuevo:
        print(f"ya está puesto: {nuevo}")
        return False
    base = json.loads((TEMAS / "base.json").read_text())
    de, a = tabla(base, cargar(actual)), tabla(base, cargar(nuevo))
    mapa = {c: {de[c][k]: a[c][k] for k in base[c]} for c in de}

    def r_hex(m):
        v = mapa["hex"].get(m.group(2).lower())
        if v is None:
            return m.group(0)
        return m.group(1) + (v.upper() if m.group(2).isupper() else v)

    def r_qt(m):
        v = mapa["qt"].get(norm_qt(",".join(m.groups())))
        return m.group(0) if v is None else f"Qt.rgba({fmt_qt(v)},"

    def r_int(m):
        v = mapa["int"].get(",".join(m.groups()[:3]))
        if v is None:
            return m.group(0)
        pre = m.group(0)[:m.group(0).index("(") + 1]
        return pre + ", ".join(v.split(",")) + m.group(4)

    cambiados = 0
    for f in ARCHIVOS:
        p = K / f
        if not p.exists():
            continue
        txt = p.read_text()
        nuevo_txt = INT.sub(r_int, QT.sub(r_qt, HEX.sub(r_hex, txt)))
        if nuevo_txt != txt:
            p.write_text(nuevo_txt)
            cambiados += 1
    ESTADO.parent.mkdir(parents=True, exist_ok=True)
    ESTADO.write_text(nuevo + "\n")
    print(f"{actual} -> {nuevo}: {cambiados} archivos")
    return True


def recargar():
    # Quickshell (panel y vista de workspaces) se recarga solo al ver los archivos cambiar
    subprocess.run(["hyprctl", "reload"], stdout=subprocess.DEVNULL)
    # Waybar NO se reinicia (la barra desaparecía ~2 s): style.css se recarga solo
    # (reload_style_on_change), los puntos de workspaces releen sus colores con SIGUSR1
    # y las rayitas de cava los releen cada segundo.
    subprocess.run(["pkill", "-USR1", "-f", r"^python3 \S*scripts/workspaces\.py$"], stderr=subprocess.DEVNULL)


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print(ESTADO.read_text().strip() if ESTADO.exists() else "dorado")
    elif sys.argv[1] == "--base":
        escanear()
    elif aplicar(sys.argv[1]):
        recargar()
