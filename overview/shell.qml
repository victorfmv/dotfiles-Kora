// Vista de workspaces de Hyprland Kora (tipo niri): alejamiento con los 5
// workspaces del grupo actual apilados en vertical y sus ventanas en fila.
// Abrir/cerrar:  ~/.config/hypr-kora/scripts/overview.sh
// Clic en ventana = ir a ella · clic en un workspace = ir ahí · ↑↓ + Enter · Esc cierra
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
    readonly property color fondo: "#14120f"

    readonly property int grupo: 5
    property bool abierto: false
    property int seleccion: 1

    readonly property var monitor: Hyprland.focusedMonitor
    readonly property int activo: monitor?.activeWorkspace?.id ?? 1
    readonly property int inicio: Math.floor((Math.max(seleccion, 1) - 1) / grupo) * grupo + 1

    function abrir() {
        Hyprland.refreshWorkspaces();
        Hyprland.refreshToplevels();
        seleccion = Math.max(activo, 1);
        abierto = true;
    }
    function cerrar() { abierto = false; }
    function alternar() { abierto ? cerrar() : abrir(); }

    function irAWorkspace(id) {
        Hyprland.dispatch(`hl.dsp.focus({ workspace = ${id} })`);
        cerrar();
    }
    function irAVentana(toplevel) {
        const addr = toplevel.address.startsWith("0x") ? toplevel.address : "0x" + toplevel.address;
        Hyprland.dispatch(`hl.dsp.focus({ window = "address:${addr}" })`);
        cerrar();
    }
    // Ventanas de un workspace, de izquierda a derecha (orden de la fila scrolling)
    function ventanasDe(id) {
        return Hyprland.toplevels.values
            .filter(t => t.workspace?.id === id && !(t.lastIpcObject?.floating ?? false))
            .sort((a, b) => (a.lastIpcObject?.at?.[0] ?? 0) - (b.lastIpcObject?.at?.[0] ?? 0));
    }

    IpcHandler {
        target: "overview"
        function toggle(): void { root.alternar(); }
        function open(): void { root.abrir(); }
        function close(): void { root.cerrar(); }
    }

    PanelWindow {
        id: ventana
        visible: root.abierto || contenido.opacity > 0
        screen: Quickshell.screens.find(s => s.name === root.monitor?.name) ?? Quickshell.screens[0]
        color: "transparent"
        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "kora-overview"
        WlrLayershell.keyboardFocus: root.abierto ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        readonly property real escala: (height - 120) / root.grupo / height * 0.92

        // Fondo oscuro; clic afuera cierra
        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(0.04, 0.035, 0.03, 0.88)
            opacity: contenido.opacity
            MouseArea { anchors.fill: parent; onClicked: root.cerrar() }
        }

        Item {
            id: contenido
            anchors.fill: parent
            focus: true
            opacity: 0
            scale: 1.12
            transformOrigin: Item.Center

            states: State {
                name: "abierto"; when: root.abierto
                PropertyChanges { target: contenido; opacity: 1; scale: 1 }
            }
            transitions: [
                Transition {
                    to: "abierto"
                    NumberAnimation { properties: "opacity,scale"; duration: 260; easing.type: Easing.OutCubic }
                },
                Transition {
                    from: "abierto"
                    NumberAnimation { properties: "opacity,scale"; duration: 180; easing.type: Easing.InCubic }
                }
            ]

            Keys.onPressed: e => {
                if (e.key === Qt.Key_Escape) root.cerrar();
                else if (e.key === Qt.Key_Up || e.key === Qt.Key_K) root.seleccion = Math.max(1, root.seleccion - 1);
                else if (e.key === Qt.Key_Down || e.key === Qt.Key_J) root.seleccion = root.seleccion + 1;
                else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) root.irAWorkspace(root.seleccion);
                else if (e.key >= Qt.Key_1 && e.key <= Qt.Key_9) root.irAWorkspace(e.key - Qt.Key_0);
                else return;
                e.accepted = true;
            }
            Connections {
                target: root
                function onAbiertoChanged() { if (root.abierto) contenido.forceActiveFocus(); }
            }

            Column {
                anchors.centerIn: parent
                spacing: 18

                Repeater {
                    model: root.grupo

                    // Un workspace = una fila
                    Rectangle {
                        id: fila
                        required property int index
                        readonly property int wsId: root.inicio + index
                        readonly property bool esActivo: wsId === root.activo
                        readonly property bool esSeleccion: wsId === root.seleccion
                        readonly property var ventanas: root.abierto ? root.ventanasDe(wsId) : []

                        width: ventana.width * 0.86
                        height: ventana.height * ventana.escala
                        radius: 18
                        color: Qt.rgba(0.09, 0.08, 0.07, 0.95)
                        border.width: esSeleccion ? 2 : 1
                        border.color: esSeleccion ? root.oro : Qt.rgba(1, 1, 1, 0.06)
                        Behavior on border.color { ColorAnimation { duration: 120 } }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            onEntered: root.seleccion = fila.wsId
                            onClicked: root.irAWorkspace(fila.wsId)
                        }

                        // Punto + número a la izquierda, como la barra
                        Column {
                            anchors { left: parent.left; leftMargin: 22; verticalCenter: parent.verticalCenter }
                            spacing: 6
                            Rectangle {
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: fila.esActivo ? 14 : 10; height: width; radius: width / 2
                                color: fila.esActivo ? root.oro : (fila.ventanas.length ? root.crema : root.gris)
                            }
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: fila.wsId
                                color: fila.esSeleccion ? root.oro : root.gris
                                font { family: "Rubik"; pixelSize: 13; bold: true }
                            }
                        }

                        Text {
                            visible: fila.ventanas.length === 0
                            anchors.centerIn: parent
                            text: "vacío"
                            color: root.gris
                            font { family: "Rubik"; pixelSize: 15; italic: true }
                        }

                        // Ventanas en fila (tamaño proporcional a la pantalla)
                        Flickable {
                            anchors { fill: parent; leftMargin: 64; rightMargin: 16; topMargin: 10; bottomMargin: 10 }
                            contentWidth: filaVentanas.width
                            clip: true
                            boundsBehavior: Flickable.StopAtBounds

                            Row {
                                id: filaVentanas
                                height: parent.height
                                spacing: 12

                                Repeater {
                                    model: fila.ventanas

                                    Rectangle {
                                        id: mini
                                        required property var modelData
                                        readonly property var ipc: modelData.lastIpcObject
                                        readonly property real prop: (ipc?.size?.[0] ?? 16) / Math.max(1, ipc?.size?.[1] ?? 10)
                                        readonly property bool enfocada: modelData.activated

                                        height: filaVentanas.height
                                        width: height * prop
                                        radius: 12
                                        color: Qt.rgba(0.12, 0.11, 0.09, 1)
                                        border.width: enfocada ? 2 : 1
                                        border.color: hover.containsMouse ? root.crema : (enfocada ? root.oro : Qt.rgba(1, 1, 1, 0.1))
                                        scale: hover.containsMouse ? 1.03 : 1
                                        Behavior on scale { NumberAnimation { duration: 120 } }

                                        ScreencopyView {
                                            anchors { fill: parent; margins: 2 }
                                            captureSource: root.abierto ? mini.modelData.wayland : null
                                            live: true
                                        }

                                        // Nombre de la app abajo
                                        Rectangle {
                                            anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: 6 }
                                            height: 24; radius: 8
                                            color: Qt.rgba(0.08, 0.07, 0.06, 0.8)
                                            Text {
                                                anchors { fill: parent; leftMargin: 8; rightMargin: 8 }
                                                verticalAlignment: Text.AlignVCenter
                                                elide: Text.ElideRight
                                                text: mini.modelData.title
                                                color: root.crema
                                                font { family: "Rubik"; pixelSize: 12 }
                                            }
                                        }

                                        MouseArea {
                                            id: hover
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            onEntered: root.seleccion = fila.wsId
                                            onClicked: root.irAVentana(mini.modelData)
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
