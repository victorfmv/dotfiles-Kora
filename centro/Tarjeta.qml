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

    implicitHeight: contenido.implicitHeight + 24
    radius: 16
    color: emergente ? Qt.rgba(0.08, 0.07, 0.06, 0.94) : Qt.rgba(1, 1, 1, area.containsMouse ? 0.08 : 0.05)
    border.width: emergente ? 1.5 : 0
    border.color: notif?.urgency === 2 ? "#e06c5a" : Qt.rgba(0.9, 0.7, 0.31, 0.6)
    Behavior on color { ColorAnimation { duration: 140 } }

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
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 12 }
        spacing: 12

        Rectangle {
            width: 38; height: 38; radius: 11
            color: Qt.rgba(1, 1, 1, 0.06)
            clip: true
            Image {
                anchors.fill: parent
                anchors.margins: raiz.notif?.image ? 0 : 5
                source: raiz.iconoApp
                fillMode: Image.PreserveAspectCrop
                sourceSize { width: 76; height: 76 }
                visible: status === Image.Ready
            }
            Text {
                anchors.centerIn: parent
                visible: !raiz.iconoApp
                text: "󰂚"
                color: "#e6b450"
                font { family: "CaskaydiaCove Nerd Font"; pixelSize: 18 }
            }
        }

        Column {
            width: parent.width - 38 - 12 - 26
            spacing: 3

            Text {
                width: parent.width
                text: (raiz.notif?.appName || "Sistema") + (raiz.hace ? "  ·  " + raiz.hace : "")
                color: "#8c8270"
                elide: Text.ElideRight
                font { family: "Rubik"; pixelSize: 11 }
            }
            Text {
                width: parent.width
                text: raiz.notif?.summary ?? ""
                color: "#f5ebd8"
                elide: Text.ElideRight
                font { family: "Rubik"; pixelSize: 14; weight: Font.Medium }
            }
            Text {
                width: parent.width
                visible: text !== ""
                text: raiz.notif?.body ?? ""
                textFormat: Text.StyledText
                color: "#c9bfad"
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
        width: 22; height: 22; radius: 11
        color: x_area.containsMouse ? Qt.rgba(1, 1, 1, 0.14) : "transparent"
        opacity: area.containsMouse || x_area.containsMouse || raiz.emergente ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 120 } }
        Text {
            anchors.centerIn: parent
            text: "󰅖"
            color: "#c9bfad"
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
