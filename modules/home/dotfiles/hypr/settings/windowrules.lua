-- Window and workspace rules
local suppressMaximizeRule = hl.window_rule({
    name  = "suppress-maximize-events",
    match = { class = ".*" },
    suppress_event = "maximize",
})

-- Block fullscreen requests only when the toggle state file exists.
-- Toggle with ~/.config/hypr/scripts/toggle-fullscreen.sh (or the keybind).
local suppressFullscreenFile = io.open((os.getenv("HOME") or "") .. "/.cache/hypr/fullscreen-suppress", "r")
if suppressFullscreenFile then
    suppressFullscreenFile:close()
    hl.window_rule({
        name  = "suppress-fullscreen-events",
        match = { class = ".*" },
        suppress_event = "fullscreen",
    })
end

hl.window_rule({
    name  = "fix-xwayland-drags",
    match = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },
    no_focus = true,
})

hl.window_rule({
    name  = "move-hyprland-run",
    match = { class = "hyprland-run" },
    move  = "20 monitor_h-120",
    float = true,
})
