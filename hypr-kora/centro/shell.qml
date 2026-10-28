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

    // Sin el aviso "Config reloaded" (tema.py reescribe los colores y Quickshell recarga solo)
    Connections {
        target: Quickshell
        function onReloadCompleted() { Quickshell.inhibitReloadPopup(); }
        function onReloadFailed() { Quickshell.inhibitReloadPopup(); }
    }

    readonly property color oro: "#91bfa8"
    readonly property color crema: "#dde3dd"
    readonly property color tenue: "#7b827b"
    readonly property color fondo: "#111211"
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
    property real tocadoBrillo: 0       // cuándo se movió el deslizador (para no pelear con la lectura)
    Timer {
        // Seguir el brillo real (teclas Fn, hypridle…) mientras el panel está abierto
        interval: 1000; repeat: true
        running: root.abierto
        onTriggered: if (Date.now() - root.tocadoBrillo > 1500) leerBrillo.running = true
    }
    function ponerBrillo(v) {
        tocadoBrillo = Date.now();
        brillo = Math.max(0.02, v);
        Quickshell.execDetached(["brightnessctl", "-q", "set", Math.round(brillo * 100) + "%"]);
    }

    property string encendido: ""
    Process {
        id: leerSistema
        command: ["awk", "{s=int($1); h=int(s/3600); m=int(s%3600/60); print (h? h \" h \" : \"\") m \" min\"}", "/proc/uptime"]
        stdout: StdioCollector { onStreamFinished: root.encendido = text.trim() }
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
    property string menu: ""            // "wifi" | "bt" | "ajustes" | "" — menú desplegado en el panel

    IpcHandler {
        target: "centro"
        function toggle(): void { root.abierto ? root.cerrar() : root.abrir(); }
        function open(): void { root.abrir(); }
        function close(): void { root.cerrar(); }
        function clear(): void { root.limpiar(); }
        function dnd(): void { root.noMolestar = !root.noMolestar; }
        // scripts/tema.py la llama al terminar de escribir todos los archivos del tema
        function recargar(): void { Quickshell.reload(false); }
        function menu(m: string): void { root.abrir(); root.menu = m; }
    }

    // Nombre para mostrar (lo pide instalar.sh) y equipo; sin archivo, el usuario
    FileView { id: archivoNombre; blockLoading: true; path: Quickshell.env("HOME") + "/.local/state/hypr-kora/nombre" }
    FileView { id: archivoEquipo; blockLoading: true; path: "/etc/hostname" }
    readonly property string usuario: Quickshell.env("USER") ?? ""
    readonly property string nombre: archivoNombre.text().trim() || usuario
    readonly property string equipo: archivoEquipo.text().trim()

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
                GradientStop { position: 0.0; color: Qt.rgba(0.088, 0.097, 0.088, 0.99) }
                GradientStop { position: 1.0; color: Qt.rgba(0.048, 0.053, 0.048, 0.99) }
            }
            border.width: 1
            border.color: Qt.rgba(0.565, 0.745, 0.655, 0.5)
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
                        color: "#0b0c0b"
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
                                GradientStop { position: 1.0; color: Qt.rgba(0.048, 0.053, 0.048, 0.92) }
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
                                Text { text: root.nombre; color: "#e3eae3"; font { family: "Rubik"; pixelSize: 16; bold: true } }
                                Text {
                                    text: root.usuario + "@" + root.equipo + (root.encendido ? "  ·  encendido " + root.encendido : "")
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
                                    color: Qt.rgba(0.068, 0.073, 0.068, a.containsMouse ? 0.95 : 0.72)
                                    border.width: 1
                                    border.color: a.containsMouse ? "#91bfa8" : Qt.rgba(0.865, 0.935, 0.9, 0.22)
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
                            abre: true
                            desplegado: root.menu === "ajustes"
                            onClic: root.menu = root.menu === "ajustes" ? "" : "ajustes"
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
                    MenuAjustes {
                        Layout.fillWidth: true
                        abierto: root.abierto && root.menu === "ajustes"
                        visible: root.menu === "ajustes"
                        onAbrio: root.cerrar()
                    }

                    // ── Notificaciones ──
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: notifCol.implicitHeight + 20
                        radius: 18
                        color: Qt.rgba(1, 1, 1, 0.035)
                        border.width: 1
                        border.color: Qt.rgba(0.865, 0.935, 0.9, 0.08)

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
                                        GradientStop { position: 0.0; color: Qt.rgba(0.906, 0.944, 0.906, 0.09) }
                                        GradientStop { position: 1.0; color: Qt.rgba(0.906, 0.944, 0.906, 0.03) }
                                    }
                                    border.width: 1
                                    border.color: root.cuantas > 0 ? Qt.rgba(0.565, 0.745, 0.655, 0.45) : Qt.rgba(0.865, 0.935, 0.9, 0.10)
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
                }
            }
        }
    }

    // ───────────── Batería y modo de energía (clic en la batería de Waybar) ─────────────
    Energia {}
}
