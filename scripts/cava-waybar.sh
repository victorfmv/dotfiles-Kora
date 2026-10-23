#!/usr/bin/env bash
# Rayitas de música estilo espejo para Waybar: cada barra crece desde la línea
# del centro hacia arriba y abajo, y el dibujo es simétrico (graves al centro).
# Truco: cada barra es un "┃" de distinto tamaño, subido (rise) para que su centro
# quede siempre a la misma altura y con letter_spacing para que todas ocupen lo mismo.
# Medidas de CaskaydiaCove Nerd Font Mono: ascent 0.928, descent 0.235, avance 0.586 em.
BARRAS=16          # por lado (en total se ven el doble)
cfg="${XDG_RUNTIME_DIR:-/tmp}/kora-cava.conf"
cat > "$cfg" <<CFG
[general]
bars = $BARRAS
framerate = 30
sleep_timer = 0
[input]
method = pipewire
[output]
method = raw
raw_target = /dev/stdout
data_format = ascii
ascii_max_range = 100
bar_delimiter = 59
CFG
pkill -f "cava -p $cfg" 2>/dev/null
exec cava -p "$cfg" | awk -F';' '
BEGIN {
    smax = 15; smin = 1.6       # tamaño (pt) de la barra más alta y de la más baja
    paso = 3.4                  # espacio fijo por barra (pt)
    centro = (0.928 - 0.235) / 2
    avance = 0.586
}
function barra(v,   s, t, r, g, b) {
    t = v / 100
    s = smin + (smax - smin) * t
    # color: dorado apagado -> dorado brillante según la altura
    r = int(138 + (245 - 138) * t); g = int(106 + (207 - 106) * t); b = int(42 + (122 - 42) * t)
    # Las altas con línea fina y las bajas con línea gruesa: así todas se ven del mismo grosor
    return sprintf("<span font_family=\"CaskaydiaCove Nerd Font Mono\" size=\"%d\" rise=\"%d\" letter_spacing=\"%d\" foreground=\"#%02x%02x%02x\">%s</span>",
        s * 1024, centro * (smax - s) * 1024, (paso - avance * s) * 1024, r, g, b, (s > 6.5 ? "│" : "┃"))
}
{
    n = NF - 1
    # Ancla invisible al tamaño máximo para que la altura de la línea no brinque
    s = sprintf("<span size=\"%d\">\342\200\213</span>", smax * 1024)
    for (i = n; i >= 1; i--) s = s barra($i)     # mitad izquierda (espejo)
    for (i = 1; i <= n; i++) s = s barra($i)     # mitad derecha
    print s
    fflush()
}'
