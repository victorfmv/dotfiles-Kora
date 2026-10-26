#!/usr/bin/env python3
"""Pone en la pantalla de inicio (noctalia-greeter) el wallpaper y los colores del tema actual.

    greeter-sync.py      lo llama wallpaper.sh cada vez que cambia el fondo

Escribe ~/.local/state/hypr-kora/greeter/{greeter.toml,wallpaper.png}.
/var/lib/noctalia-greeter/greeter.toml es un enlace a ese greeter.toml (lo crea
scripts/instalar-greeter.sh una sola vez con sudo), así que no hace falta sudo aquí.
"""
import importlib.util, json, subprocess
from pathlib import Path

K = Path.home() / ".config/hypr-kora"
ESTADO = Path.home() / ".local/state/hypr-kora"
SALIDA = ESTADO / "greeter"

# Paleta del greeter escrita en la versión del tema base (igual que el resto de la config);
# tema.py la convierte a los colores del tema que va con el wallpaper.
PALETA_BASE = {
    "primary": "e6b450", "on_primary": "271900",
    "secondary": "b8862b", "on_secondary": "271900",
    "tertiary": "f08a78", "on_tertiary": "2b1208",
    "error": "ff6b6b", "on_error": "2b0505",
    "surface": "14120f", "on_surface": "f5ead6",
    "surface_variant": "1f1b15", "on_surface_variant": "b8a88a",
    "outline": "5c4a26", "shadow": "000000",
    "hover": "e6b450", "on_hover": "271900",
}

spec = importlib.util.spec_from_file_location("tema", K / "scripts/tema.py")
tema_py = importlib.util.module_from_spec(spec)
spec.loader.exec_module(tema_py)


def main():
    img = Path((ESTADO / "wallpaper").read_text().strip())
    nombre = (ESTADO / "tema").read_text().strip() if (ESTADO / "tema").exists() else "dorado"
    tema = json.loads((K / "temas" / f"{nombre}.json").read_text())

    paleta = {}
    for clave, h in PALETA_BASE.items():
        rgb = tuple(int(h[i:i + 2], 16) / 255 for i in (0, 2, 4))
        paleta[clave] = "#" + tema_py.a_hex(tema_py.transformar(rgb, tema, h))

    SALIDA.mkdir(parents=True, exist_ok=True)
    if img.is_file():
        # 2560 px basta para la pantalla de inicio y carga más rápido que el original 4K
        subprocess.run(["magick", str(img), "-resize", "2560x>", str(SALIDA / "wallpaper.tmp.png")], check=True)
        (SALIDA / "wallpaper.tmp.png").replace(SALIDA / "wallpaper.png")

    lineas = [
        f"# Generado por ~/.config/hypr-kora/scripts/greeter-sync.py (tema: {nombre}). No editar a mano.",
        "",
        "[user]",
        'default = "kora"',
        "",
        "[appearance]",
        'scheme = "Synced"',
        'password_style = "random"',
        "hide_logo = true",
        'power_buttons_position = "bottom-right"',
        'scheme_selector_position = "hidden"',
        'theme_mode = "dark"',
        "corner_radius_scale = 1.4",
        'font_family = "Rubik"',
        "",
        "[appearance.palette]",
        *(f'{k} = "{v}"' for k, v in paleta.items()),
        "",
        "[appearance.wallpaper]",
        f'path = "{SALIDA / "wallpaper.png"}"',
        'fill_mode = "crop"',
        f'fill_color = "{paleta["surface"]}"',
        "",
        "[clock]",
        "enabled = true",
        'position = "above-panel"',
        'time_format = "%I:%M %p"',
        'date_format = "%A %d de %B"',
        "time_font_size = 64",
        "date_font_size = 16",
        "",
        "[keyboard]",
        'layout = "latam"',
        "numlock = true",
        "",
        "[idle]",
        "timeout = 300",
        "",
    ]
    tmp = SALIDA / "greeter.toml.tmp"
    tmp.write_text("\n".join(lineas))
    tmp.replace(SALIDA / "greeter.toml")
    print(f"greeter: tema {nombre}, fondo {img.name}")


if __name__ == "__main__":
    main()
