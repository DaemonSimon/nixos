-- Environment variables
-- XCURSOR_THEME / XCURSOR_SIZE are set by home-manager (modules/home/cursor.nix)
-- via home.pointerCursor. Do not set them here: hl.env re-exports into hyprland's
-- own environment, which would override home-manager's mkDefault values.
hl.env("ENABLE_HDR_WSI", "1")
hl.env("DXVK_HDR", "1")

-- Render / color management
hl.config({
    render = {
        direct_scanout = false,
        cm_auto_hdr = 0,
    },
})
