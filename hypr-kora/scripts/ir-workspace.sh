#!/usr/bin/env bash
# Super + N: si hay un workspace especial abierto (Steam, Spotify, Discord…), lo cierra
# y luego va al workspace N. Sin esto, Hyprland cambia el de atrás y sigues en el especial.
esp=$(hyprctl monitors -j | jq -r '.[] | select(.focused) | .specialWorkspace.name')
if [ -n "$esp" ]; then
    hyprctl dispatch "hl.dsp.workspace.toggle_special(\"${esp#special:}\")" >/dev/null
fi
hyprctl dispatch "hl.dsp.focus({ workspace = $1 })" >/dev/null
