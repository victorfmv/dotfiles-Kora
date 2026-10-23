-- Look and feel configuration

local ACCENT1  = KORA.accent
local ACCENT2  = KORA.accent2
local INACTIVE = KORA.inactive
local LOCKED   = KORA.locked

hl.config({
    general = {
        layout = "scrolling", -- ventanas en fila horizontal, tipo niri
        gaps_in = 3,
        gaps_out = { top = 0, right = 8, bottom = 8, left = 8 }, -- arriba 0: el degradado de Waybar ya cubre ese hueco
        border_size = 2,
        extend_border_grab_area = 10,
        resize_on_border = true,
        col = {
            active_border = {
                colors = { ACCENT1, ACCENT2 },
                angle = 45,
            },
            inactive_border = INACTIVE,
        },
    },
    group = {
        col = {
            border_active = ACCENT1,
            border_inactive = INACTIVE,
            border_locked_active = LOCKED,
            border_locked_inactive = INACTIVE,
        },
        groupbar = {
            col = {
                active = ACCENT1,
                inactive = INACTIVE,
                locked_active = LOCKED,
                locked_inactive = INACTIVE,
            },
        },
    },
    decoration = {
        dim_special = 0.3,
        rounding = 10,
        active_opacity = 0.95,
        inactive_opacity = 0.85,
        fullscreen_opacity = 1,
        blur = {
            size = 5,
            passes = 4,
            special = true,
        },
    },
})
