// Burbuja de vidrio estilo Apple (modo Familiar): brillo suave arriba y un aro de luz en el
// borde, fuerte arriba a la izquierda, casi nada en medio y un reflejo abajo.
// Uso: dentro de un Rectangle →  Vidrio { radio: parent.radius; activo: Modo.familiar }
// (osd/Vidrio.qml es un enlace a este archivo)
import QtQuick

Item {
    id: vidrio
    property real radio: 20
    property bool activo: true
    anchors.fill: parent
    visible: activo

    // Brillo suave en la mitad de arriba
    Rectangle {
        anchors { left: parent.left; right: parent.right; top: parent.top }
        height: Math.min(parent.height * 0.55, 160)
        radius: vidrio.radio
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.08) }
            GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0) }
        }
    }

    // Aro de luz
    Canvas {
        anchors.fill: parent
        // blanco con transparencia (armado así para que tema.py no lo tiña)
        function blanco(a) { return "rgba" + "(255, 255, 255, " + a + ")"; }
        onPaint: {
            const c = getContext("2d");
            c.reset();
            const o = 0.75, w = width, h = height, r = Math.max(0, vidrio.radio - o);
            const g = c.createLinearGradient(0, 0, w * 0.3, h);
            g.addColorStop(0.0, blanco(0.7));
            g.addColorStop(0.5, blanco(0.08));
            g.addColorStop(1.0, blanco(0.32));
            c.strokeStyle = g;
            c.lineWidth = 1.3;
            c.beginPath();
            c.roundedRect(o, o, w - 2 * o, h - 2 * o, r, r);
            c.stroke();
        }
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        onVisibleChanged: requestPaint()
    }
}
