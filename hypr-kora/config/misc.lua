hl.config({
    dwindle = {
        preserve_split = true,
    },
    -- Layout scrolling (tipo niri): cada ventana nueva ocupa toda la pantalla
    -- y se acomoda a la derecha; Super+J alterna entre media y completa.
    scrolling = {
        column_width = 1.0,
        explicit_column_widths = "0.5, 1.0",
        fullscreen_on_one_column = true,
        follow_focus = true,
        focus_fit_method = 1,
    },
    ecosystem = {
        no_update_news = true,
        no_donation_nag = true,
    },
    misc = {
        col = {
            splash = KORA.accent,
        },
        middle_click_paste = false,
        enable_swallow = true,
        swallow_regex = "(kitty|ghostty|[Kk]onsole|Alacritty|gnome-terminal|xfce[0-9]?-terminal)",
        vrr = 3,
    },
    render = {
        direct_scanout = 2,
        -- Use the option below if you find games constantly black screening for a couple seconds whenever direct scanout enables/disables
        -- non_shader_cm = 0,
    },
    xwayland = {
        force_zero_scaling = true
    },
})
