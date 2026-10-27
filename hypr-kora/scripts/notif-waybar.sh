#!/usr/bin/env bash
# Campanita de Waybar: lee el contador que escribe el centro (centro/shell.qml).
read -r n dnd < "${XDG_RUNTIME_DIR}/kora-notif" 2>/dev/null
n=${n:-0}
if [ "$dnd" = 1 ]; then
    printf '{"text":"󰂛","class":"dnd","tooltip":"No molestar"}\n'
elif [ "$n" -gt 0 ]; then
    printf '{"text":"󰂚 %s","class":"hay","tooltip":"%s notificaciones"}\n' "$n" "$n"
else
    printf '{"text":"󰂚","class":"vacio","tooltip":"Sin notificaciones"}\n'
fi
