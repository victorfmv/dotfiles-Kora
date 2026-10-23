// Panel de batería y modo de energía: sale desde abajo de la barra, bajo el ícono de la batería.
// IPC:  qs -p ~/.config/hypr-kora/centro ipc call energia toggle <x del cursor>
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.UPower

Scope {
    id: energia

    readonly property color oro: "#e6b450"
    readonly property color crema: "#ece4d4"
    readonly property color tenue: "#8c8270"
    readonly property color fondo: "#14120f"
    readonly property string iconos: "CaskaydiaCove Nerd Font"

    property bool abierto: false
    property real centroX: 0            // x del ícono (donde se dio clic), el panel se centra ahí

    readonly property var bateria: UPower.displayDevice
    readonly property real nivel: {
        const p = bateria?.percentage ?? 0;
        return p > 1 ? p / 100 : p;
    }
    readonly property bool cargando: bateria?.state === UPowerDeviceState.Charging
    readonly property bool llena: bateria?.state === UPowerDeviceState.FullyCharged

    function duracion(s) {
        if (!s || s <= 0) return "";
        const h = Math.floor(s / 3600), m = Math.round(s % 3600 / 60);
        return (h ? h + " h " : "") + m + " min";
    }
    readonly property string estado: {
        if (llena) return "Cargada";
        if (cargando) {
            const t = duracion(bateria?.timeToFull);
            return t ? "Cargando · " + t + " para llenarse" : "Cargando";
        }
        const t = duracion(bateria?.timeToEmpty);
        return t ? "Con batería · quedan " + t : "Con batería";
    }
    readonly property string iconoBateria: {
        if (cargando) return "󰂄";
        const ic = ["󰂎", "󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"];
        return ic[Math.round(nivel * 10)];
    }

    readonly property var modos: [
        { perfil: PowerProfile.PowerSaver,  ic: "󰌪", nombre: "Ahorro",      desc: "Dura más la batería, menos velocidad" },
        { perfil: PowerProfile.Balanced,    ic: "󰗑", nombre: "Balanceado",  desc: "Equilibrio entre batería y velocidad" },
        { perfil: PowerProfile.Performance, ic: "󱓞", nombre: "Rendimiento", desc: "Máxima velocidad, gasta más batería" }
    ]
    readonly property var modoActual: modos.find(m => m.perfil === PowerProfiles.profile) ?? modos[1]

    IpcHandler {
        target: "energia"
        function toggle(x: int): void {
            if (energia.abierto) { energia.abierto = false; return; }
            energia.centroX = x;
            energia.abierto = true;
        }
        function close(): void { energia.abierto = false; }
    }

    PanelWindow {
        id: ventana
        visible: energia.abierto || caja.opacity > 0
        anchors { top: true; bottom: true; left: true; right: true }
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "kora-energia"
        WlrLayershell.keyboardFocus: energia.abierto ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

        // Clic afuera cierra
        MouseArea { anchors.fill: parent; onClicked: energia.abierto = false }

        // Recorte justo debajo de la barra: la tarjeta se asoma desde ahí
        Item {
            id: recorte
            x: Math.max(10, Math.min(ventana.width - width - 10, energia.centroX - width / 2))
            y: 44
            width: 320
            height: caja.height + 20
            clip: true

            Rectangle {
                id: caja
                width: parent.width
                height: columna.implicitHeight + 32
                radius: 22
                gradient: Gradient {
                    GradientStop { position: 0.0; color: Qt.rgba(0.11, 0.095, 0.075, 0.99) }
                    GradientStop { position: 1.0; color: Qt.rgba(0.06, 0.05, 0.04, 0.99) }
                }
                border.width: 1
                border.color: Qt.rgba(0.9, 0.7, 0.31, 0.5)

                y: energia.abierto ? 0 : -height * 0.6
                opacity: energia.abierto ? 1 : 0
                Behavior on y { NumberAnimation { duration: 280; easing.type: Easing.OutCubic } }
                Behavior on opacity { NumberAnimation { duration: 200 } }

                MouseArea { anchors.fill: parent }   // que los clics adentro no cierren
                focus: energia.abierto
                Keys.onEscapePressed: energia.abierto = false

                ColumnLayout {
                    id: columna
                    anchors { left: parent.left; right: parent.right; top: parent.top; margins: 16 }
                    spacing: 14

                    // ── Batería ──
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12

                        Rectangle {
                            Layout.preferredWidth: 48; Layout.preferredHeight: 48
                            radius: 16
                            color: Qt.rgba(0.9, 0.7, 0.31, 0.14)
                            border.width: 1; border.color: Qt.rgba(0.9, 0.7, 0.31, 0.3)
                            Text {
                                anchors.centerIn: parent
                                text: energia.iconoBateria
                                color: energia.nivel < 0.15 && !energia.cargando ? "#e06c5a" : energia.oro
                                font { family: energia.iconos; pixelSize: 24 }
                            }
                        }
                        Column {
                            Layout.fillWidth: true
                            spacing: 2
                            Text {
                                text: Math.round(energia.nivel * 100) + "%"
                                color: "#fff8ec"
                                font { family: "Rubik"; pixelSize: 22; bold: true }
                            }
                            Text {
                                width: parent.width
                                text: energia.estado
                                color: energia.tenue
                                elide: Text.ElideRight
                                font { family: "Rubik"; pixelSize: 11 }
                            }
                        }
                    }

                    // Barra de carga
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 6
                        radius: 3
                        color: Qt.rgba(1, 0.9, 0.7, 0.08)
                        Rectangle {
                            width: parent.width * energia.nivel
                            height: parent.height
                            radius: 3
                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop { position: 0.0; color: "#b8862f" }
                                GradientStop { position: 1.0; color: energia.oro }
                            }
                            Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
                        }
                    }

                    Text {
                        text: "MODO DE ENERGÍA"
                        color: energia.oro
                        font { family: "Rubik"; pixelSize: 10; weight: Font.DemiBold; letterSpacing: 1 }
                    }

                    // ── Modos ──
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Repeater {
                            model: energia.modos

                            Rectangle {
                                id: boton
                                required property var modelData
                                readonly property bool activo: PowerProfiles.profile === modelData.perfil
                                readonly property bool disponible: modelData.perfil !== PowerProfile.Performance || PowerProfiles.hasPerformanceProfile

                                Layout.fillWidth: true
                                Layout.preferredHeight: 86
                                radius: 16
                                opacity: disponible ? 1 : 0.35
                                gradient: Gradient {
                                    GradientStop { position: 0.0; color: boton.activo ? "#f0c463" : Qt.rgba(0.19, 0.165, 0.13, zona.containsMouse ? 1 : 0.85) }
                                    GradientStop { position: 1.0; color: boton.activo ? "#c99a3c" : Qt.rgba(0.13, 0.115, 0.095, zona.containsMouse ? 1 : 0.85) }
                                }
                                border.width: 1
                                border.color: boton.activo ? "#f5d48a" : zona.containsMouse ? Qt.rgba(0.9, 0.7, 0.31, 0.6) : Qt.rgba(1, 0.9, 0.7, 0.1)
                                scale: zona.pressed ? 0.95 : 1
                                Behavior on scale { NumberAnimation { duration: 100 } }

                                Column {
                                    anchors.centerIn: parent
                                    spacing: 6
                                    Rectangle {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        width: 38; height: 38; radius: 19
                                        color: boton.activo ? Qt.rgba(0.08, 0.07, 0.06, 0.2) : Qt.rgba(0.9, 0.7, 0.31, 0.14)
                                        Text {
                                            anchors.centerIn: parent
                                            text: boton.modelData.ic
                                            color: boton.activo ? energia.fondo : energia.oro
                                            font { family: energia.iconos; pixelSize: 20 }
                                        }
                                    }
                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: boton.modelData.nombre
                                        color: boton.activo ? energia.fondo : energia.crema
                                        font { family: "Rubik"; pixelSize: 11; weight: boton.activo ? Font.Bold : Font.Medium }
                                    }
                                }

                                MouseArea {
                                    id: zona
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    enabled: boton.disponible
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: PowerProfiles.profile = boton.modelData.perfil
                                }
                            }
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        text: energia.modoActual.desc
                        color: energia.tenue
                        font { family: "Rubik"; pixelSize: 11 }
                    }
                }
            }
        }
    }
}
