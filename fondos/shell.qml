// Selector de wallpapers de Hyprland Kora: un panal de hexágonos animado.
// Al abrir, los hexágonos brotan en ola desde el centro y flotan suavemente;
// al elegir uno, un hexágono con el fondo nuevo crece hasta llenar la pantalla.
// Abrir/cerrar:  ~/.config/hypr-kora/scripts/fondos.sh [toggle|open|close]
// Clic o flechas + Enter = elegir · Esc o clic afuera = cerrar
// Las imágenes salen de ~/Imágenes/wallpapers (los videos se ponen solos con wallpaper.sh).
import QtQuick
import QtQuick.Effects
import QtQuick.Shapes
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

ShellRoot {
    id: root

    // Colores del tema actual, leídos en vivo de config/colors.lua (los reescribe tema.py)
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
    readonly property color oro: colorKora("accent", "#e44b43")
    readonly property color crema: colorKora("fg", "#d1dcef")
    readonly property color gris: Qt.rgba(crema.r, crema.g, crema.b, 0.45)

    readonly property string home: Quickshell.env("HOME")
    readonly property string carpeta: home + "/Imágenes/wallpapers"

    property bool abierto: false
    property bool eligiendo: false
    property int seleccion: 0
    property real t: 0            // fondo desenfocado: 0 = nada, 1 = visible
    property real entrada: 0      // avance de la ola de entrada (segundos)
    property real tiempo: 0       // reloj del flotado
    property real revelado: 0     // 0..1: el hexágono elegido crece hasta llenar la pantalla
    property string elegido: ""
    property real origenX: 0
    property real origenY: 0

    FileView {
        id: estadoWallpaper
        path: root.home + "/.local/state/hypr-kora/wallpaper"
        watchChanges: true
        onFileChanged: reload()
    }
    readonly property string actual: estadoWallpaper.text().trim()

    FolderListModel {
        id: imagenes
        folder: "file://" + root.carpeta
        nameFilters: ["*.png", "*.jpg", "*.jpeg", "*.webp"]
        showDirs: false
        sortField: FolderListModel.Name
    }

    // ── Panal: filas, columnas y tamaño de cada hexágono (con la parte plana arriba) ──
    readonly property int total: imagenes.count
    readonly property int filas: total <= 8 ? 2 : total <= 15 ? 3 : 4
    readonly property int columnas: Math.max(1, Math.ceil(total / filas))
    readonly property real separacion: 14
    readonly property real anchoHex: Math.min(420,
        (vista.width * 0.88 - separacion * (columnas - 1)) / (0.75 * (columnas - 1) + 1),
        (vista.height * 0.72 - separacion * filas) / ((filas + 0.5) * 0.866))
    readonly property real altoHex: anchoHex * 0.866
    readonly property real anchoPanal: anchoHex * (0.75 * (columnas - 1) + 1) + separacion * (columnas - 1)
    readonly property real altoPanal: (altoHex + separacion) * (filas + (columnas > 1 ? 0.5 : 0)) - separacion

    function nombreBonito(archivo) {
        const s = archivo.replace(/\.[^.]+$/, "").replace(/[-_]+/g, " ");
        return s.charAt(0).toUpperCase() + s.slice(1);
    }
    function suave(p) { p = Math.max(0, Math.min(1, p)); return 1 - Math.pow(1 - p, 3); }
    function rebote(p) {           // easeOutBack: se pasa un poquito y regresa
        p = Math.max(0, Math.min(1, p));
        const c = 1.5;
        return 1 + (c + 1) * Math.pow(p - 1, 3) + c * Math.pow(p - 1, 2);
    }

    function animar(anim, valor, ms, curva) {
        anim.stop();
        anim.from = anim.target[anim.property]; anim.to = valor;
        anim.duration = ms; anim.easing.type = curva;
        anim.start();
    }
    NumberAnimation { id: animT; target: root; property: "t"; onFinished: if (root.t === 0) root.cerrado() }
    NumberAnimation { id: animEntrada; target: root; property: "entrada" }
    NumberAnimation { id: animRevelado; target: root; property: "revelado"; onFinished: if (root.revelado === 1) root.aplicar() }
    NumberAnimation on tiempo { running: root.abierto; from: 0; to: Math.PI * 2; duration: 7000; loops: Animation.Infinite }

    function abrir() {
        if (abierto) return;
        let actualIdx = 0;
        for (let i = 0; i < total; i++)
            if (carpeta + "/" + imagenes.get(i, "fileName") === actual) actualIdx = i;
        seleccion = actualIdx;
        revelado = 0; entrada = 0; eligiendo = false;
        abierto = true;
        animar(animT, 1, 350, Easing.OutCubic);
        animar(animEntrada, 1.4, 1400, Easing.Linear);
    }
    function cerrar() {
        if (!abierto || eligiendo) return;
        eligiendo = true;
        animar(animEntrada, 0, 380, Easing.InCubic);
        animar(animT, 0, 420, Easing.InCubic);
    }
    function alternar() { abierto ? cerrar() : abrir(); }
    function cerrado() { abierto = false; }

    function elegir(i, celda) {
        if (eligiendo || i < 0 || i >= total) return;
        eligiendo = true;
        seleccion = i;
        elegido = carpeta + "/" + imagenes.get(i, "fileName");
        const c = celda.mapToItem(null, celda.width / 2, celda.height / 2);
        origenX = c.x; origenY = c.y;
        animar(animRevelado, 1, 850, Easing.InOutCubic);
    }
    // El hexágono ya tapa la pantalla: cambiar el wallpaper debajo y luego desvanecer
    function aplicar() {
        Quickshell.execDetached([root.home + "/.config/hypr-kora/scripts/wallpaper.sh", "set", elegido]);
        esperarMpv.restart();
    }
    Timer {
        id: esperarMpv
        interval: 1300            // lo que tarda mpvpaper en reiniciar con el video nuevo
        onTriggered: root.animar(animT, 0, 600, Easing.InOutQuad)
    }

    function mover(d) {
        if (eligiendo || total === 0) return;
        seleccion = Math.max(0, Math.min(total - 1, seleccion + d));
    }

    IpcHandler {
        target: "fondos"
        function toggle(): void { root.alternar(); }
        function open(): void { root.abrir(); }
        function close(): void { root.cerrar(); }
        function choose(i: int): void { if (root.abierto) root.elegir(i, panal.itemAt(i)); }
    }

    PanelWindow {
        id: vista
        visible: root.abierto
        screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
        color: "transparent"
        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "kora-fondos"
        WlrLayershell.keyboardFocus: root.abierto && !root.eligiendo ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        // Fondo: el wallpaper actual desenfocado y oscurecido
        Item {
            anchors.fill: parent
            opacity: root.t
            Image {
                id: fondoImg
                anchors.fill: parent
                source: root.actual ? "file://" + root.actual : ""
                sourceSize.width: 960
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
                brightness: -0.4
                saturation: -0.2
            }
            MouseArea {
                anchors.fill: parent
                onClicked: root.cerrar()
            }
        }

        Item {
            id: escena
            anchors.fill: parent
            focus: true
            opacity: 1 - root.revelado * 0.6

            Keys.onPressed: e => {
                if (e.key === Qt.Key_Escape) root.cerrar();
                else if (e.key === Qt.Key_Left || e.key === Qt.Key_H) root.mover(-root.filas);
                else if (e.key === Qt.Key_Right || e.key === Qt.Key_L) root.mover(root.filas);
                else if (e.key === Qt.Key_Up || e.key === Qt.Key_K) root.mover(-1);
                else if (e.key === Qt.Key_Down || e.key === Qt.Key_J) root.mover(1);
                else if (e.key === Qt.Key_Tab) root.mover(1);
                else if (e.key === Qt.Key_Backtab) root.mover(-1);
                else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter || e.key === Qt.Key_Space)
                    root.elegir(root.seleccion, panal.itemAt(root.seleccion));
                else return;
                e.accepted = true;
            }
            Connections {
                target: root
                function onAbiertoChanged() { if (root.abierto) escena.forceActiveFocus(); }
            }

            Item {
                id: contenedor
                width: root.anchoPanal
                height: root.altoPanal
                anchors.centerIn: parent
                anchors.verticalCenterOffset: -24

                Repeater {
                    id: panal
                    model: imagenes

                    Item {
                        id: celda
                        required property int index
                        required property string fileName
                        readonly property int col: Math.floor(index / root.filas)
                        readonly property int fila: index % root.filas
                        readonly property bool esSeleccion: index === root.seleccion
                        readonly property bool esActual: root.carpeta + "/" + fileName === root.actual
                        readonly property bool esElegido: root.eligiendo && root.revelado > 0 && esSeleccion

                        // La ola sale del centro del panal
                        readonly property real baseX: col * (root.anchoHex * 0.75 + root.separacion)
                        readonly property real baseY: fila * (root.altoHex + root.separacion) + (col % 2) * (root.altoHex + root.separacion) / 2
                        readonly property real dx: (baseX + width / 2 - contenedor.width / 2) / Math.max(1, contenedor.width)
                        readonly property real dy: (baseY + height / 2 - contenedor.height / 2) / Math.max(1, contenedor.height)
                        readonly property real retraso: Math.sqrt(dx * dx + dy * dy) * 0.55 + (index % 3) * 0.03
                        readonly property real p: (root.entrada - retraso) / 0.6
                        readonly property real brote: root.rebote(p)

                        width: root.anchoHex
                        height: root.altoHex
                        x: baseX
                        y: baseY + Math.sin(root.tiempo + index * 0.9) * 5 + (1 - root.suave(p)) * 50
                        z: esSeleccion ? 2 : 1
                        opacity: Math.max(0, Math.min(1, p * 2)) * (esElegido ? 1 : 1 - root.revelado)
                        scale: (0.35 + 0.65 * brote) * (esSeleccion && !root.eligiendo ? 1.07 : 1)
                        rotation: (1 - root.suave(p)) * (index % 2 ? 10 : -10)
                        Behavior on scale { enabled: root.entrada >= 1.4; NumberAnimation { duration: 260; easing.type: Easing.OutBack } }

                        Shape {
                            id: mascara
                            anchors.fill: parent
                            visible: false
                            layer.enabled: true
                            preferredRendererType: Shape.CurveRenderer
                            containsMode: Shape.FillContains
                            ShapePath {
                                fillColor: "white"
                                strokeColor: "transparent"
                                startX: celda.width / 4; startY: 0
                                PathLine { x: celda.width * 3 / 4; y: 0 }
                                PathLine { x: celda.width; y: celda.height / 2 }
                                PathLine { x: celda.width * 3 / 4; y: celda.height }
                                PathLine { x: celda.width / 4; y: celda.height }
                                PathLine { x: 0; y: celda.height / 2 }
                                PathLine { x: celda.width / 4; y: 0 }
                            }
                        }

                        Item {
                            id: contenido
                            anchors.fill: parent
                            visible: false
                            layer.enabled: true
                            clip: true
                            Image {
                                anchors.fill: parent
                                source: "file://" + root.carpeta + "/" + celda.fileName
                                sourceSize.width: 900
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                cache: true
                                // Acercamiento lento de la imagen dentro del hexágono
                                scale: celda.esSeleccion ? 1.18 : 1.04
                                Behavior on scale { NumberAnimation { duration: 900; easing.type: Easing.OutCubic } }
                            }
                        }
                        Shape {
                            anchors.fill: parent
                            preferredRendererType: Shape.CurveRenderer
                            layer.enabled: true
                            layer.effect: MultiEffect {
                                brightness: celda.esSeleccion ? 0.04 : -0.18
                                saturation: celda.esSeleccion ? 0.1 : -0.25
                                shadowEnabled: true
                                shadowColor: Qt.rgba(0, 0, 0, 0.7)
                                shadowBlur: 0.8
                                shadowVerticalOffset: 8
                                Behavior on brightness { NumberAnimation { duration: 250 } }
                                Behavior on saturation { NumberAnimation { duration: 250 } }
                            }
                            ShapePath {
                                fillItem: contenido
                                strokeColor: "transparent"
                                startX: celda.width / 4; startY: 0
                                PathLine { x: celda.width * 3 / 4; y: 0 }
                                PathLine { x: celda.width; y: celda.height / 2 }
                                PathLine { x: celda.width * 3 / 4; y: celda.height }
                                PathLine { x: celda.width / 4; y: celda.height }
                                PathLine { x: 0; y: celda.height / 2 }
                                PathLine { x: celda.width / 4; y: 0 }
                            }
                        }

                        // Borde: tenue en todos, del color del tema en el seleccionado
                        Shape {
                            anchors.fill: parent
                            preferredRendererType: Shape.CurveRenderer
                            ShapePath {
                                fillColor: "transparent"
                                strokeColor: celda.esSeleccion ? root.oro : Qt.rgba(1, 1, 1, 0.22)
                                strokeWidth: celda.esSeleccion ? 3.5 : 1.5
                                joinStyle: ShapePath.RoundJoin
                                startX: celda.width / 4; startY: 0
                                PathLine { x: celda.width * 3 / 4; y: 0 }
                                PathLine { x: celda.width; y: celda.height / 2 }
                                PathLine { x: celda.width * 3 / 4; y: celda.height }
                                PathLine { x: celda.width / 4; y: celda.height }
                                PathLine { x: 0; y: celda.height / 2 }
                                PathLine { x: celda.width / 4; y: 0 }
                            }
                        }

                        // Puntito en el wallpaper que está puesto
                        Rectangle {
                            visible: celda.esActual
                            width: 9; height: 9; radius: 4.5
                            color: root.oro
                            border.width: 1.5
                            border.color: Qt.rgba(0, 0, 0, 0.4)
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 14
                        }

                        MouseArea {
                            anchors.fill: parent
                            containmentMask: mascara
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: if (!root.eligiendo) root.seleccion = celda.index
                            onClicked: root.elegir(celda.index, celda)
                        }
                    }
                }
            }

            // Nombre del seleccionado
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: contenedor.bottom
                anchors.topMargin: 40
                text: root.total > 0 ? root.nombreBonito(imagenes.get(root.seleccion, "fileName") ?? "") : "No hay imágenes en ~/Imágenes/wallpapers"
                color: root.crema
                font.pixelSize: 22
                font.weight: Font.DemiBold
                font.letterSpacing: 1.5
                opacity: root.suave(root.entrada - 0.5) * (1 - root.revelado)
                style: Text.Raised
                styleColor: Qt.rgba(0, 0, 0, 0.5)
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 36
                text: "←↑↓→  mover   ·   Enter  elegir   ·   Esc  cerrar"
                color: root.gris
                font.pixelSize: 13
                opacity: root.suave(root.entrada - 0.7) * (1 - root.revelado)
            }
        }

        // ── Al elegir: un hexágono con el fondo nuevo crece desde su lugar hasta tapar todo ──
        Item {
            anchors.fill: parent
            visible: root.revelado > 0
            Image {
                id: imgNueva
                anchors.fill: parent
                source: root.elegido ? "file://" + root.elegido : ""
                sourceSize.width: vista.width
                fillMode: Image.PreserveAspectCrop
                asynchronous: false
                visible: false
                layer.enabled: true
            }
            // Hexágono dibujado a pantalla completa (puntos calculados), relleno con la imagen nueva
            Shape {
                id: hexGrande
                anchors.fill: parent
                opacity: root.t
                preferredRendererType: Shape.CurveRenderer
                readonly property real lejos: Math.max(
                    Math.hypot(root.origenX, root.origenY),
                    Math.hypot(vista.width - root.origenX, root.origenY),
                    Math.hypot(root.origenX, vista.height - root.origenY),
                    Math.hypot(vista.width - root.origenX, vista.height - root.origenY))
                // radio (centro a vértice): de su tamaño en el panal a uno que cubre la esquina más lejana
                readonly property real inicio: root.anchoHex / 2 * 1.07
                readonly property real r: inicio + (lejos * 1.2 - inicio) * root.revelado
                readonly property real giro: root.revelado * Math.PI / 6
                function px(i) { return root.origenX + r * Math.cos(giro + i * Math.PI / 3); }
                function py(i) { return root.origenY + r * Math.sin(giro + i * Math.PI / 3); }
                ShapePath {
                    fillItem: imgNueva
                    strokeColor: "transparent"
                    startX: hexGrande.px(0); startY: hexGrande.py(0)
                    PathLine { x: hexGrande.px(1); y: hexGrande.py(1) }
                    PathLine { x: hexGrande.px(2); y: hexGrande.py(2) }
                    PathLine { x: hexGrande.px(3); y: hexGrande.py(3) }
                    PathLine { x: hexGrande.px(4); y: hexGrande.py(4) }
                    PathLine { x: hexGrande.px(5); y: hexGrande.py(5) }
                    PathLine { x: hexGrande.px(0); y: hexGrande.py(0) }
                }
            }
        }
    }
}
