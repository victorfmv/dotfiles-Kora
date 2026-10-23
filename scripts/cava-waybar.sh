#!/usr/bin/env bash
# Rayitas verticales que se mueven con la música (Waybar). Siempre visibles: en silencio quedan planas.
cfg="${XDG_RUNTIME_DIR:-/tmp}/kora-cava.conf"
cat > "$cfg" <<CFG
[general]
bars = 12
framerate = 30
sleep_timer = 0
[input]
method = pipewire
[output]
method = raw
raw_target = /dev/stdout
data_format = ascii
ascii_max_range = 7
bar_delimiter = 59
CFG
pkill -f "cava -p $cfg" 2>/dev/null
exec cava -p "$cfg" | awk -F';' -v OFS='' '
BEGIN { split("▁ ▂ ▃ ▄ ▅ ▆ ▇ █", b, " ") }
{
    s = ""
    for (i = 1; i < NF; i++) s = s b[$i + 1]
    print s
    fflush()
}'
