// Menú de Ajustes: actualizaciones del sistema y atajos a apps gráficas (nada de terminal).
// La contraseña se pide con la ventanita de hyprpolkitagent (pkexec).
// Si una app no está instalada, el botón dice "Instalar" y la instala con un clic.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Rectangle {
    id: raiz
    property bool abierto: false
    signal abrio()          // para que el panel se cierre al abrir una app

    readonly property var sistema: [
        { ic: "󰄨", nombre: "Monitor",       desc: "Qué app gasta más",    pkg: "mission-center",          cmd: ["mission-center"] },
        { ic: "󰏓", nombre: "Instalar apps", desc: "Buscar programas", pkg: "cachyos-packageinstaller", cmd: ["cachyos-pi"] },
        { ic: "󰃢", nombre: "Mantenimiento", desc: "Limpiar y arreglar",  pkg: "cachyos-hello",           cmd: ["cachyos-hello"] },
        { ic: "󰻠", nombre: "Kernel",        desc: "Cambiar de kernel",  pkg: "cachyos-kernel-manager",  cmd: ["cachyos-kernel-manager"] }
    ]
    readonly property var dispositivos: [
        { ic: "󰖩", nombre: "Redes",      desc: "Redes guardadas",  pkg: "nm-connection-editor", cmd: ["nm-connection-editor"] },
        { ic: "󰂯", nombre: "Bluetooth",  desc: "Audífonos y más",   pkg: "blueman",              cmd: ["blueman-manager"] },
        { ic: "󰕾", nombre: "Sonido",     desc: "Bocinas y micrófono",   pkg: "pavucontrol",          cmd: ["pavucontrol"] },
        { ic: "󰏘", nombre: "Apariencia", desc: "Tema, íconos y cursor",       pkg: "nwg-look",             cmd: ["nwg-look"] }
    ]

    // ───────────── Qué apps están instaladas ─────────────
    property var instalados: ({})
    property string instalando: ""       // paquete que se está instalando ahora
    Process {
        id: revisarApps
        command: ["pacman", "-Qq"].concat(raiz.sistema.concat(raiz.dispositivos).map(a => a.pkg))
        stdout: StdioCollector {
            onStreamFinished: {
                const s = {};
                for (const p of text.trim().split("\n")) if (p) s[p] = true;
                raiz.instalados = s;
            }
        }
    }
    Process {
        id: instalar
        property var app: null
        command: ["pkexec", "pacman", "-S", "--needed", "--noconfirm", app?.pkg ?? ""]
        onExited: code => {
            raiz.instalando = "";
            revisarApps.running = true;
            if (code === 0) Quickshell.execDetached(app.cmd);
            else if (code !== 126 && code !== 127)
                Quickshell.execDetached(["notify-send", "-a", "Ajustes", "No se pudo instalar " + app.nombre, "Revisa tu conexión e inténtalo otra vez."]);
        }
    }
    function usar(app) {
        if (instalados[app.pkg]) { abrio(); Quickshell.execDetached(app.cmd); return; }
        if (instalando) return;
        instalando = app.pkg;
        instalar.app = app;
        instalar.running = true;
    }

    // ───────────── Actualizaciones ─────────────
    property int pendientes: -1          // -1 = revisando
    property bool actualizando: false
    property string avance: ""
    property string resultado: ""        // "ok" | "error" | ""
    Process {
        id: buscar
        command: ["checkupdates"]
        stdout: StdioCollector { onStreamFinished: raiz.pendientes = text.trim() ? text.trim().split("\n").length : 0 }
        onExited: code => { if (code !== 0 && code !== 2) raiz.pendientes = -2; }   // -2 = sin internet / error
    }
    Process {
        id: actualizar
        command: ["pkexec", "pacman", "-Syu", "--noconfirm"]
        stdout: SplitParser { onRead: l => { if (l.trim()) raiz.avance = l.trim(); } }
        stderr: SplitParser { onRead: l => { if (l.trim()) raiz.avance = l.trim(); } }
        onExited: code => {
            raiz.actualizando = false;
            raiz.avance = "";
            if (code === 126 || code === 127) return;          // canceló la contraseña
            raiz.resultado = code === 0 ? "ok" : "error";
            Quickshell.execDetached(["notify-send", "-a", "Actualizaciones",
                code === 0 ? "Sistema actualizado" : "La actualización no terminó",
                code === 0 ? "Todo al día. Si se actualizó el kernel, reinicia cuando puedas." : "Abre Mantenimiento o pídele ayuda a Claude."]);
            buscar.running = true;
        }
    }
    function empezarActualizacion() {
        if (actualizando || pendientes <= 0) return;
        resultado = "";
        avance = "Esperando tu contraseña…";
        actualizando = true;
        actualizar.running = true;
    }

    onAbiertoChanged: if (abierto) {
        revisarApps.running = true;
        if (!actualizando) { pendientes = -1; buscar.running = true; }
    }

    implicitHeight: col.implicitHeight + 24
    radius: 18
    color: Qt.rgba(1, 1, 1, 0.04)
    border.width: 1; border.color: Qt.rgba(0.991, 0.76, 0.669, 0.07)

    ColumnLayout {
        id: col
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 12 }
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            Text { text: "󰒓"; color: "#e1754b"; font { family: "CaskaydiaCove Nerd Font"; pixelSize: 16 } }
            Text {
                Layout.fillWidth: true
                text: "  Ajustes"
                color: "#fef4ed"
                font { family: "Rubik"; pixelSize: 14; weight: Font.DemiBold }
            }
        }

        // ── Tarjeta de actualizaciones ──
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: actCol.implicitHeight + 24
            radius: 14
            readonly property bool hay: raiz.pendientes > 0 || raiz.actualizando
            color: hay ? Qt.rgba(0.879, 0.457, 0.291, 0.14) : Qt.rgba(0.993, 0.914, 0.857, 0.025)
            border.width: 1
            border.color: hay ? Qt.rgba(0.879, 0.457, 0.291, 0.5) : Qt.rgba(0.991, 0.76, 0.669, 0.06)

            ColumnLayout {
                id: actCol
                anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; margins: 12 }
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10
                    Text {
                        id: iconoAct
                        text: raiz.actualizando ? "󰚰" : raiz.pendientes > 0 ? "󰚰" : raiz.pendientes === -2 ? "󰖪" : raiz.pendientes === -1 ? "󰑓" : "󰄬"
                        color: raiz.pendientes === 0 && !raiz.actualizando ? "#8fbf7a" : "#e1754b"
                        font { family: "CaskaydiaCove Nerd Font"; pixelSize: 22 }
                        RotationAnimation on rotation {
                            running: raiz.pendientes === -1 || raiz.actualizando
                            from: 0; to: 360; duration: 1400; loops: Animation.Infinite
                            onRunningChanged: if (!running) iconoAct.rotation = 0
                        }
                    }
                    Column {
                        Layout.fillWidth: true
                        spacing: 2
                        Text {
                            width: parent.width
                            elide: Text.ElideRight
                            text: raiz.actualizando ? "Actualizando…"
                                : raiz.pendientes === -1 ? "Buscando actualizaciones…"
                                : raiz.pendientes === -2 ? "No se pudo revisar"
                                : raiz.pendientes === 0 ? (raiz.resultado === "ok" ? "¡Listo! Sistema actualizado" : "Tu sistema está al día")
                                : raiz.pendientes + (raiz.pendientes === 1 ? " actualización disponible" : " actualizaciones disponibles")
                            color: "#fef4ed"
                            font { family: "Rubik"; pixelSize: 13; weight: Font.DemiBold }
                        }
                        Text {
                            width: parent.width
                            elide: Text.ElideRight
                            text: raiz.actualizando ? raiz.avance
                                : raiz.resultado === "error" ? "Algo falló; intenta otra vez"
                                : raiz.pendientes === -2 ? "Revisa tu conexión a internet"
                                : raiz.pendientes > 0 ? "Programas, drivers y seguridad"
                                : "Paquetes oficiales de CachyOS"
                            color: raiz.resultado === "error" && !raiz.actualizando ? "#f2c14e" : "#8b7c71"
                            font { family: "Rubik"; pixelSize: 11 }
                        }
                    }
                    Rectangle {
                        visible: raiz.pendientes > 0 && !raiz.actualizando
                        Layout.preferredWidth: botonTxt.implicitWidth + 24
                        Layout.preferredHeight: 32
                        radius: 16
                        color: actArea.containsMouse ? "#ef9572" : "#e1754b"
                        scale: actArea.pressed ? 0.94 : 1
                        Behavior on scale { NumberAnimation { duration: 110 } }
                        Text {
                            id: botonTxt
                            anchors.centerIn: parent
                            text: "Actualizar"
                            color: "#14110f"
                            font { family: "Rubik"; pixelSize: 12; weight: Font.DemiBold }
                        }
                        MouseArea { id: actArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: raiz.empezarActualizacion() }
                    }
                }

                // Barrita animada mientras actualiza
                Rectangle {
                    visible: raiz.actualizando
                    Layout.fillWidth: true
                    Layout.preferredHeight: 4
                    radius: 2
                    clip: true
                    color: Qt.rgba(0.991, 0.76, 0.669, 0.08)
                    Rectangle {
                        width: parent.width * 0.3; height: parent.height; radius: 2
                        color: "#e1754b"
                        NumberAnimation on x {
                            running: raiz.actualizando
                            from: -parent.width * 0.3; to: parent.width
                            duration: 1300; loops: Animation.Infinite; easing.type: Easing.InOutQuad
                        }
                    }
                }
            }
        }

        // ── Secciones de apps ──
        Repeater {
            model: [
                { titulo: "Sistema", apps: raiz.sistema },
                { titulo: "Dispositivos y estilo", apps: raiz.dispositivos }
            ]

            ColumnLayout {
                required property var modelData
                Layout.fillWidth: true
                Layout.topMargin: 4
                spacing: 8

                Text {
                    text: modelData.titulo.toUpperCase()
                    color: "#8b7c71"
                    font { family: "Rubik"; pixelSize: 10; weight: Font.DemiBold; letterSpacing: 1.2 }
                }

                GridLayout {
                    Layout.fillWidth: true
                    columns: 2
                    rowSpacing: 8; columnSpacing: 8

                    Repeater {
                        model: modelData.apps

                        Rectangle {
                            id: boton
                            required property var modelData
                            readonly property bool falta: raiz.instalados[modelData.pkg] !== true
                            readonly property bool cargando: raiz.instalando === modelData.pkg
                            Layout.fillWidth: true
                            Layout.preferredWidth: 1
                            Layout.preferredHeight: 58
                            radius: 14
                            color: Qt.rgba(0.993, 0.914, 0.857, area.containsMouse ? 0.08 : 0.025)
                            border.width: 1
                            border.color: area.containsMouse ? Qt.rgba(0.879, 0.457, 0.291, 0.6) : Qt.rgba(0.991, 0.76, 0.669, 0.06)
                            scale: area.pressed ? 0.96 : 1
                            Behavior on color { ColorAnimation { duration: 120 } }
                            Behavior on scale { NumberAnimation { duration: 110 } }

                            RowLayout {
                                anchors { fill: parent; leftMargin: 12; rightMargin: 10 }
                                spacing: 10
                                Rectangle {
                                    Layout.preferredWidth: 34; Layout.preferredHeight: 34
                                    radius: 11
                                    color: area.containsMouse ? Qt.rgba(0.879, 0.457, 0.291, 0.22) : Qt.rgba(0.993, 0.914, 0.857, 0.06)
                                    Text {
                                        anchors.centerIn: parent
                                        text: boton.modelData.ic
                                        color: area.containsMouse ? "#e1754b" : "#ebded5"
                                        opacity: boton.falta ? 0.55 : 1
                                        font { family: "CaskaydiaCove Nerd Font"; pixelSize: 18 }
                                    }
                                }
                                Column {
                                    Layout.fillWidth: true
                                    spacing: 2
                                    Text {
                                        width: parent.width
                                        elide: Text.ElideRight
                                        text: boton.modelData.nombre
                                        color: boton.falta ? "#b6a69a" : "#fef4ed"
                                        font { family: "Rubik"; pixelSize: 12; weight: Font.DemiBold }
                                    }
                                    Text {
                                        width: parent.width
                                        elide: Text.ElideRight
                                        text: boton.cargando ? "Instalando…" : boton.falta ? "󰇚 Instalar" : boton.modelData.desc
                                        color: boton.falta || boton.cargando ? "#e1754b" : "#8b7c71"
                                        font { family: boton.falta && !boton.cargando ? "CaskaydiaCove Nerd Font" : "Rubik"; pixelSize: 10 }
                                    }
                                }
                            }
                            MouseArea {
                                id: area
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: raiz.usar(boton.modelData)
                            }
                        }
                    }
                }
            }
        }
    }
}
