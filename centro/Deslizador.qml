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
    color: Qt.rgba(0, 0, 0, 0.28)
    border.width: 1
    border.color: Qt.rgba(0.786, 0.914, 0.994, 0.10)
    clip: true

    Rectangle {
        anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
        width: Math.max(parent.height, parent.width * Math.max(0, Math.min(1, raiz.value)))
        radius: parent.radius
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: raiz.apagado ? "#45505b" : "#53a5d9" }
            GradientStop { position: 1.0; color: raiz.apagado ? "#54606c" : "#8dcbf2" }
        }
        border.width: 1
        border.color: raiz.apagado ? "#616e7b" : "#b3ddf7"
        Behavior on width { enabled: !arrastre.pressed; NumberAnimation { duration: 120 } }
        // Brillo arriba
        Rectangle {
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 3 }
            height: parent.height / 2 - 3
            radius: height / 2
            color: Qt.rgba(1, 1, 1, 0.16)
        }
    }

    Text {
        anchors { right: parent.right; rightMargin: 14; verticalCenter: parent.verticalCenter }
        text: raiz.icono
        color: raiz.value > 0.88 ? "#0f1114" : "#d3e0ed"
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
