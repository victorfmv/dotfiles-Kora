-- Workspace rules wiki https://wiki.hypr.land/Configuring/Basics/Workspace-Rules/
-- Add your workspace rules here. Increment the workspace number as you go. Do not have duplicate workspaces.
hl.workspace_rule({ workspace = "special:gaming", monitor = PRIMARY_MONITOR })
hl.workspace_rule({ workspace = "1", monitor = MONITOR1, default = true, persistent = true })
hl.workspace_rule({ workspace = "2", monitor = MONITOR1, default = true, persistent = true })
hl.workspace_rule({ workspace = "3", monitor = MONITOR1, default = true, persistent = true })
-- hl.workspace_rule({ workspace = "4", monitor = MONITOR2, default = true, persistent = true })
-- hl.workspace_rule({ workspace = "5", monitor = MONITOR2, default = true, persistent = true })
-- hl.workspace_rule({ workspace = "6", monitor = MONITOR2, default = true, persistent = true })

-- For other layouts such as scrolling, see example below
-- hl.workspace_rule({ workspace = "1", monitor = MONITOR1, default = true, persistent = true, layout = "scrolling" })

-- Workspaces especiales que abren su app la primera vez que se muestran vacíos
-- (Super + M = Spotify, Super + O = OBS, Super + S = Steam).
-- Antes era on_created_empty en workspace_rule; Hyprland 0.57 lo marcó obsoleto.
local apps_al_crear = {
    ["special:music"] = "uwsm app -- spotify-launcher",
    ["special:obs"]   = "uwsm app -- obs",
    ["special:steam"] = "uwsm app -- steam",
}

hl.on("workspace.created", function(ws)
    local cmd = ws and apps_al_crear[ws.name]
    if cmd and ws.is_empty then
        hl.exec_cmd(cmd, { workspace = ws.name })
    end
end)
