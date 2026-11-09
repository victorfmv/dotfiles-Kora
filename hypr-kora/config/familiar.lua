-- Modo Familiar (estética tipo macOS). Se prende/apaga con scripts/familiar.sh, que crea o
-- borra ~/.local/state/hypr-kora/familiar y hace hyprctl reload. Va al final: pisa decorations.lua.
local f = io.open(os.getenv("HOME") .. "/.local/state/hypr-kora/familiar", "r")
FAMILIAR = f ~= nil
if f then f:close() end

if FAMILIAR then
    -- Borde casi invisible: el acento del tema con poca opacidad
    local suave = KORA.accent:gsub("%x%x%)$", "55)")
    hl.config({
        general = {
            border_size = 1,
            gaps_in = 5,
            gaps_out = { top = 6, right = 12, bottom = 12, left = 12 },
            col = {
                active_border = { colors = { suave } },
                inactive_border = "rgba(ffffff12)",
            },
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
