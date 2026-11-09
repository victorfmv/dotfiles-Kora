// Panel de notas rápidas: sale pequeño abajo a la derecha (Super + T) y crece según el texto.
// Se escribe directo y se guarda solo en ~/.local/state/hypr-kora/notas.txt
// IPC:  qs -p ~/.config/hypr-kora/centro ipc call notas toggle|open|close
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Scope {
    id: notas

    readonly property color oro: "#e68750"
    readonly property color crema: "#e4d2ee"
    readonly property color tenue: "#826e8e"
    readonly property color fondo: "#120f14"
    readonly property string iconos: "CaskaydiaCove Nerd Font"

    property bool abierto: false
    property bool guardado: true

    IpcHandler {
        target: "notas"
        function toggle(): void { notas.abierto ? notas.cerrar() : notas.abrir(); }
        function open(): void { notas.abrir(); }
        function close(): void { notas.cerrar(); }
    }

    function abrir() { abierto = true; editor.forceActiveFocus(); }
    function cerrar() { guardar(); abierto = false; }

    FileView {
        id: archivo
        path: Quickshell.env("HOME") + "/.local/state/hypr-kora/notas.txt"
        blockLoading: true
        atomicWrites: true
        printErrors: false
    }
    function guardar() {
        if (guardado) return;
        archivo.setText(editor.text);
        guardado = true;
    }
    Timer { id: autoguardado; interval: 800; onTriggered: notas.guardar() }

    PanelWindow {
        id: ventana
        visible: notas.abierto || caja.opacity > 0
        anchors { top: true; bottom: true; left: true; right: true }
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "kora-notas"
        WlrLayershell.keyboardFocus: notas.abierto ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        // Clic afuera cierra
        MouseArea { anchors.fill: parent; onClicked: notas.cerrar() }

        // Mide la línea más larga (sin ajuste) para saber cuánto ensanchar
        Text {
            id: medida
            visible: false
            text: editor.text
            font: editor.font
        }

        Rectangle {
            id: caja
            readonly property int relleno: 14
            readonly property int anchoMin: 280
            readonly property int anchoMax: Math.min(460, ventana.width - 40)
            readonly property int altoMax: ventana.height - 80

            width: Math.max(anchoMin, Math.min(anchoMax, medida.implicitWidth + relleno * 2 + 28))
            height: Math.min(altoMax, encabezado.height + Math.max(22, editor.implicitHeight) + relleno * 2 + 19)
            Behavior on width { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
            Behavior on height { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

            anchors { right: parent.right; bottom: parent.bottom; rightMargin: 14; bottomMargin: 14 }
            radius: 20
            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.rgba(0.098, 0.072, 0.113, 0.97) }
                GradientStop { position: 1.0; color: Qt.rgba(0.053, 0.039, 0.061, 0.97) }
            }
            border.width: 1
            border.color: Qt.rgba(0.9, 0.526, 0.31, 0.45)
            clip: true

            // Entrada: sube desde abajo, crece un poco y aparece
            opacity: notas.abierto ? 1 : 0
            scale: notas.abierto ? 1 : 0.92
            transformOrigin: Item.BottomRight
            transform: Translate { y: notas.abierto ? 0 : 24; Behavior on y { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } } }
            Behavior on opacity { NumberAnimation { duration: 200 } }
            Behavior on scale { NumberAnimation { duration: 260; easing.type: Easing.OutBack } }

            MouseArea { anchors.fill: parent; onClicked: editor.forceActiveFocus() }   // que los clics adentro no cierren

            // ── Encabezado compacto ──
            RowLayout {
                id: encabezado
                anchors { top: parent.top; left: parent.left; right: parent.right; margins: caja.relleno }
                height: 26
                spacing: 8

                Rectangle {
                    Layout.preferredWidth: 8; Layout.preferredHeight: 8
                    radius: 4
                    color: notas.guardado ? notas.oro : notas.tenue
                    Behavior on color { ColorAnimation { duration: 200 } }
                }
                Text {
                    Layout.fillWidth: true
                    text: "Notas"
                    color: "#ebd6f7"
                    font { family: "Rubik"; pixelSize: 13; bold: true; letterSpacing: 0.5 }
                }
                Repeater {
                    model: [
                        { ic: "󰆏", accion: () => Quickshell.execDetached(["wl-copy", editor.text]) },
                        { ic: "󰃢", accion: () => { editor.text = ""; editor.forceActiveFocus(); } },
                        { ic: "󰅖", accion: () => notas.cerrar() }
                    ]
                    Rectangle {
                        required property var modelData
                        Layout.preferredWidth: 26; Layout.preferredHeight: 26
                        radius: 13
                        color: b.containsMouse ? Qt.rgba(0.073, 0.058, 0.082, 0.95) : "transparent"
                        border.width: b.containsMouse ? 1 : 0
                        border.color: Qt.rgba(1, 0.81, 0.7, 0.22)
                        Text {
                            anchors.centerIn: parent
                            text: modelData.ic
                            color: b.containsMouse ? notas.oro : notas.tenue
                            font { family: notas.iconos; pixelSize: 13 }
                        }
                        MouseArea { id: b; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: modelData.accion() }
                    }
                }
            }

            // Línea fina bajo el encabezado
            Rectangle {
                id: linea
                anchors { top: encabezado.bottom; left: parent.left; right: parent.right; topMargin: 8; leftMargin: caja.relleno; rightMargin: caja.relleno }
                height: 1
                color: Qt.rgba(1, 0.81, 0.7, 0.1)
            }

            // ── Hoja ──
            Flickable {
                id: hoja
                anchors { top: linea.bottom; bottom: parent.bottom; left: parent.left; right: parent.right
                          topMargin: 10; leftMargin: caja.relleno; rightMargin: caja.relleno; bottomMargin: caja.relleno }
                contentHeight: editor.implicitHeight
                boundsBehavior: Flickable.StopAtBounds
                clip: true

                // Seguir al cursor cuando ya no cabe y hay que desplazar
                function verCursor(r) {
                    if (r.y < contentY) contentY = r.y;
                    else if (r.y + r.height > contentY + height) contentY = r.y + r.height - height;
                }

                TextEdit {
                    id: editor
                    width: hoja.width
                    text: archivo.text()
                    color: notas.crema
                    selectionColor: Qt.rgba(0.9, 0.526, 0.31, 0.35)
                    selectedTextColor: "#ebd6f7"
                    wrapMode: TextEdit.Wrap
                    font { family: "Rubik"; pixelSize: 14 }
                    focus: true
                    persistentSelection: true
                    onTextChanged: if (text !== archivo.text()) { notas.guardado = false; autoguardado.restart(); }
                    onCursorRectangleChanged: hoja.verCursor(cursorRectangle)
                    Keys.onEscapePressed: notas.cerrar()

                    Text {
                        visible: !editor.text
                        text: "Escribe algo…"
                        color: notas.tenue
                        font: editor.font
                    }
                }
            }
        }

        onVisibleChanged: if (visible) editor.forceActiveFocus()
    }
}
