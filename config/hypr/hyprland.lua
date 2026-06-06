-- configuration references:
--   https://github.com/hyprwm/Hyprland/blob/main/example/hyprland.lua
--   https://github.com/hyprwm/hyprland-wiki
--
-- Hyprland configuration in Lua
-- This file is sourced by Hyprland directly

------------------
---- MONITORS ----
------------------

hl.monitor({
    output   = "eDP-1",
    mode     = "2880x1920@120",
    position = "0x0",
    scale    = 2,
})

---------------------
---- MY PROGRAMS ----
---------------------

local terminal = "uwsm app -- ghostty"
local focus_or_start = "$HOME/.config/hypr/scripts/focus-or-start.sh"
local electron_flags = "--enable-features=UseOzonePlatform --ozone-platform=wayland"

-------------------
---- AUTOSTART ----
-------------------

hl.on("hyprland.start", function()
    -- Enable easyeffects at startup
    hl.exec_cmd("uwsm app -- easyeffects --gapplication-service")

    -- Enable polkit agent for interactive auth
    hl.exec_cmd("uwsm app -- /usr/lib/polkit-kde-authentication-agent-1")

    -- Start clipboard history process
    hl.exec_cmd("uwsm app -- wl-paste --type text --watch cliphist store")
    hl.exec_cmd("uwsm app -- wl-paste --type image --watch cliphist store")

    -- Start 1password and ghostty automatically
    hl.exec_cmd("[workspace special:1password silent] uwsm app -- 1password " .. electron_flags)
    hl.exec_cmd(terminal)

    -- Start Dank Material Shell
    hl.exec_cmd("uwsm app -- dms run")
end)

------------------
---- SETTINGS ----
------------------

-- General configuration
hl.config({
    input = {
        repeat_rate = 45,
        repeat_delay = 400,
        kb_options = "caps:escape",
    },
    xwayland = {
        force_zero_scaling = true,
    },
    misc = {
        focus_on_activate = false,
    },
    general = {
        border_size = 1,
        gaps_in = 2,
        gaps_out = 3,
    }
})

-------------------
---- VARIABLES ----
-------------------

-- Define variables for use in keybindings
-- Note: These are Lua variables that get expanded when used
local mod = "SUPER"

--------------------
---- WINDOW RULES ----
--------------------

-- Window rules with workspace assignment
-- Using the "workspace" property directly in the rule (not in match)
hl.window_rule({
    name = "firefox-workspace",
    match = { class = "firefox" },
    ["workspace"] = "1",
})

hl.window_rule({
    name = "zed-workspace",
    match = { class = "dev.zed.Zed" },
    ["workspace"] = "2",
})

hl.window_rule({
    name = "ghostty-workspace",
    match = { class = "com.mitchellh.ghostty" },
    ["workspace"] = "3",
})

-------------------
---- KEYBINDINGS ----
-------------------

-- System controls
hl.bind(mod .. " + Q", hl.dsp.exec_cmd("systemctl suspend"))
hl.bind(mod .. " + W", hl.dsp.window.close())
hl.bind(mod .. " + SHIFT + F", hl.dsp.window.fullscreen())
hl.bind(mod .. " + Return", hl.dsp.exec_cmd(focus_or_start .. " ghostty com.mitchellh.ghostty"))

-- Ghostty quick terminal binding
-- Pass ALT+SPACE to Ghostty windows to toggle the quick terminal from any workspace
hl.bind("ALT + SPACE", hl.dsp.pass({ window = "class:^(com.mitchellh.ghostty)$" }))

-- Dank Material Shell integrations
hl.bind(mod .. " + SPACE", hl.dsp.exec_cmd("dms ipc call spotlight toggle"))
hl.bind(mod .. " + V", hl.dsp.exec_cmd("dms ipc call clipboard toggle"))
hl.bind(mod .. " + T", hl.dsp.exec_cmd("dms ipc call processlist toggle"))

-- TUI apps
hl.bind(mod .. " + F", hl.dsp.exec_cmd(terminal .. " -e yazi"))

-- Applications
hl.bind(mod .. " + B", hl.dsp.exec_cmd(focus_or_start .. " firefox firefox"))
hl.bind(mod .. " + P", hl.dsp.exec_cmd(focus_or_start .. " '1password " .. electron_flags .. "' 1Password"))
hl.bind(mod .. " + Z", hl.dsp.exec_cmd(focus_or_start .. " zed dev.zed.Zed"))

-- Workspace navigation
hl.bind(mod .. " + H", hl.dsp.focus({ workspace = "r-1" }))
hl.bind(mod .. " + L", hl.dsp.focus({ workspace = "r+1" }))

-- Window navigation (cycle through windows)
hl.bind(mod .. " + J", hl.dsp.focus({ direction = "right" }))
hl.bind(mod .. " + K", hl.dsp.focus({ direction = "left" }))

-- Move window to workspace
hl.bind(mod .. " + SHIFT + H", hl.dsp.window.move({ workspace = "r-1" }))
hl.bind(mod .. " + SHIFT + L", hl.dsp.window.move({ workspace = "r+1" }))

-- Screenshots
hl.bind(mod .. " + PRINT", hl.dsp.exec_cmd("uwsm app -- hyprshot -m window"))
hl.bind(mod .. " + SHIFT + PRINT", hl.dsp.exec_cmd("uwsm app -- hyprshot -m output"))
hl.bind(mod .. " + SHIFT + 4", hl.dsp.exec_cmd("uwsm app -- hyprshot -m region"))

-- Media controls
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("dms ipc call audio micmute"))
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("dms ipc call audio mute"))
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("dms ipc call audio increment 10"))
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("dms ipc call audio decrement 10"))
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"))
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"))
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"))
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"))

-- Screen brightness
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("dms ipc call brightness increment 5 ''"))
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("dms ipc call brightness decrement 5 ''"))
