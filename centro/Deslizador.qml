// Deslizador tipo pastilla: relleno dorado + ícono al final. value de 0 a 1.
import QtQuick

Rectangle {
    id: raiz
    property real value: 0
    property string icono: ""
    property bool apagado: false
    signal mover(real valor)

    implicitHeight: 38
    radius: height / 2
    color: Qt.rgba(1, 1, 1, 0.07)
    clip: true

    Rectangle {
        anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
        width: Math.max(parent.height, parent.width * Math.max(0, Math.min(1, raiz.value)))
        radius: parent.radius
        color: raiz.apagado ? "#6b6255" : "#e6b450"
        Behavior on width { enabled: !arrastre.pressed; NumberAnimation { duration: 120 } }
        Behavior on color { ColorAnimation { duration: 150 } }
    }

    Text {
        anchors { right: parent.right; rightMargin: 14; verticalCenter: parent.verticalCenter }
        text: raiz.icono
        color: raiz.value > 0.88 ? "#14120f" : "#ece4d4"
        font { family: "CaskaydiaCove Nerd Font"; pixelSize: 16 }
    }

    MouseArea {
        id: arrastre
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        function aplicar(x) { raiz.mover(Math.max(0, Math.min(1, x / width))); }
        onPressed: m => aplicar(m.x)
        onPositionChanged: m => { if (pressed) aplicar(m.x); }
        onWheel: w => raiz.mover(Math.max(0, Math.min(1, raiz.value + (w.angleDelta.y > 0 ? 0.05 : -0.05))))
    }
}
