#!/usr/bin/env bash
# Rayitas verticales que se mueven con la música (Waybar). Si no suena nada, se ocultan.
cfg="${XDG_RUNTIME_DIR:-/tmp}/kora-cava.conf"
cat > "$cfg" <<CFG
[general]
bars = 12
framerate = 30
sleep_timer = 2
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
    s = ""; total = 0
    for (i = 1; i < NF; i++) { s = s b[$i + 1]; total += $i }
    print (total == 0 ? "" : s)
    fflush()
}'
