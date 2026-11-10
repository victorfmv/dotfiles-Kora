// Indicador de volumen y brillo de Hyprland Kora (tipo Windows): una pastilla abajo al centro
// que aparece al subir/bajar/silenciar el volumen o cambiar el brillo y se esconde sola.
// El brillo lo avisan las teclas (binds.lua: ipc call osd brillo), así hypridle no lo dispara.
// Escucha a Pipewire directo, así que sale con las teclas, el panel o cualquier app.
// Colores en vivo de config/colors.lua (los reescribe tema.py). No recibe clics.
// Probar:  qs -p ~/.config/hypr-kora/osd ipc call osd mostrar|brillo
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pipewire

ShellRoot {
    id: root

    Connections {
        target: Quickshell
        function onReloadCompleted() { Quickshell.inhibitReloadPopup(); }
        function onReloadFailed() { Quickshell.inhibitReloadPopup(); }
    }

    // ── Colores del tema ──
    FileView {
        id: paleta
        path: Quickshell.env("HOME") + "/.config/hypr-kora/config/colors.lua"
        watchChanges: true
        onFileChanged: reload()
    }
    function colorKora(nombre, otro) {
        const m = paleta.text().match(new RegExp(nombre + "\\s*=\\s*\"rgba\\(([0-9a-fA-F]{6})"));
        return m ? "#" + m[1] : otro;
    }
    readonly property color acento: colorKora("accent", "#91bfa8")
    readonly property color acento2: colorKora("accent2", "#639a7e")
    readonly property color crema: colorKora("fg", "#dde3dd")
    readonly property color fondo: colorKora("bg", "#111211")
    readonly property string iconos: "CaskaydiaCove Nerd Font"

    // Modo Familiar (scripts/familiar.sh): pastilla más transparente y sin desenfoque
    property bool familiar: false
    FileView {
        path: Quickshell.env("HOME") + "/.local/state/hypr-kora/familiar"
        printErrors: false
        onLoaded: root.familiar = true
        onLoadFailed: root.familiar = false
    }

    // ── Audio ──
    readonly property var salida: Pipewire.defaultAudioSink
    PwObjectTracker { objects: [root.salida] }
    readonly property real volumen: Math.max(0, Math.min(1, salida?.audio?.volume ?? 0))
    readonly property bool mudo: salida?.audio?.muted ?? false
    readonly property int porcentaje: Math.round(volumen * 100)

    // Al cambiar de salida (Bluetooth, arranque) cambia el volumen sin que lo toques: no mostrar
    property bool listo: false
    onSalidaChanged: { listo = false; calma.restart(); }
    Timer { id: calma; interval: 600; onTriggered: root.listo = true }
    Component.onCompleted: calma.start()

    Connections {
        target: root.salida?.audio ?? null
        function onVolumeChanged() { if (root.listo) { root.modo = "volumen"; root.mostrar(); } }
        function onMutedChanged() { if (root.listo) { root.modo = "volumen"; root.mostrar(); } }
    }

    // ── Brillo ──
    property real brillo: 0
    Process {
        id: leerBrillo
        command: ["brightnessctl", "-m"]
        stdout: StdioCollector {
            onStreamFinished: {
                const v = parseInt(text.split(",")[3]);
                if (!isNaN(v)) { root.brillo = v / 100; root.modo = "brillo"; root.mostrar(); }
            }
        }
    }

    // ── Qué se muestra ──
    property string modo: "volumen"
    readonly property bool esBrillo: modo === "brillo"
    readonly property real valor: esBrillo ? brillo : volumen
    readonly property bool apagado: !esBrillo && mudo
    readonly property int numero: Math.round(valor * 100)

    property bool visible_: false
    function mostrar() { visible_ = true; ocultar.restart(); }
    Timer { id: ocultar; interval: 1600; onTriggered: root.visible_ = false }

    IpcHandler {
        target: "osd"
        function mostrar(): void { root.modo = "volumen"; root.mostrar(); }
        function brillo(): void { leerBrillo.running = true; }
        function recargar(): void { Quickshell.reload(false); }
    }

    function icono() {
        if (esBrillo) {
            if (numero < 34) return "󰃞";
            if (numero < 67) return "󰃟";
            return "󰃠";
        }
        if (mudo || porcentaje === 0) return "󰝟";
        if (porcentaje < 34) return "󰕿";
        if (porcentaje < 67) return "󰖀";
        return "󰕾";
    }

    PanelWindow {
        id: ventana
        visible: root.visible_ || caja.opacity > 0
        anchors.bottom: true
        margins.bottom: 70
        implicitWidth: 360
        implicitHeight: 90
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "kora-osd"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        mask: Region {}          // los clics pasan de largo

        Rectangle {
            id: caja
            width: 340
            height: 62
            anchors.horizontalCenter: parent.horizontalCenter
            y: root.visible_ ? 14 : 34
            opacity: root.visible_ ? 1 : 0
            scale: root.visible_ ? 1 : 0.94
            Behavior on y { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
            Behavior on opacity { NumberAnimation { duration: 180 } }
            Behavior on scale { NumberAnimation { duration: 240; easing.type: Easing.OutBack } }

            radius: height / 2
            color: Qt.rgba(root.fondo.r, root.fondo.g, root.fondo.b, root.familiar ? 0.5 : 0.86)
            border.width: root.familiar ? 0 : 1
            border.color: Qt.rgba(root.acento.r, root.acento.g, root.acento.b, 0.45)

            Vidrio { radio: parent.radius; activo: root.familiar }  // burbuja de vidrio (modo Familiar)

            // Ícono
            Text {
                id: ico
                anchors { left: parent.left; leftMargin: 22; verticalCenter: parent.verticalCenter }
                width: 26
                text: root.icono()
                color: root.apagado ? Qt.rgba(root.crema.r, root.crema.g, root.crema.b, 0.45) : root.acento
                font { family: root.iconos; pixelSize: 22 }
            }

            // Número
            Text {
                id: num
                anchors { right: parent.right; rightMargin: 22; verticalCenter: parent.verticalCenter }
                width: 34
                horizontalAlignment: Text.AlignRight
                text: root.apagado ? "—" : root.numero
                color: root.crema
                font { pixelSize: 16; weight: Font.DemiBold; features: { "tnum": 1 } }
            }

            // Barra
            Rectangle {
                id: pista
                anchors {
                    left: ico.right; leftMargin: 14
                    right: num.left; rightMargin: 14
                    verticalCenter: parent.verticalCenter
                }
                height: 10
                radius: height / 2
                color: Qt.rgba(0, 0, 0, 0.35)
                border.width: 1
                border.color: Qt.rgba(root.crema.r, root.crema.g, root.crema.b, 0.08)

                Rectangle {
                    anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
                    width: root.valor > 0 ? Math.max(parent.height, parent.width * root.valor) : 0
                    radius: parent.radius
                    opacity: root.apagado ? 0.35 : 1
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: root.acento2 }
                        GradientStop { position: 1.0; color: root.acento }
                    }
                    Behavior on width { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
                    Behavior on opacity { NumberAnimation { duration: 150 } }
                    // Brillo arriba
                    Rectangle {
                        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 2 }
                        height: parent.height / 2 - 2
                        radius: height / 2
                        color: Qt.rgba(1, 1, 1, 0.18)
                    }
                }
            }
        }
    }
}
