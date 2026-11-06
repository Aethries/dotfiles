-- =============================================================================
-- Personal General Settings
-- =============================================================================

-- Monitor: force the native 1080p @ 120 Hz mode (EDID-preferred mode is 60 Hz)
hl.monitor({
    output = "HDMI-A-1",
    mode = "1920x1080@120",
    position = "0x0",
    scale = 1
})

-- Keyboard & caret ergonomics (180 ms delay / 50 Hz repeat)
hl.config({
    input = {
        repeat_rate = 50,
        repeat_delay = 180,
        kb_layout = "us"
    }
})
