// Botón redondo de encendido/apagado (WiFi, Bluetooth, sonido…)
import QtQuick

Rectangle {
    id: raiz
    property bool activo: false
    property string icono: ""
    property string nombre: ""
    signal clic()

    implicitHeight: 46
    radius: height / 2
    color: activo ? "#e6b450" : Qt.rgba(1, 1, 1, area.containsMouse ? 0.11 : 0.07)
    Behavior on color { ColorAnimation { duration: 160 } }
    scale: area.pressed ? 0.94 : 1
    Behavior on scale { NumberAnimation { duration: 110 } }

    Text {
        anchors.centerIn: parent
        text: raiz.icono
        color: raiz.activo ? "#14120f" : "#ece4d4"
        font { family: "CaskaydiaCove Nerd Font"; pixelSize: 18 }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: raiz.clic()
    }
}
