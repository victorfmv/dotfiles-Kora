// Interruptor deslizante pequeño (encendido = dorado)
import QtQuick

Rectangle {
    id: raiz
    property bool encendido: false
    signal cambiar()

    implicitWidth: 44; implicitHeight: 24
    radius: height / 2
    color: encendido ? "#e6b450" : Qt.rgba(1, 1, 1, 0.12)
    Behavior on color { ColorAnimation { duration: 150 } }

    Rectangle {
        width: 18; height: 18; radius: 9
        anchors.verticalCenter: parent.verticalCenter
        x: raiz.encendido ? parent.width - width - 3 : 3
        color: raiz.encendido ? "#14120f" : "#ece4d4"
        Behavior on x { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
    }
    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: raiz.cambiar() }
}
