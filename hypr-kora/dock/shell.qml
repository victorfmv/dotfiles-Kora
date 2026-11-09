// Dock del modo Familiar (estilo macOS): pastilla translúcida abajo al centro.
// - Iconos que se agrandan al pasar el ratón (y empujan a los vecinos).
// - Puntito redondo bajo las apps abiertas (color del tema en la enfocada).
// - Clic: abre la app, o enfoca su ventana (si tiene varias, va rotando);
//   si vive en un workspace especial (Spotify, Discord, Steam…) lo muestra/oculta.
// - Clic central: abre otra ventana nueva de la app.
// Colores en vivo de config/colors.lua (los reescribe tema.py).
// Lo prende/apaga scripts/familiar.sh. Probar a mano:  qs -p ~/.config/hypr-kora/dock
import QtQuick
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

    // ── Apps fijas (id del .desktop y regex de la clase de su ventana) ──
    readonly property var fijas: [
        { id: "brave-browser",    clase: "brave-browser" },
        { id: "kitty",            clase: "kitty" },
        { id: "org.kde.dolphin",  clase: "org\\.kde\\.dolphin" },
        { id: "vscodium",         clase: "codium|vscodium" },
        { id: "obsidian",         clase: "obsidian" },
        { id: "spotify-launcher", clase: "spotify" },
        { id: "discord",          clase: "discord|vesktop" },
        { id: "steam",            clase: "steam" },
    ]

    // ── Tamaños ──
    readonly property int icono: 46        // tamaño normal del ícono
    readonly property int celda: 58        // ancho de cada hueco
    readonly property real zoom: 1.55      // cuánto crece el ícono bajo el ratón
    readonly property real alcance: 150    // a cuántos px llega el efecto
    readonly property int alto: 68         // alto de la pastilla
    readonly property int abajo: 10        // separación del borde de la pantalla

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

    // ── Qué hay en el dock ──
    readonly property var elementos: {
        DesktopEntries.applications.values.length;   // recalcular cuando carguen los .desktop
        const abiertas = ToplevelManager.toplevels.values;
        const usadas = new Set();
        const lista = root.fijas.map(f => {
            const re = new RegExp("^(" + f.clase + ")$", "i");
            const vs = abiertas.filter(t => re.test(t.appId ?? ""));
            vs.forEach(v => usadas.add(v));
            return { entrada: DesktopEntries.byId(f.id), clase: f.id, ventanas: vs, fija: true };
        });
        const grupos = {};
        for (const t of abiertas) {
            if (usadas.has(t) || !t.appId) continue;
            (grupos[t.appId] = grupos[t.appId] || []).push(t);
        }
        for (const id in grupos)
            lista.push({ entrada: DesktopEntries.heuristicLookup(id), clase: id, ventanas: grupos[id], fija: false });
        return lista;
    }
    readonly property int nFijas: fijas.length
    readonly property bool hayExtras: elementos.length > nFijas
    readonly property int separador: hayExtras ? 21 : 0   // hueco de la rayita entre fijas y abiertas
    readonly property real anchoBase: elementos.length * celda + separador

    // Centro de un hueco (sin zoom) medido desde el centro del dock
    function centroBase(i) {
        return i * celda + celda / 2 + (i >= nFijas ? separador : 0) - anchoBase / 2;
    }

    // ── Acciones ── (config en Lua: Hyprland.dispatch de Quickshell no sirve, se usa hyprctl)
    function despachar(lua) { Quickshell.execDetached(["hyprctl", "dispatch", lua]); }
    function addr(h) { return h.address.startsWith("0x") ? h.address : "0x" + h.address; }

    function usar(d) {
        if (d.ventanas.length === 0) { d.entrada?.execute(); return false; }
        const i = d.ventanas.findIndex(v => v.activated);
        const t = d.ventanas[(i + 1) % d.ventanas.length];
        const h = Hyprland.toplevels.values.find(x => x.wayland === t);
        const ws = h?.workspace?.name ?? "";
        if (ws.startsWith("special:")) despachar(`hl.dsp.workspace.toggle_special("${ws.slice(8)}")`);
        else if (h) despachar(`hl.dsp.focus({ window = "address:${addr(h)}" })`);
        else t.activate();
        return true;
    }

    PanelWindow {
        id: ventana
        anchors { left: true; right: true; bottom: true }
        implicitHeight: 150                       // espacio para que los íconos crezcan hacia arriba
        exclusiveZone: root.alto + root.abajo     // las ventanas no se meten debajo del dock
        color: "transparent"
        WlrLayershell.layer: WlrLayer.Bottom      // pantalla completa lo tapa (igual que la barra)
        WlrLayershell.namespace: "kora-dock"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        // Solo la pastilla (y lo que sube al hacer zoom) recibe el ratón
        mask: Region { item: zona }

        Item {
            id: zona
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            width: pastilla.width
            height: sobre.hovered ? parent.height : root.alto + root.abajo

            HoverHandler { id: sobre }
            readonly property real ratonX: sobre.point.position.x - width / 2

            Rectangle {
                id: pastilla
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: root.abajo
                width: fila.width + 22
                height: root.alto
                radius: height / 2
                color: Qt.rgba(root.fondo.r, root.fondo.g, root.fondo.b, 0.55)
                border.width: 1
                border.color: Qt.rgba(root.crema.r, root.crema.g, root.crema.b, 0.12)
                // Brillo suave arriba, como vidrio
                Rectangle {
                    anchors { left: parent.left; right: parent.right; top: parent.top; margins: 1 }
                    height: parent.height / 2
                    radius: parent.radius
                    color: Qt.rgba(1, 1, 1, 0.04)
                }
            }

            Row {
                id: fila
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                height: parent.height

                Repeater {
                    model: root.elementos
                    delegate: Item {
                        id: hueco
                        required property var modelData
                        required property int index
                        readonly property bool primeraExtra: index === root.nFijas

                        readonly property bool abierta: modelData.ventanas.length > 0
                        readonly property bool activa: modelData.ventanas.some(v => v.activated)
                        readonly property string nombre: modelData.entrada?.name ?? modelData.clase
                        readonly property real escala: {
                            if (!sobre.hovered) return 1;
                            const d = Math.abs(zona.ratonX - root.centroBase(index));
                            const t = Math.min(d / root.alcance, 1);
                            return 1 + (root.zoom - 1) * Math.cos(t * Math.PI / 2);
                        }
                        property real salto: 0

                        width: root.celda * escala + (primeraExtra ? root.separador : 0)
                        height: fila.height
                        Behavior on width { NumberAnimation { duration: 90; easing.type: Easing.OutQuad } }

                        // Rayita que separa las fijas de las que no lo son
                        Rectangle {
                            visible: hueco.primeraExtra
                            x: (root.separador - width) / 2
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: root.abajo + 14
                            width: 1
                            height: root.alto - 28
                            color: Qt.rgba(root.crema.r, root.crema.g, root.crema.b, 0.18)
                        }

                        Item {
                            id: caja
                            x: hueco.primeraExtra ? root.separador : 0
                            width: parent.width - x
                            height: parent.height

                            IconImage {
                                id: imagen
                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.bottom: parent.bottom
                                anchors.bottomMargin: root.abajo + (root.alto - root.icono) / 2 + hueco.salto
                                implicitSize: root.icono * hueco.escala
                                source: Quickshell.iconPath(hueco.modelData.entrada?.icon ?? hueco.modelData.clase, "application-x-executable")
                                asynchronous: true
                                Behavior on implicitSize { NumberAnimation { duration: 90; easing.type: Easing.OutQuad } }
                            }

                            // Puntito de app abierta
                            Rectangle {
                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.bottom: parent.bottom
                                anchors.bottomMargin: root.abajo + 4
                                width: hueco.activa ? 14 : 5
                                height: 5
                                radius: 2.5
                                opacity: hueco.abierta ? 1 : 0
                                color: hueco.activa ? root.acento : Qt.rgba(root.crema.r, root.crema.g, root.crema.b, 0.7)
                                Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                                Behavior on opacity { NumberAnimation { duration: 200 } }
                                Behavior on color { ColorAnimation { duration: 200 } }
                            }

                            // Nombre de la app encima del ícono
                            Rectangle {
                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.bottom: imagen.top
                                anchors.bottomMargin: 10
                                width: etiqueta.implicitWidth + 24
                                height: 28
                                radius: height / 2
                                color: Qt.rgba(root.fondo.r, root.fondo.g, root.fondo.b, 0.85)
                                border.width: 1
                                border.color: Qt.rgba(root.crema.r, root.crema.g, root.crema.b, 0.12)
                                opacity: raton.containsMouse ? 1 : 0
                                visible: opacity > 0
                                Behavior on opacity { NumberAnimation { duration: 140 } }
                                Text {
                                    id: etiqueta
                                    anchors.centerIn: parent
                                    text: hueco.nombre
                                    color: root.crema
                                    font { family: "Rubik"; pixelSize: 13 }
                                }
                            }

                            MouseArea {
                                id: raton
                                anchors.fill: parent
                                anchors.bottomMargin: root.abajo
                                anchors.topMargin: parent.height - root.abajo - root.alto - (root.icono * (hueco.escala - 1))
                                hoverEnabled: true
                                acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                                cursorShape: Qt.PointingHandCursor
                                onClicked: mouse => {
                                    if (mouse.button === Qt.MiddleButton) { hueco.modelData.entrada?.execute(); rebote.restart(); return; }
                                    if (!root.usar(hueco.modelData)) rebote.restart();
                                }
                            }
                        }

                        // Brinquito al abrir una app
                        SequentialAnimation {
                            id: rebote
                            loops: 2
                            NumberAnimation { target: hueco; property: "salto"; to: 16; duration: 220; easing.type: Easing.OutQuad }
                            NumberAnimation { target: hueco; property: "salto"; to: 0; duration: 260; easing.type: Easing.OutBounce }
                        }
                    }
                }
            }
        }
    }
}
