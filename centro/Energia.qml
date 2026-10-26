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

    readonly property color oro: "#e1754b"
    readonly property color crema: "#ebded5"
    readonly property color tenue: "#8b7c71"
    readonly property color fondo: "#14110f"
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
            y: 42
            width: 232
            height: caja.height + 20
            clip: true

            Rectangle {
                id: caja
                width: parent.width
                height: columna.implicitHeight + 22
                radius: 16
                gradient: Gradient {
                    GradientStop { position: 0.0; color: Qt.rgba(0.108, 0.09, 0.077, 0.99) }
                    GradientStop { position: 1.0; color: Qt.rgba(0.059, 0.049, 0.041, 0.99) }
                }
                border.width: 1
                border.color: Qt.rgba(0.879, 0.457, 0.291, 0.5)

                y: energia.abierto ? 0 : -height * 0.6
                opacity: energia.abierto ? 1 : 0
                Behavior on y { NumberAnimation { duration: 280; easing.type: Easing.OutCubic } }
                Behavior on opacity { NumberAnimation { duration: 200 } }

                MouseArea { anchors.fill: parent }   // que los clics adentro no cierren
                focus: energia.abierto
                Keys.onEscapePressed: energia.abierto = false

                ColumnLayout {
                    id: columna
                    anchors { left: parent.left; right: parent.right; top: parent.top; margins: 11 }
                    spacing: 9

                    // ── Batería ──
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 9

                        Rectangle {
                            Layout.preferredWidth: 34; Layout.preferredHeight: 34
                            radius: 11
                            color: Qt.rgba(0.879, 0.457, 0.291, 0.14)
                            border.width: 1; border.color: Qt.rgba(0.879, 0.457, 0.291, 0.3)
                            Text {
                                anchors.centerIn: parent
                                text: energia.iconoBateria
                                color: energia.nivel < 0.15 && !energia.cargando ? "#f2c14e" : energia.oro
                                font { family: energia.iconos; pixelSize: 17 }
                            }
                        }
                        Column {
                            Layout.fillWidth: true
                            spacing: 2
                            Text {
                                text: Math.round(energia.nivel * 100) + "%"
                                color: "#fef4ed"
                                font { family: "Rubik"; pixelSize: 16; bold: true }
                            }
                            Text {
                                width: parent.width
                                text: energia.estado
                                color: energia.tenue
                                elide: Text.ElideRight
                                font { family: "Rubik"; pixelSize: 9 }
                            }
                        }
                    }

                    // Barra de carga
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 4
                        radius: 2
                        color: Qt.rgba(0.991, 0.76, 0.669, 0.08)
                        Rectangle {
                            width: parent.width * energia.nivel
                            height: parent.height
                            radius: 2
                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop { position: 0.0; color: "#ad5330" }
                                GradientStop { position: 1.0; color: energia.oro }
                            }
                            Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
                        }
                    }

                    Text {
                        text: "MODO DE ENERGÍA"
                        color: energia.oro
                        font { family: "Rubik"; pixelSize: 9; weight: Font.DemiBold; letterSpacing: 1 }
                    }

                    // ── Modos ──
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        Repeater {
                            model: energia.modos

                            Rectangle {
                                id: boton
                                required property var modelData
                                readonly property bool activo: PowerProfiles.profile === modelData.perfil
                                readonly property bool disponible: modelData.perfil !== PowerProfile.Performance || PowerProfiles.hasPerformanceProfile

                                Layout.fillWidth: true
                                Layout.preferredHeight: 58
                                radius: 12
                                opacity: disponible ? 1 : 0.35
                                gradient: Gradient {
                                    GradientStop { position: 0.0; color: boton.activo ? "#eb865d" : Qt.rgba(0.187, 0.155, 0.133, zona.containsMouse ? 1 : 0.85) }
                                    GradientStop { position: 1.0; color: boton.activo ? "#c1603a" : Qt.rgba(0.128, 0.11, 0.097, zona.containsMouse ? 1 : 0.85) }
                                }
                                border.width: 1
                                border.color: boton.activo ? "#f1a383" : zona.containsMouse ? Qt.rgba(0.879, 0.457, 0.291, 0.6) : Qt.rgba(0.991, 0.76, 0.669, 0.1)
                                scale: zona.pressed ? 0.95 : 1
                                Behavior on scale { NumberAnimation { duration: 100 } }

                                Column {
                                    anchors.centerIn: parent
                                    spacing: 3
                                    Rectangle {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        width: 26; height: 26; radius: 13
                                        color: boton.activo ? Qt.rgba(0.079, 0.069, 0.061, 0.2) : Qt.rgba(0.879, 0.457, 0.291, 0.14)
                                        Text {
                                            anchors.centerIn: parent
                                            text: boton.modelData.ic
                                            color: boton.activo ? energia.fondo : energia.oro
                                            font { family: energia.iconos; pixelSize: 14 }
                                        }
                                    }
                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: boton.modelData.nombre
                                        color: boton.activo ? energia.fondo : energia.crema
                                        font { family: "Rubik"; pixelSize: 9; weight: boton.activo ? Font.Bold : Font.Medium }
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
                        font { family: "Rubik"; pixelSize: 9 }
                    }
                }
            }
        }
    }
}
