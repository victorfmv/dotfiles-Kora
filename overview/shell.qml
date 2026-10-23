// Vista de workspaces de Hyprland Kora (tipo niri): alejamiento con los 5
// workspaces del grupo actual apilados en vertical y sus ventanas en fila.
// Al abrir, la ventana actual se encoge desde su lugar real; al elegir una,
// la "cámara" se acerca a ella hasta llenar la pantalla.
// Abrir/cerrar:  ~/.config/hypr-kora/scripts/overview.sh [toggle|open|close]
// Clic en ventana = ir a ella · clic en un workspace = ir ahí · ↑↓ + Enter · 1-9 · Esc cierra
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

ShellRoot {
    id: root

    readonly property color oro: "#e6b450"
    readonly property color crema: "#ece4d4"
    readonly property color gris: "#6b6255"

    readonly property int grupo: 5
    property bool abierto: false     // ventana de la vista visible
    property bool saliendo: false
    property int seleccion: 1
    property int grupoInicio: 1

    readonly property var monitor: Hyprland.focusedMonitor
    readonly property int activo: monitor?.activeWorkspace?.id ?? 1

    // Progreso de la animación: 0 = pantalla normal, 1 = vista alejada
    property real t: 0
    // Objetivo del acercamiento: miniatura (o, en coordenadas de la vista) <-> ventana real (r)
    property real ox: 0; property real oy: 0; property real ow: 1
    property real rx: 0; property real ry: 0; property real rw: 1
    readonly property real s0: rw / Math.max(1, ow)

    property var miniaturas: ({})    // address -> Item
    property var filas: ({})         // workspace id -> Item

    NumberAnimation {
        id: anim
        target: root; property: "t"
        onFinished: if (root.t === 0) { root.abierto = false; root.saliendo = false; }
    }

    function animarA(valor, ms, curva) {
        anim.stop();
        anim.from = t; anim.to = valor; anim.duration = ms; anim.easing.type = curva;
        anim.start();
    }

    function addr(t) { return t.address.startsWith("0x") ? t.address : "0x" + t.address; }

    // Ventanas de un workspace, de izquierda a derecha (orden de la fila scrolling)
    function ventanasDe(id) {
        return Hyprland.toplevels.values
            .filter(t => t.workspace?.id === id && !(t.lastIpcObject?.floating ?? false))
            .sort((a, b) => (a.lastIpcObject?.at?.[0] ?? 0) - (b.lastIpcObject?.at?.[0] ?? 0));
    }

    // La ventana que se ve en pantalla de un workspace: la enfocada o la más cercana al borde izquierdo
    function ventanaVisible(id) {
        const vs = ventanasDe(id);
        if (!vs.length) return null;
        const enfocada = vs.find(v => v.activated);
        if (enfocada) return enfocada;
        const mx = vista.screen?.x ?? 0;
        return vs.reduce((a, b) => Math.abs((a.lastIpcObject?.at?.[0] ?? 0) - mx) <= Math.abs((b.lastIpcObject?.at?.[0] ?? 0) - mx) ? a : b);
    }

    // Fija el objetivo del zoom: la miniatura de esa ventana <-> su lugar real en pantalla
    function apuntarA(toplevel, wsId) {
        const item = toplevel ? miniaturas[addr(toplevel)] : null;
        const ipc = toplevel?.lastIpcObject;
        if (item && ipc?.at && ipc?.size) {
            const p = item.mapToItem(escena, 0, 0);
            ox = p.x; oy = p.y; ow = item.width;
            rx = ipc.at[0] - (vista.screen?.x ?? 0);
            ry = ipc.at[1] - (vista.screen?.y ?? 0);
            rw = ipc.size[0];
            return;
        }
        // Workspace vacío: la fila entera se expande a toda la pantalla
        const fila = filas[wsId];
        if (fila) {
            const p = fila.mapToItem(escena, 0, 0);
            ox = p.x; oy = p.y; ow = fila.width;
            rx = 0; ry = (vista.height - fila.height * vista.width / fila.width) / 2; rw = vista.width;
        }
    }

    function abrir() {
        if (abierto && !saliendo) return;
        Hyprland.refreshWorkspaces();
        Hyprland.refreshToplevels();
        seleccion = Math.max(activo, 1);
        grupoInicio = Math.floor((seleccion - 1) / grupo) * grupo + 1;
        saliendo = false;
        if (!abierto) t = 0;
        abierto = true;
        // Esperar a que se acomoden las miniaturas antes de medirlas
        Qt.callLater(() => Qt.callLater(() => {
            apuntarA(ventanaVisible(activo), activo);
            animarA(1, 420, Easing.OutQuart);
        }));
    }

    // Cerrar acercándose a una ventana (o al workspace) y luego ir ahí
    function salirA(toplevel, wsId) {
        if (!abierto || saliendo) return;
        saliendo = true;
        apuntarA(toplevel, wsId);
        if (toplevel)
            Hyprland.dispatch(`hl.dsp.focus({ window = "address:${addr(toplevel)}" })`);
        else if (wsId !== activo)
            Hyprland.dispatch(`hl.dsp.focus({ workspace = ${wsId} })`);
        animarA(0, 340, Easing.InOutCubic);
    }
    function cerrar() { salirA(ventanaVisible(activo), activo); }
    function irAWorkspace(id) { salirA(ventanaVisible(id), id); }
    function alternar() { (abierto && !saliendo) ? cerrar() : abrir(); }

    IpcHandler {
        target: "overview"
        function toggle(): void { root.alternar(); }
        function open(): void { root.abrir(); }
        function close(): void { root.cerrar(); }
    }

    PanelWindow {
        id: vista
        visible: root.abierto
        screen: Quickshell.screens.find(s => s.name === root.monitor?.name) ?? Quickshell.screens[0]
        color: "transparent"
        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "kora-overview"
        WlrLayershell.keyboardFocus: root.abierto && !root.saliendo ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        readonly property real altoFila: (height - 140) / root.grupo

        // Fondo oscuro; clic afuera cierra
        Rectangle {
            anchors.fill: parent
            opacity: root.t
            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.rgba(0.05, 0.045, 0.035, 0.93) }
                GradientStop { position: 0.5; color: Qt.rgba(0.035, 0.03, 0.025, 0.90) }
                GradientStop { position: 1.0; color: Qt.rgba(0.06, 0.05, 0.03, 0.93) }
            }
            MouseArea { anchors.fill: parent; onClicked: root.cerrar() }
        }

        Item {
            id: escena
            anchors.fill: parent
            focus: true

            // La "cámara": a t=0 la miniatura objetivo cubre exactamente la ventana real
            transform: [
                Scale {
                    xScale: root.s0 + (1 - root.s0) * root.t
                    yScale: root.s0 + (1 - root.s0) * root.t
                },
                Translate {
                    x: (root.rx - root.ox * root.s0) * (1 - root.t)
                    y: (root.ry - root.oy * root.s0) * (1 - root.t)
                }
            ]

            Keys.onPressed: e => {
                if (e.key === Qt.Key_Escape) root.cerrar();
                else if (e.key === Qt.Key_Up || e.key === Qt.Key_K) root.seleccion = Math.max(root.grupoInicio, root.seleccion - 1);
                else if (e.key === Qt.Key_Down || e.key === Qt.Key_J) root.seleccion = Math.min(root.grupoInicio + root.grupo - 1, root.seleccion + 1);
                else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter || e.key === Qt.Key_Space) root.irAWorkspace(root.seleccion);
                else if (e.key >= Qt.Key_1 && e.key <= Qt.Key_9) root.irAWorkspace(e.key - Qt.Key_0);
                else return;
                e.accepted = true;
            }
            Connections {
                target: root
                function onAbiertoChanged() { if (root.abierto) escena.forceActiveFocus(); }
            }

            // Marco dorado que se desliza entre workspaces
            Rectangle {
                x: columna.x - 4
                y: columna.y + (root.seleccion - root.grupoInicio) * (vista.altoFila + columna.spacing) - 4
                width: columna.width + 8
                height: vista.altoFila + 8
                radius: 24
                color: "transparent"
                border.width: 2
                border.color: root.oro
                opacity: root.t
                Behavior on y { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
            }

            Column {
                id: columna
                anchors.centerIn: parent
                spacing: 20

                Repeater {
                    model: root.grupo

                    // Un workspace = una fila
                    Rectangle {
                        id: fila
                        required property int index
                        readonly property int wsId: root.grupoInicio + index
                        readonly property bool esActivo: wsId === root.activo
                        readonly property bool esSeleccion: wsId === root.seleccion
                        readonly property var ventanas: root.abierto ? root.ventanasDe(wsId) : []

                        Component.onCompleted: root.filas[wsId] = fila
                        onWsIdChanged: root.filas[wsId] = fila

                        width: vista.width * 0.86
                        height: vista.altoFila
                        radius: 20
                        color: esSeleccion ? Qt.rgba(0.13, 0.11, 0.08, 0.96) : Qt.rgba(0.09, 0.08, 0.07, 0.94)
                        border.width: 1
                        border.color: Qt.rgba(1, 1, 1, 0.05)
                        Behavior on color { ColorAnimation { duration: 180 } }

                        // Entrada escalonada: las filas aparecen una tras otra
                        readonly property real retraso: Math.min(0.6, Math.abs(wsId - root.activo) * 0.12)
                        opacity: esActivo ? 1 : Math.max(0, Math.min(1, (root.t - retraso) / (1 - retraso)))

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            onEntered: root.seleccion = fila.wsId
                            onClicked: root.irAWorkspace(fila.wsId)
                        }

                        // Punto + número a la izquierda, como la barra
                        Column {
                            anchors { left: parent.left; leftMargin: 24; verticalCenter: parent.verticalCenter }
                            spacing: 8
                            opacity: root.t
                            Rectangle {
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: fila.esActivo ? 14 : 10; height: width; radius: width / 2
                                color: fila.esActivo ? root.oro : (fila.ventanas.length ? root.crema : root.gris)
                            }
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: fila.wsId
                                color: fila.esSeleccion ? root.oro : root.gris
                                font { family: "Rubik"; pixelSize: 14; bold: true }
                                Behavior on color { ColorAnimation { duration: 180 } }
                            }
                        }

                        Text {
                            visible: fila.ventanas.length === 0
                            anchors.centerIn: parent
                            text: "vacío"
                            color: root.gris
                            opacity: root.t
                            font { family: "Rubik"; pixelSize: 15; italic: true }
                        }

                        // Ventanas en fila (proporción real de cada ventana)
                        Flickable {
                            anchors { fill: parent; leftMargin: 70; rightMargin: 18; topMargin: 12; bottomMargin: 12 }
                            contentWidth: filaVentanas.width
                            clip: root.t > 0.98
                            boundsBehavior: Flickable.StopAtBounds

                            Row {
                                id: filaVentanas
                                height: parent.height
                                spacing: 14

                                Repeater {
                                    model: fila.ventanas

                                    Item {
                                        id: mini
                                        required property var modelData
                                        readonly property var ipc: modelData.lastIpcObject
                                        readonly property real prop: (ipc?.size?.[0] ?? 16) / Math.max(1, ipc?.size?.[1] ?? 10)
                                        readonly property bool enfocada: modelData.activated
                                        readonly property string clave: root.addr(modelData)

                                        height: filaVentanas.height
                                        width: height * prop

                                        Component.onCompleted: root.miniaturas[clave] = mini
                                        Component.onDestruction: if (root.miniaturas[clave] === mini) delete root.miniaturas[clave]

                                        // Tarjeta que se eleva al pasar el mouse
                                        Rectangle {
                                            anchors.fill: parent
                                            radius: 14 * root.t
                                            color: Qt.rgba(0.12, 0.11, 0.09, 1)
                                            border.width: hover.containsMouse || mini.enfocada ? 2 : 1
                                            border.color: hover.containsMouse ? root.crema : (mini.enfocada ? root.oro : Qt.rgba(1, 1, 1, 0.08))
                                            scale: hover.containsMouse ? 1.04 : 1
                                            Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutBack } }
                                            Behavior on border.color { ColorAnimation { duration: 140 } }
                                            clip: true

                                            ScreencopyView {
                                                anchors { fill: parent; margins: 2 * root.t }
                                                captureSource: root.abierto ? mini.modelData.wayland : null
                                                live: true
                                            }

                                            // Nombre de la app abajo
                                            Rectangle {
                                                anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: 7 }
                                                height: 26; radius: 9
                                                color: Qt.rgba(0.08, 0.07, 0.06, 0.82)
                                                opacity: root.t * (hover.containsMouse ? 1 : 0.85)
                                                Text {
                                                    anchors { fill: parent; leftMargin: 9; rightMargin: 9 }
                                                    verticalAlignment: Text.AlignVCenter
                                                    elide: Text.ElideRight
                                                    text: mini.modelData.title
                                                    color: root.crema
                                                    font { family: "Rubik"; pixelSize: 12 }
                                                }
                                            }
                                        }

                                        MouseArea {
                                            id: hover
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            onEntered: root.seleccion = fila.wsId
                                            onClicked: root.salirA(mini.modelData, fila.wsId)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
