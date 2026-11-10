// Indicador de volumen y brillo de Hyprland Kora (estilo Caelestia): un panel pegado al borde
// derecho, centrado en la altura, con dos barras verticales (volumen y brillo) lado a lado.
// Sale deslizándose desde la orilla al cambiar cualquiera de los dos y se esconde solo;
// con el ratón encima no se esconde y las barras se pueden arrastrar (clic en el ícono de
// volumen = silenciar).
// El brillo lo avisan las teclas (binds.lua: ipc call osd brillo), así hypridle no lo dispara.
// Escucha a Pipewire directo, así que sale con las teclas, el panel o cualquier app.
// Colores en vivo de config/colors.lua (los reescribe tema.py).
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

    // Modo Familiar (scripts/familiar.sh): panel más transparente, burbuja de vidrio
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

    // Al cambiar de salida (Bluetooth, arranque) cambia el volumen sin que lo toques: no mostrar
    property bool listo: false
    onSalidaChanged: { listo = false; calma.restart(); }
    Timer { id: calma; interval: 600; onTriggered: root.listo = true }
    Component.onCompleted: { calma.start(); leerBrillo.running = true; }

    Connections {
        target: root.salida?.audio ?? null
        function onVolumeChanged() { if (root.listo && !root.arrastrando) root.mostrar(); }
        function onMutedChanged() { if (root.listo) root.mostrar(); }
    }

    // ── Brillo ──
    property real brillo: 0
    Process {
        id: leerBrillo
        property bool avisar: false
        command: ["brightnessctl", "-m"]
        stdout: StdioCollector {
            onStreamFinished: {
                const v = parseInt(text.split(",")[3]);
                if (!isNaN(v)) root.brillo = v / 100;
                if (leerBrillo.avisar) { leerBrillo.avisar = false; root.mostrar(); }
            }
        }
    }
    // Poner brillo arrastrando (sin saturar brightnessctl: uno a la vez, el último gana)
    property int brilloPedido: -1
    Process {
        id: ponerBrillo
        onExited: if (root.brilloPedido >= 0) root.aplicarBrillo()
    }
    function aplicarBrillo() {
        if (ponerBrillo.running) return;
        const n = brilloPedido; brilloPedido = -1;
        ponerBrillo.command = ["brightnessctl", "-q", "set", Math.max(1, n) + "%"];
        ponerBrillo.running = true;
    }

    // ── Mostrar / esconder ──
    property bool visible_: false
    property bool arrastrando: false
    function mostrar() { visible_ = true; ocultar.restart(); }
    Timer {
        id: ocultar
        interval: 1800
        onTriggered: if (!sobre.hovered && !root.arrastrando) root.visible_ = false; else restart()
    }

    IpcHandler {
        target: "osd"
        function mostrar(): void { root.mostrar(); }
        function brillo(): void { leerBrillo.avisar = true; leerBrillo.running = true; }
        function recargar(): void { Quickshell.reload(false); }
    }

    function iconoVolumen() {
        const p = Math.round(volumen * 100);
        if (mudo || p === 0) return "󰝟";
        if (p < 34) return "󰕿";
        if (p < 67) return "󰖀";
        return "󰕾";
    }
    function iconoBrillo() {
        const p = Math.round(brillo * 100);
        if (p < 34) return "󰃞";
        if (p < 67) return "󰃟";
        return "󰃠";
    }

    // Una barra vertical: se llena de abajo hacia arriba, con el ícono abajo y el número arriba
    component Barra: Item {
        id: barra
        property real valor: 0
        property bool apagado: false
        property string icono: ""
        signal cambiar(real v)
        signal tocarIcono()

        width: 46
        height: 214

        Text {
            id: numero
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            text: barra.apagado ? "—" : Math.round(barra.valor * 100)
            color: root.crema
            font { family: "Rubik"; pixelSize: 13; weight: Font.DemiBold; features: { "tnum": 1 } }
        }

        Rectangle {
            id: pista
            anchors { top: numero.bottom; topMargin: 10; bottom: parent.bottom; horizontalCenter: parent.horizontalCenter }
            width: parent.width
            radius: width / 2
            color: Qt.rgba(0, 0, 0, 0.32)
            border.width: 1
            border.color: Qt.rgba(root.crema.r, root.crema.g, root.crema.b, 0.08)
            clip: true

            // Relleno
            Rectangle {
                id: relleno
                anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                height: Math.max(parent.width, parent.height * barra.valor)
                radius: parent.radius
                opacity: barra.apagado ? 0.35 : 1
                gradient: Gradient {
                    GradientStop { position: 0.0; color: root.acento }
                    GradientStop { position: 1.0; color: root.acento2 }
                }
                Behavior on height { enabled: !root.arrastrando; NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
                Behavior on opacity { NumberAnimation { duration: 150 } }
                // Brillo de vidrio a la izquierda
                Rectangle {
                    anchors { left: parent.left; top: parent.top; bottom: parent.bottom; margins: 3 }
                    width: parent.width / 2 - 3
                    radius: width / 2
                    color: Qt.rgba(1, 1, 1, 0.16)
                }
            }

            // Arrastrar para cambiar
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                function valorEn(y) { return Math.max(0, Math.min(1, 1 - y / height)); }
                onPressed: mouse => { root.arrastrando = true; barra.cambiar(valorEn(mouse.y)); }
                onPositionChanged: mouse => { if (pressed) barra.cambiar(valorEn(mouse.y)); }
                onReleased: { root.arrastrando = false; root.mostrar(); }
                onWheel: wheel => barra.cambiar(Math.max(0, Math.min(1, barra.valor + (wheel.angleDelta.y > 0 ? 0.05 : -0.05))))
            }

            // Ícono abajo, dentro del relleno
            Text {
                anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 12 }
                text: barra.icono
                color: barra.valor > 0.12 && !barra.apagado ? root.fondo : root.crema
                font { family: root.iconos; pixelSize: 20 }
                Behavior on color { ColorAnimation { duration: 150 } }
                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -6
                    cursorShape: Qt.PointingHandCursor
                    onClicked: barra.tocarIcono()
                }
            }
        }
    }

    PanelWindow {
        id: ventana
        visible: root.visible_ || caja.opacity > 0
        anchors.right: true                     // solo a la derecha: queda centrado en la altura
        implicitWidth: caja.width + 24
        implicitHeight: caja.height + 20
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "kora-osd"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        mask: Region { item: caja }

        Rectangle {
            id: caja
            width: fila.width + 32
            height: fila.height + 32
            anchors.verticalCenter: parent.verticalCenter
            // Entra deslizándose desde la orilla derecha
            x: root.visible_ ? parent.width - width - 12 : parent.width + 4
            opacity: root.visible_ ? 1 : 0
            Behavior on x { NumberAnimation { duration: 280; easing.type: Easing.OutCubic } }
            Behavior on opacity { NumberAnimation { duration: 200 } }

            radius: 30
            color: Qt.rgba(root.fondo.r, root.fondo.g, root.fondo.b, root.familiar ? 0.5 : 0.86)
            border.width: root.familiar ? 0 : 1
            border.color: Qt.rgba(root.acento.r, root.acento.g, root.acento.b, 0.45)

            Vidrio { radio: parent.radius; activo: root.familiar }  // burbuja de vidrio (modo Familiar)

            HoverHandler { id: sobre; onHoveredChanged: if (hovered) ocultar.restart() }

            Row {
                id: fila
                anchors.centerIn: parent
                spacing: 14

                Barra {
                    valor: root.volumen
                    apagado: root.mudo
                    icono: root.iconoVolumen()
                    onCambiar: v => { if (root.salida?.audio) { root.salida.audio.muted = false; root.salida.audio.volume = v; } }
                    onTocarIcono: if (root.salida?.audio) root.salida.audio.muted = !root.salida.audio.muted
                }
                Barra {
                    valor: root.brillo
                    icono: root.iconoBrillo()
                    onCambiar: v => { root.brillo = v; root.brilloPedido = Math.round(v * 100); root.aplicarBrillo(); }
                }
            }
        }
    }
}
