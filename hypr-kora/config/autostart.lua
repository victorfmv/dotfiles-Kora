-- Programas al iniciar Hyprland Kora (nada de Caelestia aquí)
local K = os.getenv("HOME") .. "/.config/hypr-kora"

hl.on("hyprland.start", function ()
    hl.exec_cmd("dbus-update-activation-environment --systemd --all")
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")
    hl.exec_cmd("systemctl --user start hyprpolkitagent")
    hl.exec_cmd("nm-applet --indicator")
    hl.exec_cmd(K .. "/scripts/barra.sh") -- Waybar normal o la del modo Familiar
    hl.exec_cmd(K .. "/scripts/video-solido.sh") -- navegador sólido mientras suena un video
    hl.exec_cmd("qs -p " .. K .. "/overview") -- vista de workspaces (Super+Shift+Tab / pellizco)
    hl.exec_cmd("qs -p " .. K .. "/centro") -- notificaciones + centro de control (reemplaza a mako)
    hl.exec_cmd("qs -p " .. K .. "/fondos") -- selector de wallpapers (Super+Shift+W)
    hl.exec_cmd("qs -p " .. K .. "/osd") -- indicador de volumen y brillo (orilla derecha)
    hl.exec_cmd("qs -p " .. K .. "/lanzador") -- lanzador de apps del modo Familiar (sale de abajo)
    hl.exec_cmd("hypridle -c " .. K .. "/hypridle.conf")
    hl.exec_cmd(K .. "/scripts/wallpaper.sh")
    hl.exec_cmd(K .. "/scripts/ahorro.sh") -- 60 Hz + fondo fijo + power-saver con batería
    hl.exec_cmd("xhost +SI:localuser:root")
end)
