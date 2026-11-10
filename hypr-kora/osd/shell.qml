// Indicador de volumen y brillo de Hyprland Kora (estilo Caelestia): un panel que sale de la
// orilla derecha de la pantalla (pegado a ella, con esquinas curvas hacia adentro donde se une),
// con dos barras verticales, volumen arriba y brillo abajo.
// Crece desde la orilla al cambiar cualquiera de los dos y se vuelve a meter solo;
// con el ratón encima no se esconde y las barras se pueden arrastrar (clic en el ícono de
// volumen = silenciar).
// El brillo lo avisan las teclas (binds.lua: ipc call osd brillo), así hypridle no lo dispara.
// Escucha a Pipewire directo, así que sale con las teclas, el panel o cualquier app.
// Colores en vivo de config/colors.lua (los reescribe tema.py).
// Probar:  qs -p ~/.config/hypr-kora/osd ipc call osd mostrar|brillo
import QtQuick
import QtQuick.Shapes
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

        width: 30
        height: 176

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
                anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 8 }
                text: barra.icono
                color: barra.valor > 0.12 && !barra.apagado ? root.fondo : root.crema
                font { family: root.iconos; pixelSize: 15 }
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

    // Medidas del panel
    readonly property int oreja: 24       // curva hacia adentro donde el panel se une con la orilla
    readonly property int esquina: 26     // esquinas redondas del lado de afuera
    readonly property real anchoPanel: columna.width + 40
    readonly property real altoPanel: columna.height + 36
    // Cuánto ha salido el panel (0 = metido en la orilla, 1 = afuera)
    property real salida_: root.visible_ ? 1 : 0
    Behavior on salida_ { NumberAnimation { duration: 340; easing.type: Easing.OutCubic } }

    PanelWindow {
        id: ventana
        visible: root.visible_ || root.salida_ > 0.001
        anchors.right: true                     // pegado a la orilla derecha, centrado en la altura
        implicitWidth: root.anchoPanel + 2
        implicitHeight: root.altoPanel + 2 * root.oreja
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "kora-osd"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        mask: Region { item: zona }

        // Zona que recibe el ratón: solo lo que ya salió del panel
        Item {
            id: zona
            x: parent.width - width
            y: root.oreja
            width: root.anchoPanel * root.salida_
            height: root.altoPanel
            HoverHandler { id: sobre; onHoveredChanged: if (hovered) ocultar.restart() }
        }

        // Forma: panel pegado a la orilla con "orejas" curvas arriba y abajo (tipo Caelestia)
        Shape {
            id: forma
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer
            readonly property real ancho: width
            readonly property real w: root.anchoPanel * root.salida_
            readonly property real e: Math.min(root.oreja, w)
            readonly property real r: Math.min(root.esquina, w / 2)
            readonly property real t: root.oreja                // arriba del panel
            readonly property real b: root.oreja + root.altoPanel  // abajo del panel

            ShapePath {
                fillColor: Qt.rgba(root.fondo.r, root.fondo.g, root.fondo.b, root.familiar ? 0.6 : 0.92)
                strokeColor: root.familiar ? Qt.rgba(1, 1, 1, 0.22) : Qt.rgba(root.acento.r, root.acento.g, root.acento.b, 0.4)
                strokeWidth: 1
                startX: forma.ancho; startY: forma.t - forma.e
                // oreja de arriba (curva hacia adentro)
                PathArc { x: forma.ancho - forma.e; y: forma.t; radiusX: forma.e; radiusY: forma.e; direction: PathArc.Clockwise }
                PathLine { x: forma.ancho - forma.w + forma.r; y: forma.t }
                PathArc { x: forma.ancho - forma.w; y: forma.t + forma.r; radiusX: forma.r; radiusY: forma.r; direction: PathArc.Counterclockwise }
                PathLine { x: forma.ancho - forma.w; y: forma.b - forma.r }
                PathArc { x: forma.ancho - forma.w + forma.r; y: forma.b; radiusX: forma.r; radiusY: forma.r; direction: PathArc.Counterclockwise }
                PathLine { x: forma.ancho - forma.e; y: forma.b }
                // oreja de abajo
                PathArc { x: forma.ancho; y: forma.b + forma.e; radiusX: forma.e; radiusY: forma.e; direction: PathArc.Clockwise }
                PathLine { x: forma.ancho; y: forma.t - forma.e }
            }
        }

        // Contenido: sale junto con el panel (recortado a lo que ya salió)
        Item {
            x: parent.width - root.anchoPanel * root.salida_
            y: root.oreja
            width: root.anchoPanel * root.salida_
            height: root.altoPanel
            clip: true
            opacity: Math.min(1, root.salida_ * 1.6)

            Column {
                id: columna
                x: 20
                anchors.verticalCenter: parent.verticalCenter
                spacing: 16

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
