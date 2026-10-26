#!/usr/bin/env bash
# Rayitas de música estilo espejo para Waybar: cada barra crece desde la línea
# del centro hacia arriba y abajo, y el dibujo es simétrico (graves al centro).
# Truco: cada barra es un "┃" de distinto tamaño, subido (rise) para que su centro
# quede siempre a la misma altura y con letter_spacing para que todas ocupen lo mismo.
# Medidas de CaskaydiaCove Nerd Font Mono: ascent 0.928, descent 0.235, avance 0.586 em.
BARRAS=28          # por lado (en total se ven el doble)
cfg="${XDG_RUNTIME_DIR:-/tmp}/kora-cava.conf"
cat > "$cfg" <<CFG
[general]
bars = $BARRAS
framerate = 30
sleep_timer = 0
[input]
method = pipewire
[output]
channels = mono
mono_option = average
method = raw
raw_target = /dev/stdout
data_format = ascii
ascii_max_range = 100
bar_delimiter = 59
CFG
# Colores de las rayitas: apagado (bajas) -> brillante (altas). scripts/tema.py los cambia con el tema.
APAGADO="317097"
BRILLANTE="90cdf4"
pkill -f "cava -p $cfg" 2>/dev/null
# awk relee APAGADO/BRILLANTE de este archivo cada segundo: al cambiar de tema
# las rayitas cambian de color solas, sin reiniciar cava ni la barra.
exec cava -p "$cfg" | awk -F';' -v yo="$(readlink -f "$0")" -v ap="$APAGADO" -v br="$BRILLANTE" '
function colores(a, b) {
    r1 = strtonum("0x" substr(a, 1, 2)); g1 = strtonum("0x" substr(a, 3, 2)); b1 = strtonum("0x" substr(a, 5, 2))
    r2 = strtonum("0x" substr(b, 1, 2)); g2 = strtonum("0x" substr(b, 3, 2)); b2 = strtonum("0x" substr(b, 5, 2))
}
function releer(   l, a, b) {
    a = ap; b = br
    while ((getline l < yo) > 0) {
        if (l ~ /^APAGADO="/) a = substr(l, 10, 6)
        if (l ~ /^BRILLANTE="/) b = substr(l, 12, 6)
    }
    close(yo)
    ap = a; br = b; colores(a, b)
}
BEGIN {
    smax = 15; smin = 2.4       # tamaño (pt) de la barra más alta y de la más baja
    paso = 3.5                  # espacio fijo por barra (pt): 56 barras llenan la pastilla (230 px)
    centro = (0.928 - 0.235) / 2
    avance = 0.586
    colores(ap, br)
}
function barra(v,   s, t, r, g, b) {
    t = v / 100
    s = smin + (smax - smin) * t
    # color: apagado -> brillante según la altura
    r = int(r1 + (r2 - r1) * t); g = int(g1 + (g2 - g1) * t); b = int(b1 + (b2 - b1) * t)
    # Las altas con línea fina y las bajas con línea gruesa: así todas se ven del mismo grosor
    return sprintf("<span font_family=\"CaskaydiaCove Nerd Font Mono\" size=\"%d\" rise=\"%d\" letter_spacing=\"%d\" foreground=\"#%02x%02x%02x\">%s</span>",
        s * 1024, centro * (smax - s) * 1024, (paso - avance * s) * 1024, r, g, b, (s > 6.5 ? "│" : "┃"))
}
{
    if (++cuadros % 30 == 0) releer()
    n = NF - 1
    # Ancla invisible al tamaño máximo para que la altura de la línea no brinque
    s = sprintf("<span size=\"%d\">\342\200\213</span>", smax * 1024)
    for (i = n; i >= 1; i--) s = s barra($i)     # mitad izquierda (espejo)
    for (i = 1; i <= n; i++) s = s barra($i)     # mitad derecha
    print s
    fflush()
}'
