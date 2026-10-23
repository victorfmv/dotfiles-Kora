// Centro de control y notificaciones de Hyprland Kora (Quickshell).
// - Recibe las notificaciones (reemplaza a mako) y muestra las emergentes arriba a la derecha.
// - Super + X abre el panel: encabezado, deslizadores, interruptores, notificaciones y monitor.
// IPC:  qs -p ~/.config/hypr-kora/centro ipc call centro toggle|open|close|clear|dnd
// Waybar lee el contador de $XDG_RUNTIME_DIR/kora-notif (señal RTMIN+8).
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Bluetooth
import Quickshell.Networking
import Quickshell.Services.Pipewire
import Quickshell.Services.Notifications

ShellRoot {
    id: root

    readonly property color oro: "#e6b450"
    readonly property color crema: "#ece4d4"
    readonly property color tenue: "#8c8270"
    readonly property color fondo: "#14120f"
    readonly property string iconos: "CaskaydiaCove Nerd Font"

    property bool abierto: false
    property bool noMolestar: false
    property var llegadas: ({})          // id de notificación -> hora de llegada (ms)
    property real ahora: Date.now()

    // ───────────── Notificaciones ─────────────
    NotificationServer {
        id: servidor
        keepOnReload: true
        bodySupported: true
        bodyMarkupSupported: true
        bodyHyperlinksSupported: false
        imageSupported: true
        actionsSupported: true
        persistenceSupported: true
        onNotification: n => {
            n.tracked = true;
            root.llegadas[n.id] = Date.now();
            if (!root.noMolestar && !root.abierto)
                emergentes.insert(0, { notif: n });
        }
    }
    readonly property var lista: servidor.trackedNotifications.values.slice().reverse()
    readonly property int cuantas: lista.length

    ListModel { id: emergentes }

    function hace(n) {
        const t = llegadas[n?.id];
        if (!t) return "";
        const s = Math.floor((ahora - t) / 1000);
        if (s < 60) return "ahora";
        if (s < 3600) return Math.floor(s / 60) + " min";
        if (s < 86400) return Math.floor(s / 3600) + " h";
        return Math.floor(s / 86400) + " d";
    }
    function quitar(n) { if (n) n.dismiss(); }
    function limpiar() { for (const n of servidor.trackedNotifications.values.slice()) n.dismiss(); }

    // Contador para Waybar
    function avisarBarra() {
        Quickshell.execDetached(["sh", "-c",
            `printf '%s %s' ${cuantas} ${noMolestar ? 1 : 0} > "$XDG_RUNTIME_DIR/kora-notif"; pkill -RTMIN+8 waybar`]);
    }
    onCuantasChanged: avisarBarra()
    onNoMolestarChanged: avisarBarra()
    Component.onCompleted: avisarBarra()

    Timer { interval: 30000; running: true; repeat: true; onTriggered: root.ahora = Date.now() }

    // ───────────── Audio / brillo / sistema ─────────────
    readonly property var salida: Pipewire.defaultAudioSink
    readonly property var entrada: Pipewire.defaultAudioSource
    PwObjectTracker { objects: [root.salida, root.entrada] }

    property real brillo: 0.5
    Process {
        id: leerBrillo
        command: ["brightnessctl", "-m"]
        stdout: StdioCollector { onStreamFinished: root.brillo = parseInt(text.split(",")[3]) / 100 }
    }
    function ponerBrillo(v) {
        brillo = Math.max(0.02, v);
        Quickshell.execDetached(["brightnessctl", "-q", "set", Math.round(brillo * 100) + "%"]);
    }

    property real cpu: 0; property real ram: 0; property real disco: 0; property real temp: 0
    property var cpuPrevio: [0, 0]
    property string encendido: ""
    Process {
        id: leerSistema
        command: ["sh", "-c",
            "awk '/^cpu /{print $2+$3+$4+$5+$6+$7+$8, $5+$6}' /proc/stat;" +
            "awk '/MemTotal/{t=$2}/MemAvailable/{a=$2}END{print t, a}' /proc/meminfo;" +
            "df -P / | awk 'NR==2{print $5+0}';" +
            "for z in /sys/class/thermal/thermal_zone*; do [ \"$(cat $z/type)\" = x86_pkg_temp ] && cat $z/temp; done | head -1;" +
            "awk '{s=int($1); h=int(s/3600); m=int(s%3600/60); print (h? h \" h \" : \"\") m \" min\"}' /proc/uptime"]
        stdout: StdioCollector {
            onStreamFinished: {
                const l = text.trim().split("\n");
                const [tot, idle] = l[0].split(" ").map(Number);
                const [pt, pi] = root.cpuPrevio;
                if (pt) root.cpu = 1 - (idle - pi) / Math.max(1, tot - pt);
                root.cpuPrevio = [tot, idle];
                const [mt, ma] = l[1].split(" ").map(Number);
                root.ram = 1 - ma / mt;
                root.disco = Number(l[2]) / 100;
                root.temp = Number(l[3]) / 1000;
                root.encendido = l[4] ?? "";
            }
        }
    }
    Timer {
        interval: 2000; repeat: true; triggeredOnStart: true
        running: root.abierto
        onTriggered: leerSistema.running = true
    }

    // ───────────── Abrir / cerrar ─────────────
    function abrir() {
        leerBrillo.running = true;
        ahora = Date.now();
        emergentes.clear();
        abierto = true;
    }
    function cerrar() { abierto = false; menu = ""; }
    property string menu: ""            // "wifi" | "bt" | "" — menú desplegado en el panel

    IpcHandler {
        target: "centro"
        function toggle(): void { root.abierto ? root.cerrar() : root.abrir(); }
        function open(): void { root.abrir(); }
        function close(): void { root.cerrar(); }
        function clear(): void { root.limpiar(); }
        function dnd(): void { root.noMolestar = !root.noMolestar; }
        function menu(m: string): void { root.abrir(); root.menu = m; }
    }

    FileView {
        id: estadoWallpaper
        path: Quickshell.env("HOME") + "/.local/state/hypr-kora/wallpaper"
        watchChanges: true
        onFileChanged: reload()
    }

    // ───────────── Emergentes (arriba a la derecha) ─────────────
    PanelWindow {
        visible: emergentes.count > 0
        anchors { top: true; right: true }
        margins { top: 6; right: 10 }
        implicitWidth: 380
        implicitHeight: pila.implicitHeight + 10
        color: "transparent"
        exclusionMode: ExclusionMode.Normal
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "kora-notif"

        Column {
            id: pila
            width: parent.width
            spacing: 8
            move: Transition { NumberAnimation { properties: "y"; duration: 200; easing.type: Easing.OutCubic } }

            Repeater {
                model: emergentes

                Tarjeta {
                    id: emergente
                    required property var model
                    required property int index
                    notif: model.notif
                    emergente: true
                    width: pila.width
                    hace: "ahora"
                    onCerrar: { root.quitar(notif); emergentes.remove(index); }

                    // Entrada deslizándose desde la derecha
                    x: 0
                    opacity: 1
                    NumberAnimation on x { from: 60; to: 0; duration: 260; easing.type: Easing.OutCubic }
                    NumberAnimation on opacity { from: 0; to: 1; duration: 220 }

                    Timer {
                        interval: emergente.notif?.urgency === 2 ? 12000 : 6000
                        running: !emergente.containsHover
                        onTriggered: emergentes.remove(emergente.index)
                    }
                    property bool containsHover: false
                    HoverHandler { onHoveredChanged: emergente.containsHover = hovered }
                }
            }
        }
    }

    // ───────────── Panel (Super + X) ─────────────
    PanelWindow {
        id: panel
        visible: root.abierto || caja.opacity > 0
        anchors { top: true; bottom: true; left: true; right: true }
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "kora-centro"
        WlrLayershell.keyboardFocus: root.abierto ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

        // Clic afuera cierra
        MouseArea { anchors.fill: parent; onClicked: root.cerrar() }

        Rectangle {
            id: caja
            width: 430
            height: Math.min(columna.implicitHeight + 28, panel.height - 60)
            anchors { top: parent.top; right: parent.right; topMargin: 48; rightMargin: 10 }
            radius: 24
            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.rgba(0.11, 0.095, 0.075, 0.99) }
                GradientStop { position: 1.0; color: Qt.rgba(0.06, 0.05, 0.04, 0.99) }
            }
            border.width: 1
            border.color: Qt.rgba(0.9, 0.7, 0.31, 0.5)
            clip: true

            // Entrada: se desliza desde la derecha y aparece
            opacity: root.abierto ? 1 : 0
            transform: Translate { x: root.abierto ? 0 : 40; Behavior on x { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } } }
            Behavior on opacity { NumberAnimation { duration: 200 } }

            MouseArea { anchors.fill: parent }   // que los clics adentro no cierren
            focus: true
            Keys.onEscapePressed: root.cerrar()

            Flickable {
                anchors { fill: parent; margins: 14 }
                contentHeight: columna.implicitHeight
                boundsBehavior: Flickable.StopAtBounds
                clip: true

                ColumnLayout {
                    id: columna
                    width: parent.width
                    spacing: 12

                    // ── Encabezado: wallpaper + usuario ──
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 150
                        radius: 18
                        color: "#0d0c0a"
                        clip: true

                        Image {
                            id: banner
                            anchors.fill: parent
                            source: "file://" + estadoWallpaper.text().trim()
                            fillMode: Image.PreserveAspectCrop
                            sourceSize.width: 860
                            asynchronous: true
                            visible: false
                        }
                        MultiEffect {
                            anchors.fill: parent
                            source: banner
                            brightness: -0.1
                            maskEnabled: true
                            maskSource: mascara
                        }
                        Item {
                            id: mascara
                            anchors.fill: parent
                            layer.enabled: true
                            visible: false
                            Rectangle { anchors.fill: parent; radius: 18 }
                        }
                        Rectangle {
                            anchors.fill: parent
                            radius: 18
                            gradient: Gradient {
                                GradientStop { position: 0.35; color: "transparent" }
                                GradientStop { position: 1.0; color: Qt.rgba(0.06, 0.05, 0.04, 0.92) }
                            }
                        }

                        RowLayout {
                            anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: 12 }
                            spacing: 10

                            Rectangle {
                                Layout.preferredWidth: 44; Layout.preferredHeight: 44
                                radius: 22
                                color: root.oro
                                Text {
                                    anchors.centerIn: parent
                                    text: "V"
                                    color: root.fondo
                                    font { family: "Rubik"; pixelSize: 20; bold: true }
                                }
                            }
                            Column {
                                Layout.fillWidth: true
                                Text { text: "Victor"; color: "#f5ebd8"; font { family: "Rubik"; pixelSize: 16; bold: true } }
                                Text {
                                    text: "kora@Kora" + (root.encendido ? "  ·  encendido " + root.encendido : "")
                                    color: root.crema; opacity: 0.75
                                    font { family: "Rubik"; pixelSize: 11 }
                                }
                            }
                            Repeater {
                                model: [
                                    { ic: "󰸉", cmd: ["sh", "-c", "~/.config/hypr-kora/scripts/wallpaper.sh pick"] },
                                    { ic: "󰌾", cmd: ["hyprlock", "-c", Quickshell.env("HOME") + "/.config/hypr-kora/hyprlock.conf"] },
                                    { ic: "⏻", cmd: ["sh", "-c", "~/.config/hypr-kora/scripts/power-menu.sh"] }
                                ]
                                Rectangle {
                                    required property var modelData
                                    Layout.preferredWidth: 32; Layout.preferredHeight: 32
                                    radius: 16
                                    color: Qt.rgba(0.08, 0.07, 0.06, a.containsMouse ? 0.95 : 0.72)
                                    border.width: 1
                                    border.color: a.containsMouse ? "#e6b450" : Qt.rgba(1, 0.9, 0.7, 0.22)
                                    Text { anchors.centerIn: parent; text: modelData.ic; color: root.crema; font { family: root.iconos; pixelSize: 15 } }
                                    MouseArea {
                                        id: a; anchors.fill: parent; hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: { root.cerrar(); Quickshell.execDetached(modelData.cmd); }
                                    }
                                }
                            }
                        }
                    }

                    // ── Deslizadores ──
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        Deslizador {
                            Layout.fillWidth: true
                            icono: "󰃠"
                            value: root.brillo
                            onMover: v => root.ponerBrillo(v)
                        }
                        Deslizador {
                            Layout.fillWidth: true
                            icono: root.salida?.audio?.muted ? "󰝟" : "󰕾"
                            apagado: root.salida?.audio?.muted ?? false
                            value: root.salida?.audio?.volume ?? 0
                            onMover: v => { if (root.salida?.audio) root.salida.audio.volume = v; }
                        }
                        Deslizador {
                            Layout.fillWidth: true
                            icono: root.entrada?.audio?.muted ? "󰍭" : "󰍬"
                            apagado: root.entrada?.audio?.muted ?? false
                            value: root.entrada?.audio?.volume ?? 0
                            onMover: v => { if (root.entrada?.audio) root.entrada.audio.volume = v; }
                        }
                    }

                    // ── Interruptores ──
                    GridLayout {
                        Layout.fillWidth: true
                        columns: 4
                        columnSpacing: 8; rowSpacing: 8
                        Interruptor {
                            Layout.fillWidth: true
                            icono: Networking.wifiEnabled ? "󰖩" : "󰖪"
                            activo: Networking.wifiEnabled
                            abre: true
                            desplegado: root.menu === "wifi"
                            onClic: root.menu = root.menu === "wifi" ? "" : "wifi"
                        }
                        Interruptor {
                            Layout.fillWidth: true
                            readonly property var bt: Bluetooth.defaultAdapter
                            icono: bt?.enabled ? "󰂯" : "󰂲"
                            activo: bt?.enabled ?? false
                            abre: true
                            desplegado: root.menu === "bt"
                            onClic: root.menu = root.menu === "bt" ? "" : "bt"
                        }
                        Interruptor {
                            Layout.fillWidth: true
                            icono: root.salida?.audio?.muted ? "󰝟" : "󰕾"
                            activo: !(root.salida?.audio?.muted ?? true)
                            onClic: if (root.salida?.audio) root.salida.audio.muted = !root.salida.audio.muted
                        }
                        Interruptor {
                            Layout.fillWidth: true
                            icono: root.entrada?.audio?.muted ? "󰍭" : "󰍬"
                            activo: !(root.entrada?.audio?.muted ?? true)
                            onClic: if (root.entrada?.audio) root.entrada.audio.muted = !root.entrada.audio.muted
                        }
                        Interruptor {
                            Layout.fillWidth: true
                            icono: root.noMolestar ? "󰂛" : "󰂚"
                            activo: root.noMolestar
                            onClic: root.noMolestar = !root.noMolestar
                        }
                        Interruptor {
                            Layout.fillWidth: true
                            icono: "󰹑"
                            onClic: { root.cerrar(); Quickshell.execDetached(["sh", "-c", "sleep 0.4; ~/.config/hypr-kora/scripts/screenshot.sh"]); }
                        }
                        Interruptor {
                            Layout.fillWidth: true
                            icono: "󰅌"
                            onClic: { root.cerrar(); Quickshell.execDetached(["sh", "-c", "~/.config/hypr-kora/scripts/clipboard.sh"]); }
                        }
                        Interruptor {
                            Layout.fillWidth: true
                            icono: "󰒓"
                            onClic: { root.cerrar(); Quickshell.execDetached(["kitty", "-e", "nmtui"]); }
                        }
                    }

                    // ── Menús de WiFi / Bluetooth (se despliegan) ──
                    MenuWifi {
                        Layout.fillWidth: true
                        abierto: root.abierto && root.menu === "wifi"
                        visible: root.menu === "wifi"
                    }
                    MenuBluetooth {
                        Layout.fillWidth: true
                        abierto: root.abierto && root.menu === "bt"
                        visible: root.menu === "bt"
                    }

                    // ── Notificaciones ──
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: notifCol.implicitHeight + 20
                        radius: 18
                        color: Qt.rgba(1, 1, 1, 0.035)
                        border.width: 1
                        border.color: Qt.rgba(1, 0.9, 0.7, 0.08)

                        ColumnLayout {
                            id: notifCol
                            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 10 }
                            spacing: 8

                            Text {
                                visible: root.cuantas === 0
                                Layout.fillWidth: true
                                Layout.topMargin: 18; Layout.bottomMargin: 18
                                horizontalAlignment: Text.AlignHCenter
                                text: root.noMolestar ? "󰂛   No molestar activado" : "󰂚   Sin notificaciones"
                                color: root.tenue
                                font { family: "Rubik"; pixelSize: 13 }
                            }

                            Repeater {
                                model: root.lista
                                Tarjeta {
                                    required property var modelData
                                    Layout.fillWidth: true
                                    notif: modelData
                                    hace: root.hace(modelData)
                                    onCerrar: root.quitar(modelData)
                                }
                            }

                            // Pie: no molestar · contador · limpiar
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8
                                Interruptor {
                                    Layout.preferredWidth: 46; implicitHeight: 34
                                    icono: root.noMolestar ? "󰂛" : "󰂚"
                                    activo: root.noMolestar
                                    onClic: root.noMolestar = !root.noMolestar
                                }
                                Rectangle {
                                    Layout.fillWidth: true; Layout.preferredHeight: 34
                                    radius: 17
                                    gradient: Gradient {
                                        GradientStop { position: 0.0; color: Qt.rgba(1, 0.95, 0.85, 0.09) }
                                        GradientStop { position: 1.0; color: Qt.rgba(1, 0.95, 0.85, 0.03) }
                                    }
                                    border.width: 1
                                    border.color: root.cuantas > 0 ? Qt.rgba(0.9, 0.7, 0.31, 0.45) : Qt.rgba(1, 0.9, 0.7, 0.10)
                                    Text {
                                        anchors.centerIn: parent
                                        text: root.cuantas === 1 ? "1 notificación" : root.cuantas + " notificaciones"
                                        color: root.crema
                                        font { family: "Rubik"; pixelSize: 12 }
                                    }
                                }
                                Interruptor {
                                    Layout.preferredWidth: 46; implicitHeight: 34
                                    icono: "󰎟"
                                    onClic: root.limpiar()
                                }
                            }
                        }
                    }

                    // ── Monitor del sistema ──
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: monCol.implicitHeight + 24
                        radius: 18
                        color: Qt.rgba(1, 1, 1, 0.035)
                        border.width: 1
                        border.color: Qt.rgba(1, 0.9, 0.7, 0.08)

                        Column {
                            id: monCol
                            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 14 }
                            spacing: 12

                            Text { text: "Monitor del sistema"; color: root.tenue; font { family: "Rubik"; pixelSize: 12; weight: Font.Medium } }

                            Repeater {
                                model: [
                                    { ic: "󰻠", nombre: "CPU", v: root.cpu, txt: Math.round(root.cpu * 100) + "%" },
                                    { ic: "󰍛", nombre: "Memoria", v: root.ram, txt: Math.round(root.ram * 100) + "%" },
                                    { ic: "󰋊", nombre: "Disco", v: root.disco, txt: Math.round(root.disco * 100) + "%" },
                                    { ic: "󰔏", nombre: "Temperatura", v: Math.min(1, root.temp / 100), txt: Math.round(root.temp) + "°C" }
                                ]
                                Column {
                                    required property var modelData
                                    width: monCol.width
                                    spacing: 6
                                    Item {
                                        width: parent.width; height: 16
                                        Row {
                                            spacing: 10
                                            Text { text: modelData.ic; color: root.oro; font { family: root.iconos; pixelSize: 13 } }
                                            Text { text: modelData.nombre; color: root.crema; font { family: "Rubik"; pixelSize: 12 } }
                                        }
                                        Text {
                                            anchors.right: parent.right
                                            text: modelData.txt
                                            color: modelData.v > 0.85 ? "#e06c5a" : root.oro
                                            font { family: "Rubik"; pixelSize: 12; bold: true }
                                        }
                                    }
                                    Rectangle {
                                        width: parent.width; height: 7; radius: 4
                                        color: Qt.rgba(0, 0, 0, 0.3)
                                        border.width: 1; border.color: Qt.rgba(1, 0.9, 0.7, 0.08)
                                        Rectangle {
                                            width: parent.width * Math.max(0, Math.min(1, modelData.v)); height: parent.height; radius: 4
                                            gradient: Gradient {
                                                orientation: Gradient.Horizontal
                                                GradientStop { position: 0.0; color: modelData.v > 0.85 ? "#b84c3d" : "#c48a2c" }
                                                GradientStop { position: 1.0; color: modelData.v > 0.85 ? "#f08a78" : "#f3cc78" }
                                            }
                                            Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
