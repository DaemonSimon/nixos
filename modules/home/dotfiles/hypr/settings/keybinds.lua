-- Programs
local terminal    = "kitty"
local fileManager = "thunar"

-- Modifier
local mainMod = "SUPER"

-- Quickshell
hl.bind(mainMod .. " + SPACE",   hl.dsp.exec_cmd("qs ipc call launcher toggle"))
hl.bind(mainMod .. " + SHIFT + T", hl.dsp.exec_cmd("qs ipc call theme toggle"))
hl.bind(mainMod .. " + W",         hl.dsp.exec_cmd("qs ipc call wallpaper toggle"))
hl.bind(mainMod .. " + O",         hl.dsp.exec_cmd("qs ipc call monitors toggle"))
hl.bind(mainMod .. " + SHIFT + O", hl.dsp.exec_cmd("qs ipc call monitors refresh"))
hl.bind(mainMod .. " + C",         hl.dsp.exec_cmd("qs ipc call idle toggle"))
hl.bind(mainMod .. " + SHIFT + B", hl.dsp.exec_cmd("qs ipc call bluetooth toggle"))

-- Launch apps
hl.bind(mainMod .. " + V", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + T", hl.dsp.exec_cmd("firefox"))
hl.bind(mainMod .. " + H", hl.dsp.exec_cmd("code"))
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + M", hl.dsp.exec_cmd("command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'"))
hl.bind("CTRL + SHIFT + S", hl.dsp.exec_cmd("hyprshot -m region --clipboard-only --freeze"))
-- Screenshot button (PrintScreen) - physical screenshot key (freeze keeps hover tooltips visible)
hl.bind("Print",               hl.dsp.exec_cmd("hyprshot -m region --clipboard-only --freeze"))
hl.bind("SHIFT + Print",       hl.dsp.exec_cmd("hyprshot -m window --clipboard-only --freeze"))
hl.bind("ALT + Print",         hl.dsp.exec_cmd("hyprshot -m output --clipboard-only --freeze"))
-- save to file as well (without --clipboard-only, saves to ~/Pictures/Screenshots)
hl.bind("CTRL + Print",        hl.dsp.exec_cmd("hyprshot -m region --freeze"))
hl.bind(mainMod .. " + U", hl.dsp.exec_cmd("discord"))
hl.bind(mainMod .. " + Z", hl.dsp.exec_cmd("spotify-launcher"))
hl.bind(mainMod .. " + K", hl.dsp.exec_cmd("hyprctl activewindow -j | jq '.pid' | xargs kill -9"))
-- Window management
local closeWindowBind = hl.bind(mainMod .. " + R", hl.dsp.window.close())
hl.bind(mainMod .. " + F", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())
hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit"))
hl.bind(mainMod .. " + F11", hl.dsp.window.fullscreen({ action = "toggle" }))

-- Focus movement
hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }))

-- Workspace switching (1-4: CTRL)
for i = 1, 4 do
    hl.bind("CTRL + " .. i,                  hl.dsp.focus({ workspace = i }))
    hl.bind("CTRL + SHIFT + " .. i,          hl.dsp.window.move({ workspace = i }))
end
-- Workspace switching (5-10: SUPER for other monitors)
for i = 5, 10 do
    local key = i % 10
    hl.bind(mainMod .. " + " .. key,         hl.dsp.focus({ workspace = i}))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- Scratchpad
hl.bind(mainMod .. " + S",         hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

-- Scroll workspaces
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

-- Mouse drag/resize
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Multimedia keys
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      { locked = true, repeating = true })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     { locked = true, repeating = true })
hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp",  hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"),                  { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown",hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"),                  { locked = true, repeating = true })
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })


