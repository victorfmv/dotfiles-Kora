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
        GradientStop { position: 0.0; color: raiz.activo ? "#f3cc78" : Qt.rgba(1, 0.95, 0.85, area.containsMouse ? 0.13 : 0.08) }
        GradientStop { position: 1.0; color: raiz.activo ? "#d39a35" : Qt.rgba(1, 0.95, 0.85, area.containsMouse ? 0.07 : 0.03) }
    }
    scale: area.pressed ? 0.94 : 1
    Behavior on scale { NumberAnimation { duration: 110 } }

    Text {
        anchors.centerIn: parent
        text: raiz.icono
        color: raiz.activo ? "#14120f" : "#ece4d4"
        font { family: "CaskaydiaCove Nerd Font"; pixelSize: 18 }
    }

    // Flechita de "tiene menú"
    Text {
        visible: raiz.abre
        anchors { right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter }
        text: raiz.desplegado ? "󰅃" : "󰅀"
        color: raiz.activo ? "#14120f" : "#8c8270"
        font { family: "CaskaydiaCove Nerd Font"; pixelSize: 12 }
    }
    // Borde: claro si está encendido, blanco si su menú está abierto
    border.width: desplegado ? 2 : 1
    border.color: desplegado ? "#fff8ec" : activo ? "#f7dc9e" : Qt.rgba(1, 0.9, 0.7, area.containsMouse ? 0.25 : 0.10)

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: raiz.clic()
    }
}
