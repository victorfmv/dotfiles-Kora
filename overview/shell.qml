// Vista de workspaces de Hyprland Kora, estilo niri: cada workspace es una
// pantalla en miniatura (wallpaper + ventanas en su lugar real), apiladas en
// vertical con la actual al centro y el wallpaper desenfocado detrás.
// Al abrir, la pantalla se aleja; al elegir, la cámara se acerca hasta llenarla.
// Abrir/cerrar:  ~/.config/hypr-kora/scripts/overview.sh [toggle|open|close]
// Clic en ventana/pantalla = ir ahí · ↑↓ o rueda + Enter · 1-9 · Esc cierra
// Super + rueda: abre y recorre; al soltar Super va al workspace elegido
import QtQuick
import QtQuick.Effects
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
    readonly property real k: 0.6            // tamaño de cada pantalla en la vista
    readonly property real separacion: 48

    property bool abierto: false
    property bool saliendo: false
    property bool porRueda: false           // abierta con Super + rueda: al soltar Super se elige
    property int seleccion: 1
    property int grupoInicio: 1
    property real t: 0                      // 0 = pantalla normal, 1 = vista alejada
    property real foco: 0                   // índice (con decimales) de la pantalla centrada

    readonly property var monitor: Hyprland.focusedMonitor
    readonly property int activo: monitor?.activeWorkspace?.id ?? 1

    FileView {
        id: estadoWallpaper
        path: Quickshell.env("HOME") + "/.local/state/hypr-kora/wallpaper"
        watchChanges: true
        onFileChanged: reload()
    }
    readonly property string wallpaper: "file://" + estadoWallpaper.text().trim()

    NumberAnimation {
        id: animT
        target: root; property: "t"
        onFinished: if (root.t === 0) {
            root.abierto = false;
            root.saliendo = false;
            // Al cerrar la vista Hyprland devuelve el foco a la ventana anterior
            // (y con ella al workspace anterior): repetir la orden al final.
            if (root.pendiente) reafirmar.restart();
        }
    }
    property string pendiente: ""
    Timer {
        id: reafirmar
        interval: 60
        onTriggered: { root.despachar(root.pendiente); root.pendiente = ""; }
    }
    NumberAnimation { id: animFoco; target: root; property: "foco"; duration: 300; easing.type: Easing.OutCubic }

    function animar(anim, valor, ms, curva) {
        anim.stop();
        anim.from = anim.target[anim.property]; anim.to = valor;
        anim.duration = ms; anim.easing.type = curva;
        anim.start();
    }

    // Config en Lua: Hyprland.dispatch de Quickshell no sirve aquí, se usa hyprctl
    function despachar(lua) { Quickshell.execDetached(["hyprctl", "dispatch", lua]); }

    function addr(t) { return t.address.startsWith("0x") ? t.address : "0x" + t.address; }
    function ventanasDe(id) {
        return Hyprland.toplevels.values.filter(t => t.workspace?.id === id);
    }

    function seleccionar(id) {
        seleccion = Math.max(grupoInicio, Math.min(grupoInicio + grupo - 1, id));
        animar(animFoco, seleccion - grupoInicio, 300, Easing.OutCubic);
    }

    function abrir() {
        if (abierto && !saliendo) return;
        Hyprland.refreshWorkspaces();
        Hyprland.refreshToplevels();
        seleccion = Math.max(activo, 1);
        grupoInicio = Math.floor((seleccion - 1) / grupo) * grupo + 1;
        animFoco.stop();
        foco = seleccion - grupoInicio;
        saliendo = false;
        porRueda = false;
        if (!abierto) t = 0;
        abierto = true;
        animar(animT, 1, 460, Easing.OutQuart);
    }

    // Cerrar: centrar la pantalla elegida y acercarse hasta llenar el monitor
    function salirA(wsId, toplevel) {
        if (!abierto || saliendo) return;
        saliendo = true;
        pendiente = toplevel ? `hl.dsp.focus({ window = "address:${addr(toplevel)}" })`
                  : wsId !== activo ? `hl.dsp.focus({ workspace = ${wsId} })` : "";
        if (pendiente) despachar(pendiente);
        seleccion = wsId;
        animar(animFoco, wsId - grupoInicio, 380, Easing.InOutCubic);
        animar(animT, 0, 380, Easing.InOutCubic);
    }
    function cerrar() { salirA(activo, null); }
    // Super + rueda: abre la vista y recorre los workspaces; soltar Super elige
    function rueda(dir) {
        if (!abierto || saliendo) abrir();
        porRueda = true;
        seleccionar(seleccion + dir);
        entrarSolo.restart();
    }

    // Al dejar de girar la rueda, entrar solo al workspace seleccionado
    Timer {
        id: entrarSolo
        interval: 650
        onTriggered: {
            if (root.porRueda && root.abierto && !root.saliendo) {
                root.salirA(root.seleccion, null);
                // Si al soltar Super se abrió el lanzador, cerrarlo
                Quickshell.execDetached(["sh", "-c", "sleep 0.3; pkill -x fuzzel"]);
            }
        }
    }
    function alternar() { (abierto && !saliendo) ? cerrar() : abrir(); }

    IpcHandler {
        target: "overview"
        function toggle(): void { root.alternar(); }
        function open(): void { root.abrir(); }
        function close(): void { root.cerrar(); }
        function scroll(dir: int): void { root.rueda(dir); }
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

        readonly property real anchoPantalla: width * root.k
        readonly property real altoPantalla: height * root.k

        // Fondo: el wallpaper desenfocado y oscurecido
        Item {
            anchors.fill: parent
            opacity: root.t
            Image {
                id: fondoImg
                anchors.fill: parent
                source: root.wallpaper
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                visible: false
            }
            MultiEffect {
                anchors.fill: parent
                source: fondoImg
                blurEnabled: true
                blur: 1.0
                blurMax: 64
                brightness: -0.38
                saturation: -0.15
            }
            MouseArea {
                anchors.fill: parent
                onClicked: root.cerrar()
                onWheel: w => root.seleccionar(root.seleccion + (w.angleDelta.y < 0 ? 1 : -1))
            }
        }

        Item {
            id: escena
            anchors.fill: parent
            focus: true

            // Cámara: a t=0 la pantalla centrada ocupa exactamente el monitor
            transform: Scale {
                origin.x: vista.width / 2
                origin.y: vista.height / 2
                xScale: 1 / root.k + (1 - 1 / root.k) * root.t
                yScale: 1 / root.k + (1 - 1 / root.k) * root.t
            }

            Keys.onPressed: e => {
                if (e.key === Qt.Key_Escape) root.cerrar();
                else if (e.key === Qt.Key_Up || e.key === Qt.Key_K) root.seleccionar(root.seleccion - 1);
                else if (e.key === Qt.Key_Down || e.key === Qt.Key_J) root.seleccionar(root.seleccion + 1);
                else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter || e.key === Qt.Key_Space) root.salirA(root.seleccion, null);
                else if (e.key >= Qt.Key_1 && e.key <= Qt.Key_9) root.salirA(e.key - Qt.Key_0, null);
                else return;
                e.accepted = true;
            }
            Keys.onReleased: e => {
                if (root.porRueda && (e.key === Qt.Key_Super_L || e.key === Qt.Key_Super_R || e.key === Qt.Key_Meta)) {
                    root.salirA(root.seleccion, null);
                    // Soltar Super también abre el lanzador (bind de release): cerrarlo
                    Quickshell.execDetached(["sh", "-c", "sleep 0.25; pkill -x fuzzel"]);
                    e.accepted = true;
                }
            }
            Connections {
                target: root
                function onAbiertoChanged() { if (root.abierto) escena.forceActiveFocus(); }
            }

            Repeater {
                model: root.grupo

                // Un workspace = una pantalla en miniatura
                Item {
                    id: pantalla
                    required property int index
                    readonly property int wsId: root.grupoInicio + index
                    readonly property bool esActivo: wsId === root.activo
                    readonly property bool esSeleccion: wsId === root.seleccion
                    readonly property var ventanas: root.abierto ? root.ventanasDe(wsId) : []
                    readonly property real distancia: Math.abs(index - root.foco)

                    width: vista.anchoPantalla
                    height: vista.altoPantalla
                    x: (vista.width - width) / 2
                    y: (vista.height - height) / 2 + (index - root.foco) * (height + root.separacion)
                    // Las de arriba/abajo se ven un poco más chicas y tenues
                    scale: 1 - Math.min(1, distancia) * 0.06 * root.t
                    opacity: index === Math.round(root.foco) ? 1 : (0.55 + 0.45 * Math.max(0, 1 - distancia)) * root.t

                    // Sombra
                    Rectangle {
                        anchors { fill: marcoPantalla; margins: -2 }
                        radius: marcoPantalla.radius + 2
                        color: "transparent"
                        border.width: 2
                        border.color: pantalla.esSeleccion ? root.oro : Qt.rgba(0, 0, 0, 0.35)
                        opacity: root.t
                        Behavior on border.color { ColorAnimation { duration: 200 } }
                    }

                    Rectangle {
                        id: marcoPantalla
                        anchors.fill: parent
                        radius: 18 * root.t
                        color: "#0d0c0a"
                        clip: true

                        Image {
                            anchors.fill: parent
                            source: root.wallpaper
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            sourceSize.width: vista.width
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: root.salirA(pantalla.wsId, null)
                            onWheel: w => root.seleccionar(root.seleccion + (w.angleDelta.y < 0 ? 1 : -1))
                        }

                        Text {
                            visible: pantalla.ventanas.length === 0
                            anchors.centerIn: parent
                            text: "vacío"
                            color: Qt.rgba(0.93, 0.89, 0.83, 0.7)
                            opacity: root.t
                            font { family: "Rubik"; pixelSize: 22; italic: true }
                        }

                        // Ventanas en su lugar real (escaladas)
                        Repeater {
                            model: pantalla.ventanas

                            Item {
                                id: mini
                                required property var modelData
                                readonly property var ipc: modelData.lastIpcObject
                                readonly property bool enfocada: modelData.activated
                                x: ((ipc?.at?.[0] ?? 0) - (vista.screen?.x ?? 0)) * root.k
                                y: ((ipc?.at?.[1] ?? 0) - (vista.screen?.y ?? 0)) * root.k
                                width: (ipc?.size?.[0] ?? 0) * root.k
                                height: (ipc?.size?.[1] ?? 0) * root.k
                                z: (ipc?.floating ?? false) ? 2 : 1

                                Rectangle {
                                    anchors.fill: parent
                                    radius: 8
                                    color: "#14120f"
                                    clip: true
                                    border.width: hover.containsMouse ? 2 : (mini.enfocada ? 1.5 : 0)
                                    border.color: hover.containsMouse ? root.crema : root.oro
                                    scale: hover.containsMouse ? 1.025 : 1
                                    Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutBack } }

                                    ScreencopyView {
                                        anchors.fill: parent
                                        captureSource: root.abierto ? mini.modelData.wayland : null
                                        live: true
                                    }

                                    // Nombre de la app al pasar el mouse
                                    Rectangle {
                                        anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 10 }
                                        width: Math.min(parent.width - 20, nombre.implicitWidth + 24)
                                        height: 28; radius: 14
                                        color: Qt.rgba(0.08, 0.07, 0.06, 0.88)
                                        border.width: 1; border.color: Qt.rgba(0.9, 0.7, 0.31, 0.5)
                                        opacity: hover.containsMouse ? root.t : 0
                                        Behavior on opacity { NumberAnimation { duration: 150 } }
                                        Text {
                                            id: nombre
                                            anchors.centerIn: parent
                                            width: Math.min(implicitWidth, parent.parent.width - 44)
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
                                    onClicked: root.salirA(pantalla.wsId, mini.modelData)
                                    onWheel: w => root.seleccionar(root.seleccion + (w.angleDelta.y < 0 ? 1 : -1))
                                }
                            }
                        }
                    }

                    // Etiqueta del workspace arriba a la izquierda
                    Rectangle {
                        anchors { left: parent.left; bottom: parent.top; bottomMargin: 10 }
                        width: etiqueta.implicitWidth + 22; height: 26; radius: 13
                        color: pantalla.esSeleccion ? root.oro : Qt.rgba(0.08, 0.07, 0.06, 0.8)
                        opacity: root.t
                        Behavior on color { ColorAnimation { duration: 200 } }
                        Text {
                            id: etiqueta
                            anchors.centerIn: parent
                            text: pantalla.wsId + (pantalla.esActivo ? "  ·  aquí estás" : "")
                            color: pantalla.esSeleccion ? "#14120f" : root.crema
                            font { family: "Rubik"; pixelSize: 12; bold: true }
                        }
                    }
                }
            }
        }
    }
}
