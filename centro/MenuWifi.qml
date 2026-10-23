// Lista de redes WiFi: encender/apagar, conectar, desconectar y pedir contraseña.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Networking

Rectangle {
    id: raiz
    property bool abierto: false

    readonly property var dispositivo: Networking.devices.values.find(d => d.type === DeviceType.Wifi) ?? null
    readonly property var redes: (dispositivo?.networks?.values ?? [])
        .filter(r => r.name)
        .sort((a, b) => (b.connected - a.connected) || (b.known - a.known) || (b.signalStrength - a.signalStrength))
        .slice(0, 8)
    property string pidiendo: ""        // nombre de la red a la que se le está escribiendo contraseña

    // Buscar redes solo mientras la lista está abierta
    Binding { target: raiz.dispositivo; property: "scannerEnabled"; value: raiz.abierto; when: raiz.dispositivo !== null }

    implicitHeight: col.implicitHeight + 24
    radius: 18
    color: Qt.rgba(1, 1, 1, 0.04)
    border.width: 1; border.color: Qt.rgba(1, 0.9, 0.7, 0.07)

    function iconoSenal(s) { return s > 0.75 ? "󰤨" : s > 0.5 ? "󰤥" : s > 0.25 ? "󰤢" : "󰤟"; }

    ColumnLayout {
        id: col
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 12 }
        spacing: 6

        // Encabezado con interruptor
        RowLayout {
            Layout.fillWidth: true
            Text { text: "󰖩"; color: "#e6b450"; font { family: "CaskaydiaCove Nerd Font"; pixelSize: 16 } }
            Text {
                Layout.fillWidth: true
                text: "  WiFi"
                color: "#fff8ec"
                font { family: "Rubik"; pixelSize: 14; weight: Font.DemiBold }
            }
            Switch { encendido: Networking.wifiEnabled; onCambiar: Networking.wifiEnabled = !Networking.wifiEnabled }
        }

        Text {
            visible: !Networking.wifiEnabled || raiz.redes.length === 0
            Layout.fillWidth: true
            Layout.topMargin: 6; Layout.bottomMargin: 6
            horizontalAlignment: Text.AlignHCenter
            text: Networking.wifiEnabled ? "Buscando redes…" : "WiFi apagado"
            color: "#8c8270"
            font { family: "Rubik"; pixelSize: 12; italic: true }
        }

        Repeater {
            model: Networking.wifiEnabled ? raiz.redes : []

            ColumnLayout {
                id: red
                required property var modelData
                readonly property bool protegida: modelData.security !== WifiSecurityType.Open && modelData.security !== WifiSecurityType.Owe
                readonly property bool conectando: modelData.state === ConnectionState.Connecting
                Layout.fillWidth: true
                spacing: 6

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 42
                    radius: 12
                    color: red.modelData.connected ? Qt.rgba(0.9, 0.7, 0.31, 0.18) : Qt.rgba(1, 0.95, 0.85, filaArea.containsMouse ? 0.07 : 0.025)
                    border.width: 1
                    border.color: red.modelData.connected ? Qt.rgba(0.9, 0.7, 0.31, 0.6) : Qt.rgba(1, 0.9, 0.7, filaArea.containsMouse ? 0.22 : 0.06)
                    Behavior on color { ColorAnimation { duration: 120 } }

                    RowLayout {
                        anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
                        spacing: 10
                        Text {
                            text: raiz.iconoSenal(red.modelData.signalStrength)
                            color: red.modelData.connected ? "#e6b450" : "#ece4d4"
                            font { family: "CaskaydiaCove Nerd Font"; pixelSize: 16 }
                        }
                        Text {
                            Layout.fillWidth: true
                            text: red.modelData.name
                            elide: Text.ElideRight
                            color: red.modelData.connected ? "#fff8ec" : "#ece4d4"
                            font { family: "Rubik"; pixelSize: 13; weight: red.modelData.connected ? Font.DemiBold : Font.Normal }
                        }
                        Text {
                            text: red.conectando ? "conectando…" : red.modelData.connected ? "conectado" : red.modelData.known ? "guardada" : ""
                            color: red.modelData.connected ? "#e6b450" : "#8c8270"
                            font { family: "Rubik"; pixelSize: 11 }
                        }
                        Text {
                            visible: red.protegida
                            text: "󰌾"
                            color: "#8c8270"
                            font { family: "CaskaydiaCove Nerd Font"; pixelSize: 12 }
                        }
                    }
                    MouseArea {
                        id: filaArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            const r = red.modelData;
                            if (r.connected) r.disconnect();
                            else if (r.known || !red.protegida) r.connect();
                            else { raiz.pidiendo = raiz.pidiendo === r.name ? "" : r.name; }
                        }
                    }
                }

                // Contraseña para redes nuevas
                Rectangle {
                    visible: raiz.pidiendo === red.modelData.name
                    Layout.fillWidth: true
                    Layout.preferredHeight: 40
                    radius: 12
                    color: Qt.rgba(0, 0, 0, 0.35)
                    border.width: 1; border.color: "#e6b450"

                    TextInput {
                        id: clave
                        anchors { fill: parent; leftMargin: 14; rightMargin: 50 }
                        verticalAlignment: TextInput.AlignVCenter
                        echoMode: TextInput.Password
                        color: "#fff8ec"
                        font { family: "Rubik"; pixelSize: 13 }
                        focus: parent.visible
                        onVisibleChanged: if (visible) forceActiveFocus()
                        onAccepted: conectarBtn.enviar()
                        Text {
                            visible: !clave.text
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Contraseña"
                            color: "#6b6255"
                            font: clave.font
                        }
                    }
                    Rectangle {
                        id: conectarBtn
                        anchors { right: parent.right; verticalCenter: parent.verticalCenter; rightMargin: 5 }
                        width: 36; height: 30; radius: 10
                        color: "#e6b450"
                        function enviar() {
                            if (!clave.text) return;
                            red.modelData.connectWithPsk(clave.text);
                            clave.text = "";
                            raiz.pidiendo = "";
                        }
                        Text { anchors.centerIn: parent; text: "󰁔"; color: "#14120f"; font { family: "CaskaydiaCove Nerd Font"; pixelSize: 15 } }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: conectarBtn.enviar() }
                    }
                }
            }
        }

        // Más opciones
        Text {
            Layout.alignment: Qt.AlignRight
            Layout.topMargin: 2
            text: "Más opciones de red  →"
            color: masArea.containsMouse ? "#e6b450" : "#8c8270"
            font { family: "Rubik"; pixelSize: 11 }
            MouseArea {
                id: masArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                onClicked: Quickshell.execDetached(["nm-connection-editor"])
            }
        }
    }
}
