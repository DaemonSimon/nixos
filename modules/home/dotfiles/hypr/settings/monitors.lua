-- Assign workspaces to specific monitors (declarative)
hl.workspace_rule({ workspace = "1", monitor = "DP-2", persistent = true })
hl.workspace_rule({ workspace = "2", monitor = "DP-2", persistent = true })
hl.workspace_rule({ workspace = "3", monitor = "DP-2", persistent = true })
hl.workspace_rule({ workspace = "4", monitor = "DP-2", persistent = true })
hl.workspace_rule({ workspace = "5", monitor = "DP-1", persistent = true })
hl.workspace_rule({ workspace = "6", monitor = "HDMI-A-1", persistent = true })

hl.monitor({
    output = "DP-1",
    mode = "1920x1200@59.95",
    position = "0x0",
    scale = 1,
    bitdepth = 8,
    cm = "srgb",
    sdrbrightness = 1.0,
    sdrsaturation = 1.0
})

hl.monitor({
    output = "DP-2",
    mode = "2560x1440@180",
    position = "1920x0",
    scale = 1,
    bitdepth = 10,
    cm = "srgb",
    sdrbrightness = 1.0,
    sdrsaturation = 1.0
})

hl.monitor({
    output = "HDMI-A-1",
    mode = "1920x1200@59.95",
    position = "4480x0",
    scale = 1,
    bitdepth = 8,
    cm = "srgb",
    sdrbrightness = 1.0,
    sdrsaturation = 1.0
})
