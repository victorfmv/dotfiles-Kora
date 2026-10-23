// Menú de Ajustes: atajos a apps gráficas de configuración (nada de terminal).
import QtQuick
import QtQuick.Layouts
import Quickshell

Rectangle {
    id: raiz
    signal abrio()          // para que el panel se cierre al abrir una app

    readonly property var apps: [
        { ic: "󰖩", nombre: "Redes y WiFi", cmd: ["nm-connection-editor"] },
        { ic: "󰂯", nombre: "Bluetooth",    cmd: ["blueman-manager"] },
        { ic: "󰕾", nombre: "Sonido",       cmd: ["pavucontrol"] },
        { ic: "󰏘", nombre: "Apariencia",   cmd: ["nwg-look"] },
        { ic: "󰍛", nombre: "Sistema",      cmd: ["mission-center"] },
        { ic: "󰸉", nombre: "Fondo",        cmd: ["sh", "-c", "~/.config/hypr-kora/scripts/wallpaper.sh pick"] }
    ]

    implicitHeight: col.implicitHeight + 24
    radius: 18
    color: Qt.rgba(1, 1, 1, 0.04)
    border.width: 1; border.color: Qt.rgba(1, 0.9, 0.7, 0.07)

    ColumnLayout {
        id: col
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 12 }
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            Text { text: "󰒓"; color: "#e6b450"; font { family: "CaskaydiaCove Nerd Font"; pixelSize: 16 } }
            Text {
                Layout.fillWidth: true
                text: "  Ajustes"
                color: "#fff8ec"
                font { family: "Rubik"; pixelSize: 14; weight: Font.DemiBold }
            }
        }

        GridLayout {
            Layout.fillWidth: true
            columns: 3
            rowSpacing: 8; columnSpacing: 8

            Repeater {
                model: raiz.apps

                Rectangle {
                    required property var modelData
                    Layout.fillWidth: true
                    Layout.preferredHeight: 70
                    radius: 14
                    color: Qt.rgba(1, 0.95, 0.85, area.containsMouse ? 0.08 : 0.025)
                    border.width: 1
                    border.color: area.containsMouse ? Qt.rgba(0.9, 0.7, 0.31, 0.6) : Qt.rgba(1, 0.9, 0.7, 0.06)
                    scale: area.pressed ? 0.95 : 1
                    Behavior on color { ColorAnimation { duration: 120 } }
                    Behavior on scale { NumberAnimation { duration: 110 } }

                    Column {
                        anchors.centerIn: parent
                        spacing: 5
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: modelData.ic
                            color: area.containsMouse ? "#e6b450" : "#ece4d4"
                            font { family: "CaskaydiaCove Nerd Font"; pixelSize: 20 }
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: modelData.nombre
                            color: "#ece4d4"
                            font { family: "Rubik"; pixelSize: 11 }
                        }
                    }
                    MouseArea {
                        id: area
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: { raiz.abrio(); Quickshell.execDetached(modelData.cmd); }
                    }
                }
            }
        }
    }
}
