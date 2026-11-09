// ¿Está prendido el modo Familiar? (scripts/familiar.sh crea/borra el archivo y luego recarga
// este Quickshell). En modo Familiar los paneles son más transparentes y sin desenfoque.
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: modo
    property bool familiar: false
    // Opacidad de los fondos: normal casi sólido / Familiar transparente como las ventanas
    function op(normal, transparente) { return familiar ? transparente : normal; }

    FileView {
        path: Quickshell.env("HOME") + "/.local/state/hypr-kora/familiar"
        printErrors: false
        onLoaded: modo.familiar = true
        onLoadFailed: modo.familiar = false
    }
}
