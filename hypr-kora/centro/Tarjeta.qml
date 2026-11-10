// Una notificación: ícono, app · hace cuánto, título, texto y botón para quitarla.
// Se usa en el panel y en las ventanitas emergentes.
import QtQuick
import Quickshell

Rectangle {
    id: raiz
    required property var notif
    property string hace: ""
    property bool emergente: false
    signal cerrar()

    readonly property bool urgente: notif?.urgency === 2
    // Modo Familiar: estilo de notificación de Apple (ícono limpio, app y hora tenues,
    // sin barra de color, borde fino claro, la X aparece arriba a la izquierda al pasar el ratón)
    readonly property bool mac: Modo.familiar
    readonly property color acento: urgente ? "#e85d9e" : "#e68750"

    implicitHeight: contenido.implicitHeight + 26
    radius: mac ? 24 : 16
    // Más clara que el panel, con degradado para que no se vea plana
    gradient: Gradient {
        GradientStop { position: 0.0; color: raiz.mac ? Qt.rgba(0.116, 0.087, 0.133, area.containsMouse ? 0.5 : 0.38) : raiz.emergente ? Qt.rgba(0.116, 0.087, 0.133, Modo.op(0.98, 0.74)) : Qt.rgba(0.169, 0.126, 0.195, area.containsMouse ? Modo.op(1, 0.7) : Modo.op(0.92, 0.5)) }
        GradientStop { position: 1.0; color: raiz.mac ? Qt.rgba(0.073, 0.058, 0.082, area.containsMouse ? 0.58 : 0.46) : raiz.emergente ? Qt.rgba(0.073, 0.058, 0.082, Modo.op(0.98, 0.74)) : Qt.rgba(0.118, 0.092, 0.133, area.containsMouse ? Modo.op(1, 0.7) : Modo.op(0.92, 0.5)) }
    }
    border.width: mac ? 0 : 1   // en modo mac el borde es el aro de vidrio de abajo
    border.color: mac ? Qt.rgba(1, 0.81, 0.7, area.containsMouse || x_area.containsMouse ? 0.22 : 0.14)
                      : emergente ? Qt.rgba(0.9, 0.526, 0.31, 0.55) : Qt.rgba(1, 0.81, 0.7, area.containsMouse ? 0.16 : 0.08)

    readonly property string iconoApp: {
        const img = notif?.image ?? "";
        // "image://icon/<nombre>" de un ícono que no existe sale como cuadro morado: entonces buscar otro
        if (img && !(img.startsWith("image://icon/") && !Quickshell.hasThemeIcon(img.slice(13)))) return img;
        const ic = notif?.appIcon ?? "";
        if (ic.startsWith("/") || ic.startsWith("file:")) return ic;
        // Ícono del tema, o el del lanzador (.desktop) de la app
        const pedido = img.startsWith("image://icon/") ? img.slice(13) : "";
        const entrada = DesktopEntries.byId(notif?.desktopEntry ?? "") ?? DesktopEntries.byId(pedido)
                     ?? DesktopEntries.heuristicLookup(notif?.appName ?? "") ?? DesktopEntries.heuristicLookup(pedido);
        for (const c of [ic, entrada?.icon ?? "", (notif?.appName ?? "").toLowerCase()])
            if (c && Quickshell.hasThemeIcon(c)) return Quickshell.iconPath(c);
        return "";
    }

    // ── Burbuja de vidrio (modo Familiar, estilo Apple) ──
    // Brillo suave en la mitad de arriba
    Rectangle {
        visible: raiz.mac
        anchors { left: parent.left; right: parent.right; top: parent.top }
        height: parent.height * 0.55
        radius: parent.radius
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.09) }
            GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0) }
        }
    }
    // Aro de luz en el borde: fuerte arriba a la izquierda, casi nada en medio y un reflejo abajo
    Canvas {
        id: aro
        anchors.fill: parent
        visible: raiz.mac
        // blanco con transparencia (armado así para que tema.py no lo tiña)
        function blanco(a) { return "rgba" + "(255, 255, 255, " + a + ")"; }
        onPaint: {
            const c = getContext("2d");
            c.reset();
            const o = 0.75, w = width, h = height, r = raiz.radius - o;
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

    // Barra de acento a la izquierda
    Rectangle {
        visible: !raiz.mac
        anchors { left: parent.left; top: parent.top; bottom: parent.bottom; topMargin: 14; bottomMargin: 14; leftMargin: 0 }
        width: 3; radius: 2
        color: raiz.acento
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        onClicked: {
            const acc = raiz.notif?.actions?.find(a => a.identifier === "default");
            if (acc) acc.invoke();
            raiz.cerrar();
        }
    }

    Row {
        id: contenido
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 13; leftMargin: raiz.mac ? 13 : 15 }
        spacing: 12

        Rectangle {
            readonly property bool limpio: raiz.mac && raiz.iconoApp !== ""
            width: 40; height: 40; radius: raiz.mac ? 10 : 12
            color: limpio ? "transparent" : Qt.rgba(0.9, 0.526, 0.31, 0.14)
            border.width: limpio ? 0 : 1; border.color: Qt.rgba(0.9, 0.526, 0.31, 0.25)
            clip: true
            Image {
                anchors.fill: parent
                anchors.margins: raiz.notif?.image || raiz.mac ? 0 : 6
                source: raiz.iconoApp
                fillMode: Image.PreserveAspectCrop
                sourceSize { width: 80; height: 80 }
                visible: status === Image.Ready
            }
            Text {
                anchors.centerIn: parent
                visible: !raiz.iconoApp
                text: "󰂚"
                color: raiz.acento
                font { family: "CaskaydiaCove Nerd Font"; pixelSize: 19 }
            }
        }

        Column {
            width: parent.width - 40 - 12 - (raiz.mac ? 2 : 26)
            spacing: raiz.mac ? 2 : 4

            Item {
                width: parent.width
                height: app.implicitHeight
                Text {
                    id: app
                    text: raiz.mac ? (raiz.notif?.appName || "Sistema") : (raiz.notif?.appName || "Sistema").toUpperCase()
                    color: raiz.mac ? "#af9abb" : raiz.acento
                    font { family: "Rubik"; pixelSize: raiz.mac ? 11 : 10; weight: raiz.mac ? Font.Medium : Font.DemiBold; letterSpacing: raiz.mac ? 0 : 0.8 }
                }
                Text {
                    visible: raiz.hace !== ""
                    // Apple: la hora va a la derecha
                    x: raiz.mac ? parent.width - width : app.width + 6
                    text: raiz.mac ? raiz.hace : "·  " + raiz.hace
                    color: "#826e8e"
                    font { family: "Rubik"; pixelSize: raiz.mac ? 11 : 10 }
                }
            }
            Text {
                width: parent.width
                text: raiz.notif?.summary ?? ""
                color: "#f8ecff"
                elide: Text.ElideRight
                font { family: "Rubik"; pixelSize: raiz.mac ? 13.5 : 14; weight: Font.DemiBold }
            }
            Text {
                width: parent.width
                visible: text !== ""
                text: raiz.notif?.body ?? ""
                textFormat: Text.StyledText
                color: raiz.mac ? "#e4d2ee" : "#af9abb"
                wrapMode: Text.Wrap
                maximumLineCount: raiz.emergente ? 3 : 2
                elide: Text.ElideRight
                font { family: "Rubik"; pixelSize: 12 }
            }
        }
    }

    // Quitar
    Rectangle {
        // Apple: círculo chico arriba a la izquierda, solo al pasar el ratón
        x: raiz.mac ? 4 : parent.width - width - 10
        y: raiz.mac ? 4 : 10
        width: raiz.mac ? 20 : 24; height: width; radius: width / 2
        color: x_area.containsMouse ? Qt.rgba(0.9, 0.526, 0.31, 0.25) : raiz.mac ? Qt.rgba(0.073, 0.058, 0.082, 0.95) : Qt.rgba(1, 1, 1, 0.06)
        border.width: raiz.mac ? 1 : 0; border.color: Qt.rgba(1, 0.81, 0.7, 0.22)
        opacity: area.containsMouse || x_area.containsMouse || (raiz.emergente && !raiz.mac) ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 120 } }
        Text {
            anchors.centerIn: parent
            text: "󰅖"
            color: "#e4d2ee"
            font { family: "CaskaydiaCove Nerd Font"; pixelSize: raiz.mac ? 11 : 13 }
        }
        MouseArea {
            id: x_area
            anchors.fill: parent
            hoverEnabled: true
            onClicked: raiz.cerrar()
        }
    }
}
