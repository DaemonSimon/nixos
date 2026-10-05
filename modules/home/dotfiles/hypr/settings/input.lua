-- Keyboard, mouse, touchpad, gestures
hl.config({
    input = {
        kb_layout  = "de",
        kb_variant = "nodeadkeys",
        kb_model   = "",
        kb_options = "",
        kb_rules   = "",

        resolve_binds_by_sym = true,

        follow_mouse = 1,

        sensitivity = 0,

        touchpad = {
            natural_scroll = false,
        },
    },
})

hl.gesture({
    fingers = 3,
    direction = "horizontal",
    action = "workspace"
})

hl.device({
    name        = "epic-mouse-v1",
    sensitivity = -0.5,
})
