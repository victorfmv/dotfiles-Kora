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
    readonly property color acento: urgente ? "#e85d9e" : "#e68750"

    implicitHeight: contenido.implicitHeight + 26
    radius: 16
    // Más clara que el panel, con degradado para que no se vea plana
    gradient: Gradient {
        GradientStop { position: 0.0; color: raiz.emergente ? Qt.rgba(0.116, 0.087, 0.133, Modo.op(0.98, 0.74)) : Qt.rgba(0.169, 0.126, 0.195, area.containsMouse ? Modo.op(1, 0.7) : Modo.op(0.92, 0.5)) }
        GradientStop { position: 1.0; color: raiz.emergente ? Qt.rgba(0.073, 0.058, 0.082, Modo.op(0.98, 0.74)) : Qt.rgba(0.118, 0.092, 0.133, area.containsMouse ? Modo.op(1, 0.7) : Modo.op(0.92, 0.5)) }
    }
    border.width: 1
    border.color: emergente ? Qt.rgba(0.9, 0.526, 0.31, 0.55) : Qt.rgba(1, 0.81, 0.7, area.containsMouse ? 0.16 : 0.08)

    readonly property string iconoApp: {
        const img = notif?.image ?? "";
        if (img) return img;
        const ic = notif?.appIcon ?? "";
        if (ic.startsWith("/") || ic.startsWith("file:")) return ic;
        // Ícono del tema, o el del lanzador (.desktop) de la app
        const entrada = DesktopEntries.byId(notif?.desktopEntry ?? "") ?? DesktopEntries.heuristicLookup(notif?.appName ?? "");
        for (const c of [ic, entrada?.icon ?? "", (notif?.appName ?? "").toLowerCase()])
            if (c && Quickshell.hasThemeIcon(c)) return Quickshell.iconPath(c);
        return "";
    }

    // Barra de acento a la izquierda
    Rectangle {
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
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 13; leftMargin: 15 }
        spacing: 12

        Rectangle {
            width: 40; height: 40; radius: 12
            color: Qt.rgba(0.9, 0.526, 0.31, 0.14)
            border.width: 1; border.color: Qt.rgba(0.9, 0.526, 0.31, 0.25)
            clip: true
            Image {
                anchors.fill: parent
                anchors.margins: raiz.notif?.image ? 0 : 6
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
            width: parent.width - 40 - 12 - 26
            spacing: 4

            Row {
                spacing: 6
                Text {
                    text: (raiz.notif?.appName || "Sistema").toUpperCase()
                    color: raiz.acento
                    font { family: "Rubik"; pixelSize: 10; weight: Font.DemiBold; letterSpacing: 0.8 }
                }
                Text {
                    visible: raiz.hace !== ""
                    text: "·  " + raiz.hace
                    color: "#826e8e"
                    font { family: "Rubik"; pixelSize: 10 }
                }
            }
            Text {
                width: parent.width
                text: raiz.notif?.summary ?? ""
                color: "#f8ecff"
                elide: Text.ElideRight
                font { family: "Rubik"; pixelSize: 14; weight: Font.DemiBold }
            }
            Text {
                width: parent.width
                visible: text !== ""
                text: raiz.notif?.body ?? ""
                textFormat: Text.StyledText
                color: "#af9abb"
                wrapMode: Text.Wrap
                maximumLineCount: raiz.emergente ? 3 : 2
                elide: Text.ElideRight
                font { family: "Rubik"; pixelSize: 12 }
            }
        }
    }

    // Quitar
    Rectangle {
        anchors { right: parent.right; top: parent.top; margins: 10 }
        width: 24; height: 24; radius: 12
        color: x_area.containsMouse ? Qt.rgba(0.9, 0.526, 0.31, 0.25) : Qt.rgba(1, 1, 1, 0.06)
        opacity: area.containsMouse || x_area.containsMouse || raiz.emergente ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 120 } }
        Text {
            anchors.centerIn: parent
            text: "󰅖"
            color: "#e4d2ee"
            font { family: "CaskaydiaCove Nerd Font"; pixelSize: 13 }
        }
        MouseArea {
            id: x_area
            anchors.fill: parent
            hoverEnabled: true
            onClicked: raiz.cerrar()
        }
    }
}
