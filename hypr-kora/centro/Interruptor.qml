// Botón redondo de encendido/apagado (WiFi, Bluetooth, sonido…)
import QtQuick

Rectangle {
    id: raiz
    property bool activo: false
    property string icono: ""
    property string nombre: ""
    property bool abre: false          // tiene menú: muestra una flechita
    property bool desplegado: false
    signal clic()

    implicitHeight: 46
    radius: height / 2
    gradient: Gradient {
        GradientStop { position: 0.0; color: raiz.activo ? "#b0d4c2" : Qt.rgba(0.906, 0.944, 0.906, area.containsMouse ? 0.13 : 0.08) }
        GradientStop { position: 1.0; color: raiz.activo ? "#78aa91" : Qt.rgba(0.906, 0.944, 0.906, area.containsMouse ? 0.07 : 0.03) }
    }
    scale: area.pressed ? 0.94 : 1
    Behavior on scale { NumberAnimation { duration: 110 } }

    Text {
        anchors.centerIn: parent
        text: raiz.icono
        color: raiz.activo ? "#111211" : "#dde3dd"
        font { family: "CaskaydiaCove Nerd Font"; pixelSize: 18 }
    }

    // Flechita de "tiene menú"
    Text {
        visible: raiz.abre
        anchors { right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter }
        text: raiz.desplegado ? "󰅃" : "󰅀"
        color: raiz.activo ? "#111211" : "#7b827b"
        font { family: "CaskaydiaCove Nerd Font"; pixelSize: 12 }
    }
    // Borde: claro si está encendido, blanco si su menú está abierto
    border.width: desplegado ? 2 : 1
    border.color: desplegado ? "#f3f8f3" : activo ? "#cbe3d7" : Qt.rgba(0.865, 0.935, 0.9, area.containsMouse ? 0.25 : 0.10)

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: raiz.clic()
    }
}
