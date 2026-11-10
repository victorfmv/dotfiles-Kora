// Lanzador de apps del modo Familiar (estilo Caelestia): sale de la orilla de abajo, al centro,
// pegado a ella (con curvas hacia adentro donde se une) y crece hacia arriba.
// Buscador abajo, lista de apps arriba (la mejor coincidencia queda junto al buscador).
// Teclas: escribir para buscar · ↑/↓ elegir · Enter abrir · Esc cerrar. Clic afuera también cierra.
// Recuerda qué apps abres más (~/.local/state/hypr-kora/lanzador.json) para ponerlas primero.
// Lo abre scripts/fuzzel.sh (Super, logo de la barra) cuando el modo Familiar está prendido.
// Probar:  qs -p ~/.config/hypr-kora/lanzador ipc call lanzador toggle
import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Widgets

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
    readonly property color crema: colorKora("fg", "#dde3dd")
    readonly property color fondo: colorKora("bg", "#111211")
    readonly property string iconos: "CaskaydiaCove Nerd Font"

    // ── Abrir / cerrar ──
    property bool abierto: false
    function abrir() { busqueda = ""; elegido = 0; abierto = true; }
    function cerrar() { abierto = false; }
    IpcHandler {
        target: "lanzador"
        function toggle(): void { root.abierto ? root.cerrar() : root.abrir(); }
        function open(): void { root.abrir(); }
        function close(): void { root.cerrar(); }
    }

    // ── Apps más usadas ──
    property var usos: ({})
    FileView {
        id: archivoUsos
        path: Quickshell.env("HOME") + "/.local/state/hypr-kora/lanzador.json"
        printErrors: false
        onLoaded: { try { root.usos = JSON.parse(text()) || {}; } catch (e) { root.usos = {}; } }
    }
    function lanzar(entrada) {
        if (!entrada) return;
        const u = Object.assign({}, usos);
        u[entrada.id] = (u[entrada.id] || 0) + 1;
        usos = u;
        archivoUsos.setText(JSON.stringify(u));
        entrada.execute();
        cerrar();
    }

    // ── Búsqueda ──
    property string busqueda: ""
    property int elegido: 0
    function quitarAcentos(t) { return (t || "").toLowerCase().normalize("NFD").replace(/[\u0300-\u036f]/g, ""); }
    readonly property var resultados: {
        const q = quitarAcentos(busqueda.trim());
        const lista = [];
        for (const e of DesktopEntries.applications.values) {
            if (e.noDisplay) continue;
            const nombre = quitarAcentos(e.name);
            let puntos = 0;
            if (q === "") puntos = 1;
            else if (nombre.startsWith(q)) puntos = 100;
            else if (nombre.split(/\s+/).some(p => p.startsWith(q))) puntos = 70;
            else if (nombre.includes(q)) puntos = 50;
            else if (quitarAcentos(e.genericName).includes(q)) puntos = 30;
            else if ((e.keywords || []).some(k => quitarAcentos(k).includes(q))) puntos = 20;
            else if (quitarAcentos(e.comment).includes(q)) puntos = 10;
            if (puntos > 0) lista.push({ e: e, p: puntos + Math.min(40, (usos[e.id] || 0) * 4) });
        }
        lista.sort((a, b) => b.p - a.p || a.e.name.localeCompare(b.e.name));
        return lista.slice(0, 40).map(x => x.e);
    }
    onResultadosChanged: elegido = 0

    // ── Medidas ──
    readonly property int oreja: 26
    readonly property int esquina: 28
    readonly property int anchoPanel: 600
    readonly property int filaAlto: 52
    readonly property int filas: 7
    readonly property int altoPanel: filas * filaAlto + 58 + 40
    property real salida_: abierto ? 1 : 0
    Behavior on salida_ { NumberAnimation { duration: 360; easing.type: Easing.OutCubic } }

    PanelWindow {
        id: ventana
        visible: root.abierto || root.salida_ > 0.001
        anchors.bottom: true                    // pegado a la orilla de abajo, al centro
        implicitWidth: root.anchoPanel + 2 * root.oreja
        implicitHeight: root.altoPanel + 2
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "kora-lanzador"
        WlrLayershell.keyboardFocus: root.abierto ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        mask: Region { item: zona }

        // Clic afuera cierra
        HyprlandFocusGrab {
            windows: [ventana]
            active: root.abierto
            onCleared: root.cerrar()
        }

        Item {
            id: zona
            x: root.oreja
            y: parent.height - height
            width: root.anchoPanel
            height: root.altoPanel * root.salida_
        }

        // Forma: panel pegado a la orilla de abajo con "orejas" curvas a los lados (tipo Caelestia)
        Shape {
            id: forma
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer
            readonly property real alto: height
            readonly property real x0: root.oreja
            readonly property real w: root.anchoPanel
            readonly property real h: root.altoPanel * root.salida_
            readonly property real e: Math.min(root.oreja, h)
            readonly property real r: Math.min(root.esquina, h / 2)

            ShapePath {
                fillColor: Qt.rgba(root.fondo.r, root.fondo.g, root.fondo.b, 0.84)
                strokeColor: Qt.rgba(1, 1, 1, 0.22)
                strokeWidth: 1
                startX: forma.x0 - forma.e; startY: forma.alto
                // oreja izquierda (curva hacia adentro)
                PathArc { x: forma.x0; y: forma.alto - forma.e; radiusX: forma.e; radiusY: forma.e; direction: PathArc.Counterclockwise }
                PathLine { x: forma.x0; y: forma.alto - forma.h + forma.r }
                PathArc { x: forma.x0 + forma.r; y: forma.alto - forma.h; radiusX: forma.r; radiusY: forma.r; direction: PathArc.Clockwise }
                PathLine { x: forma.x0 + forma.w - forma.r; y: forma.alto - forma.h }
                PathArc { x: forma.x0 + forma.w; y: forma.alto - forma.h + forma.r; radiusX: forma.r; radiusY: forma.r; direction: PathArc.Clockwise }
                PathLine { x: forma.x0 + forma.w; y: forma.alto - forma.e }
                // oreja derecha
                PathArc { x: forma.x0 + forma.w + forma.e; y: forma.alto; radiusX: forma.e; radiusY: forma.e; direction: PathArc.Counterclockwise }
                PathLine { x: forma.x0 - forma.e; y: forma.alto }
            }
        }

        // Contenido: sube junto con el panel (recortado a lo que ya salió)
        Item {
            x: root.oreja
            y: parent.height - height
            width: root.anchoPanel
            height: root.altoPanel * root.salida_
            clip: true

            Item {
                id: contenido
                anchors.bottom: parent.bottom
                width: parent.width
                height: root.altoPanel
                opacity: Math.min(1, root.salida_ * 1.5)

                // Buscador (abajo, junto a la orilla)
                Rectangle {
                    id: buscador
                    anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: 20; bottomMargin: 18 }
                    height: 50
                    radius: height / 2
                    color: Qt.rgba(0, 0, 0, 0.28)
                    border.width: 1
                    border.color: Qt.rgba(1, 1, 1, entrada.activeFocus ? 0.22 : 0.12)

                    Text {
                        id: lupa
                        anchors { left: parent.left; leftMargin: 20; verticalCenter: parent.verticalCenter }
                        text: "󰍉"
                        color: root.acento
                        font { family: root.iconos; pixelSize: 19 }
                    }
                    TextInput {
                        id: entrada
                        anchors { left: lupa.right; leftMargin: 14; right: parent.right; rightMargin: 20; verticalCenter: parent.verticalCenter }
                        text: root.busqueda
                        onTextChanged: root.busqueda = text
                        color: root.crema
                        selectionColor: Qt.rgba(root.acento.r, root.acento.g, root.acento.b, 0.4)
                        font { family: "Rubik"; pixelSize: 16 }
                        focus: root.abierto
                        clip: true
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: !entrada.text
                            text: "Buscar apps…"
                            color: Qt.rgba(root.crema.r, root.crema.g, root.crema.b, 0.4)
                            font: entrada.font
                        }
                        Keys.onEscapePressed: root.cerrar()
                        Keys.onReturnPressed: root.lanzar(root.resultados[root.elegido])
                        Keys.onEnterPressed: root.lanzar(root.resultados[root.elegido])
                        // La lista va de abajo hacia arriba: ↑ sube a la siguiente
                        Keys.onUpPressed: root.elegido = Math.min(root.resultados.length - 1, root.elegido + 1)
                        Keys.onDownPressed: root.elegido = Math.max(0, root.elegido - 1)
                        Keys.onTabPressed: root.elegido = (root.elegido + 1) % Math.max(1, root.resultados.length)
                    }
                    Connections {
                        target: root
                        function onAbiertoChanged() { if (root.abierto) { entrada.text = ""; entrada.forceActiveFocus(); } }
                    }
                }

                // Lista de apps (la mejor coincidencia abajo, junto al buscador)
                ListView {
                    id: lista
                    anchors { left: parent.left; right: parent.right; top: parent.top; bottom: buscador.top; margins: 14; topMargin: 20; bottomMargin: 10 }
                    model: root.resultados
                    verticalLayoutDirection: ListView.BottomToTop
                    currentIndex: root.elegido
                    clip: true
                    spacing: 2
                    highlightMoveDuration: 120
                    boundsBehavior: Flickable.StopAtBounds

                    highlight: Rectangle {
                        radius: 16
                        color: Qt.rgba(1, 1, 1, 0.09)
                        border.width: 1
                        border.color: Qt.rgba(1, 1, 1, 0.12)
                    }

                    delegate: Item {
                        id: fila
                        required property var modelData
                        required property int index
                        width: lista.width
                        height: root.filaAlto - 2

                        IconImage {
                            id: ico
                            anchors { left: parent.left; leftMargin: 14; verticalCenter: parent.verticalCenter }
                            implicitSize: 32
                            source: Quickshell.iconPath(fila.modelData.icon, "application-x-executable")
                            asynchronous: true
                        }
                        Column {
                            anchors { left: ico.right; leftMargin: 14; right: parent.right; rightMargin: 14; verticalCenter: parent.verticalCenter }
                            spacing: 1
                            Text {
                                width: parent.width
                                text: fila.modelData.name
                                color: root.crema
                                elide: Text.ElideRight
                                font { family: "Rubik"; pixelSize: 15; weight: fila.index === root.elegido ? Font.DemiBold : Font.Normal }
                            }
                            Text {
                                width: parent.width
                                visible: text !== ""
                                text: fila.modelData.comment || fila.modelData.genericName || ""
                                color: Qt.rgba(root.crema.r, root.crema.g, root.crema.b, 0.5)
                                elide: Text.ElideRight
                                font { family: "Rubik"; pixelSize: 12 }
                            }
                        }
                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: root.elegido = fila.index
                            onClicked: root.lanzar(fila.modelData)
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: root.resultados.length === 0
                        text: "Nada con «" + root.busqueda + "»"
                        color: Qt.rgba(root.crema.r, root.crema.g, root.crema.b, 0.5)
                        font { family: "Rubik"; pixelSize: 14 }
                    }
                }
            }
        }
    }
}
