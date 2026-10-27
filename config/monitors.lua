-- Monitor wiki https://wiki.hypr.land/Configuring/Basics/Monitors/
-- Example: output can be found with hyprctl monitors. Edit variables.lua for the monitor outputs instead of here directly
-- hl.monitor({
--     output    = MONITOR1,
--     mode      = "1920x1080@60",
--     position  = "0x0",
--     scale     = "1",
-- })

-- 240 Hz con cargador, 60 Hz con batería (scripts/ahorro.sh lo cambia al conectar/desconectar)
local ac = io.open("/sys/class/power_supply/AC/online")
local enCorriente = not ac or ac:read("*l") == "1"
if ac then ac:close() end

hl.monitor({
    output    = MONITOR1,
    mode      = enCorriente and "2560x1600@240" or "2560x1600@60",
    position  = "0x0",
    scale     = "1.25",
})

-- Cualquier otro monitor (HDMI, proyectores...): resolución preferida, a la derecha de la laptop
hl.monitor({
    output    = "",
    mode      = "preferred",
    position  = "auto",
    scale     = "1",
})
