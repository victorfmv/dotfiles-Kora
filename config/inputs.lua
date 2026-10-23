-- Input configuration

hl.config({
    input = {
        -- sensitivity = -0.25,
        accel_profile = "flat",
        kb_layout = "latam",
    },
    -- Uncomment the section below to enable software cursors; this can help with cursor display or behavior issues
    -- cursor = {
    --     no_hardware_cursors = 1,
    -- },
})

-- 3 dedos tipo niri: a los lados recorre las ventanas, arriba/abajo cambia de workspace
hl.gesture({ fingers = 3, direction = "horizontal", action = "scroll_move" })
hl.gesture({ fingers = 3, direction = "vertical",   action = "workspace" })
-- Pellizco con 3 dedos: alejamiento con todos los workspaces y sus ventanas (y regresar)
local OVERVIEW = os.getenv("HOME") .. "/.config/hypr-kora/scripts/overview.sh"
hl.gesture({ fingers = 3, direction = "pinchin",  action = function() hl.exec_cmd(OVERVIEW .. " open") end })
hl.gesture({ fingers = 3, direction = "pinchout", action = function() hl.exec_cmd(OVERVIEW .. " close") end })
-- 4 dedos: lo que antes estaba en 3
hl.gesture({ fingers = 4, direction = "down",       action = "close" })
hl.gesture({ fingers = 4, direction = "up",         action = "fullscreen" })
hl.gesture({ fingers = 4, direction = "left",       action = "float" })
