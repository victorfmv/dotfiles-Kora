// Lista de dispositivos Bluetooth: encender/apagar, buscar, conectar y desconectar.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth

Rectangle {
    id: raiz
    property bool abierto: false

    readonly property var adaptador: Bluetooth.defaultAdapter
    readonly property var dispositivos: (adaptador?.devices?.values ?? [])
        // Solo con nombre de verdad (no los que se llaman como su dirección MAC)
        .filter(d => { const n = d.name || d.deviceName || ""; return n && !/^([0-9A-F]{2}[-:]){5}[0-9A-F]{2}$/i.test(n); })
        .sort((a, b) => (b.connected - a.connected) || (b.paired - a.paired))
        .slice(0, 8)

    // Buscar dispositivos solo mientras la lista está abierta
    Binding { target: raiz.adaptador; property: "discovering"; value: raiz.abierto && (raiz.adaptador?.enabled ?? false); when: raiz.adaptador !== null }

    implicitHeight: col.implicitHeight + 24
    radius: 18
    color: Qt.rgba(1, 1, 1, 0.04)
    border.width: 1; border.color: Qt.rgba(1, 0.9, 0.7, 0.07)

    function icono(d) {
        const i = d.icon ?? "";
        if (i.includes("headset") || i.includes("headphone")) return "󰋋";
        if (i.includes("audio") || i.includes("speaker")) return "󰓃";
        if (i.includes("mouse")) return "󰍽";
        if (i.includes("keyboard")) return "󰌌";
        if (i.includes("phone")) return "󰄜";
        if (i.includes("gaming") || i.includes("joystick")) return "󰊴";
        return "󰂯";
    }

    ColumnLayout {
        id: col
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 12 }
        spacing: 6

        RowLayout {
            Layout.fillWidth: true
            Text { text: "󰂯"; color: "#e6b450"; font { family: "CaskaydiaCove Nerd Font"; pixelSize: 16 } }
            Text {
                Layout.fillWidth: true
                text: "  Bluetooth"
                color: "#fff8ec"
                font { family: "Rubik"; pixelSize: 14; weight: Font.DemiBold }
            }
            Switch {
                encendido: raiz.adaptador?.enabled ?? false
                onCambiar: if (raiz.adaptador) raiz.adaptador.enabled = !raiz.adaptador.enabled
            }
        }

        Text {
            visible: !(raiz.adaptador?.enabled ?? false) || raiz.dispositivos.length === 0
            Layout.fillWidth: true
            Layout.topMargin: 6; Layout.bottomMargin: 6
            horizontalAlignment: Text.AlignHCenter
            text: !raiz.adaptador ? "No hay Bluetooth" : raiz.adaptador.enabled ? "Buscando dispositivos…" : "Bluetooth apagado"
            color: "#8c8270"
            font { family: "Rubik"; pixelSize: 12; italic: true }
        }

        Repeater {
            model: (raiz.adaptador?.enabled ?? false) ? raiz.dispositivos : []

            Rectangle {
                id: disp
                required property var modelData
                readonly property bool ocupado: modelData.pairing || modelData.state === BluetoothDeviceState.Connecting || modelData.state === BluetoothDeviceState.Disconnecting
                Layout.fillWidth: true
                Layout.preferredHeight: 42
                radius: 12
                color: modelData.connected ? Qt.rgba(0.9, 0.7, 0.31, 0.16) : Qt.rgba(1, 1, 1, area.containsMouse ? 0.07 : 0.0)
                Behavior on color { ColorAnimation { duration: 120 } }

                RowLayout {
                    anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
                    spacing: 10
                    Text {
                        text: raiz.icono(disp.modelData)
                        color: disp.modelData.connected ? "#e6b450" : "#ece4d4"
                        font { family: "CaskaydiaCove Nerd Font"; pixelSize: 16 }
                    }
                    Text {
                        Layout.fillWidth: true
                        text: disp.modelData.name || disp.modelData.deviceName
                        elide: Text.ElideRight
                        color: disp.modelData.connected ? "#fff8ec" : "#ece4d4"
                        font { family: "Rubik"; pixelSize: 13; weight: disp.modelData.connected ? Font.DemiBold : Font.Normal }
                    }
                    Text {
                        visible: disp.modelData.batteryAvailable && disp.modelData.connected
                        text: "󰁹 " + Math.round(disp.modelData.battery * 100) + "%"
                        color: "#8c8270"
                        font { family: "CaskaydiaCove Nerd Font"; pixelSize: 11 }
                    }
                    Text {
                        text: disp.ocupado ? "conectando…" : disp.modelData.connected ? "conectado" : disp.modelData.paired ? "vinculado" : "nuevo"
                        color: disp.modelData.connected ? "#e6b450" : "#8c8270"
                        font { family: "Rubik"; pixelSize: 11 }
                    }
                }
                MouseArea {
                    id: area
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        const d = disp.modelData;
                        if (d.connected) d.disconnect();
                        else if (d.paired) d.connect();
                        else { d.trusted = true; d.pair(); }
                    }
                }
            }
        }
    }
}
