-- Modo Familiar (estética tipo macOS). Se prende/apaga con scripts/familiar.sh, que crea o
-- borra ~/.local/state/hypr-kora/familiar y hace hyprctl reload. Va al final: pisa decorations.lua.
local f = io.open(os.getenv("HOME") .. "/.local/state/hypr-kora/familiar", "r")
FAMILIAR = f ~= nil
if f then f:close() end

if FAMILIAR then
    hl.config({
        general = {
            border_size = 0,         -- sin bordes
            gaps_in = 5,
            gaps_out = { top = 6, right = 12, bottom = 12, left = 12 },
        },
        decoration = {
            rounding = 16,
            rounding_power = 3,      -- esquinas tipo "squircle" de Mac
            shadow = {
                enabled = true,
                range = 26,
                render_power = 3,
                color = "rgba(00000066)",
                color_inactive = "rgba(00000033)",
            },
        },
    })
end

-- Ventanas transparentes de verdad (se ve el fondo nítido, sin difuminar).
-- La barra y los paneles conservan su desenfoque (eso va por layer_rule, no por ventana).
if FAMILIAR then
    hl.window_rule({ match = { class = ".*" }, no_blur = true })
end

-- El indicador de volumen/brillo también transparente sin difuminar (el centro y las
-- notificaciones ya no llevan desenfoque; su transparencia la pone centro/Modo.qml)
if FAMILIAR then
    hl.layer_rule({ name = "kora-osd-nitido", match = { namespace = "^(kora-osd)$" }, blur = false })
end
