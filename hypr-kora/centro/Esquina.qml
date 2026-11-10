// Panel pegado a la esquina superior derecha de la pantalla (estilo Caelestia): el panel toca la
// orilla de arriba y la de la derecha, y donde se une con cada orilla hace una curva hacia adentro
// ("oreja"), así parece que sale de la esquina. La esquina de afuera (abajo a la izquierda) es redonda.
// Se pone llenando la ventana; ancho/alto son los del panel, medidos desde la esquina.
// abajo: true → la esquina de ABAJO a la derecha (la misma forma volteada).
import QtQuick
import QtQuick.Shapes

Shape {
    id: forma
    property real ancho: 400        // ancho del panel
    property real alto: 300         // alto del panel (animarlo hace que crezca desde la esquina)
    property real oreja: 24
    property real esquina: 26
    property color relleno: Qt.rgba(0.073, 0.058, 0.082, 0.9)
    property color borde: Qt.rgba(1, 1, 1, 0.2)
    property bool abajo: false

    transform: Scale { yScale: forma.abajo ? -1 : 1; origin.y: forma.height / 2 }

    anchors.fill: parent
    preferredRendererType: Shape.CurveRenderer
    visible: alto > 0.5

    readonly property real derecha: width
    readonly property real e: Math.min(oreja, alto, ancho)
    readonly property real r: Math.min(esquina, alto / 2, ancho / 2)
    readonly property real izq: derecha - ancho

    ShapePath {
        fillColor: forma.relleno
        strokeColor: forma.borde
        strokeWidth: 1
        startX: forma.izq - forma.e; startY: 0
        // oreja sobre la orilla de arriba
        PathArc { x: forma.izq; y: forma.e; radiusX: forma.e; radiusY: forma.e; direction: PathArc.Clockwise }
        PathLine { x: forma.izq; y: forma.alto - forma.r }
        PathArc { x: forma.izq + forma.r; y: forma.alto; radiusX: forma.r; radiusY: forma.r; direction: PathArc.Counterclockwise }
        PathLine { x: forma.derecha - forma.e; y: forma.alto }
        // oreja sobre la orilla derecha
        PathArc { x: forma.derecha; y: forma.alto + forma.e; radiusX: forma.e; radiusY: forma.e; direction: PathArc.Clockwise }
        PathLine { x: forma.derecha; y: 0 }
        PathLine { x: forma.izq - forma.e; y: 0 }
    }
}
