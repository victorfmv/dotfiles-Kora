#!/usr/bin/env bash
# Vista general tipo niri: encoge todas las ventanas del workspace para verlas
# juntas y las regresa a pantalla completa.
#   vista.sh          -> alterna
#   vista.sh abrir    -> encoger (pellizco hacia adentro)
#   vista.sh cerrar   -> volver a completas (pellizco hacia afuera)
ESTADO="${XDG_RUNTIME_DIR:-/tmp}/kora-vista"

abrir()  { hyprctl dispatch 'hl.dsp.layout("fit all")' >/dev/null; touch "$ESTADO"; }
cerrar() {
    hyprctl dispatch 'hl.dsp.layout("colresize all 1.0")' >/dev/null
    hyprctl dispatch 'hl.dsp.layout("fit active")' >/dev/null
    rm -f "$ESTADO"
}

case "$1" in
    abrir)  abrir ;;
    cerrar) cerrar ;;
    *)      if [ -f "$ESTADO" ]; then cerrar; else abrir; fi ;;
esac
