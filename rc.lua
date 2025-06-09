-- SomeWM Configuration
-- Using the new 3-layer architecture: base/core/ui

local somewm = require("somewm")

-- Initialize SomeWM with configuration
somewm.init({
  stack_insert_mode = "bottom",
  smart_behaviors = true
})

-- Configuration
local config = {
  terminal = "wezterm",
  modkey = "logo",
  shift = "Shift"
}

-- Application launcher
somewm.key({
  modifiers = { config.modkey },
  key = "p",
  description = "launch bemenu",
  group = "applications",
  on_press = function()
    somewm.spawn("bemenu-run")
  end,
})

-- Terminal
somewm.key({
  modifiers = { config.modkey },
  key = "Return",
  description = "launch wezterm",
  group = "applications",
  on_press = function()
    somewm.spawn(config.terminal)
  end,
})

-- Media keys
somewm.key({
  modifiers = {},
  key = "XF86AudioRaiseVolume",
  description = "raise volume",
  group = "media",
  on_press = function()
    somewm.spawn("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+")
  end,
})

somewm.key({
  modifiers = {},
  key = "XF86AudioLowerVolume",
  description = "lower volume",
  group = "media",
  on_press = function()
    somewm.spawn("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-")
  end,
})

somewm.key({
  modifiers = {},
  key = "XF86AudioMute",
  description = "toggle mute",
  group = "media",
  on_press = function()
    somewm.spawn("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle")
  end,
})

-- Screenshot
somewm.key({
  modifiers = { config.modkey, config.shift },
  key = "P",
  description = "screenshot to clipboard",
  group = "applications",
  on_press = function()
    somewm.spawn('grim -g "$(slurp)" - | wl-copy')
  end,
})

-- Power management
somewm.key({
  modifiers = { config.modkey, config.shift },
  key = "S",
  description = "suspend system",
  group = "power",
  on_press = function()
    somewm.spawn("systemctl suspend")
  end,
})

somewm.key({
  modifiers = { config.modkey, config.shift },
  key = "H",
  description = "hibernate system",
  group = "power",
  on_press = function()
    somewm.spawn("systemctl hibernate")
  end,
})

somewm.key({
  modifiers = { config.modkey, config.shift },
  key = "R",
  description = "reboot system",
  group = "power",
  on_press = function()
    somewm.spawn("systemctl reboot")
  end,
})

somewm.key({
  modifiers = { config.modkey, config.shift },
  key = "Q",
  description = "quit SomeWM",
  group = "power",
  on_press = function()
    somewm.quit()
  end,
})

-- Widget testing
somewm.key({
  modifiers = { config.modkey },
  key = "w",
  description = "show a test widget",
  group = "widgets",
  on_press = function()
    somewm.base.logger.info("'w' key pressed, creating notification widget")
    local ok, err = pcall(function()
      somewm.notify("Hello from SomeWM!", 5)
    end)
    if not ok then
      somewm.base.logger.error("Failed to create widget: " .. tostring(err))
    else
      somewm.base.logger.info("Widget creation successful")
    end
  end,
})

somewm.key({
  modifiers = { config.modkey },
  key = "g",
  description = "test lgi widget drawing",
  group = "widgets",
  on_press = function()
    somewm.base.logger.info("'g' key pressed, running direct LGI test")
    local ok, err = pcall(function()
      somewm.ui.widgets.test_notification("Direct LGI Test", 5)
    end)
    if not ok then
      somewm.base.logger.error("Failed to run LGI test: " .. tostring(err))
    else
      somewm.base.logger.info("LGI test completed successfully")
    end
  end,
})

somewm.key({
  modifiers = { config.modkey },
  key = "n",
  description = "test notification system",
  group = "widgets",
  on_press = function()
    somewm.base.logger.info("'n' key pressed, testing notification system")
    
    -- Use the wayland surface directly
    local wayland_surface = require("wayland_surface")
    wayland_surface.create_widget_surface(300, 100, 50, 50, "Test Notification via system")
  end,
})

somewm.key({
  modifiers = { config.modkey },
  key = "d",
  description = "test menu-based notification",
  group = "widgets",
  on_press = function()
    somewm.base.logger.info("'d' key pressed, testing menu-based notification")
    
    local wayland_surface = require("wayland_surface")
    wayland_surface.display_message("Test menu-based notification")
  end,
})

-- Client API testing
somewm.key({
  modifiers = { config.modkey },
  key = "c",
  description = "test client API",
  group = "clients",
  on_press = function()
    somewm.base.logger.info("'c' key pressed, testing client API")
    dofile("test_client_api.lua")
  end,
})

somewm.key({
  modifiers = { config.modkey, config.shift },
  key = "c",
  description = "test client manipulation",
  group = "clients",
  on_press = function()
    somewm.base.logger.info("'Shift+c' key pressed, testing client manipulation")
    dofile("test_client_manipulation.lua")
  end,
})

-- Event system testing
somewm.key({
  modifiers = { config.modkey },
  key = "e",
  description = "setup event system tests",
  group = "clients",
  on_press = function()
    somewm.base.logger.info("'e' key pressed, setting up event system tests")
    dofile("test_events.lua")
  end,
})

somewm.key({
  modifiers = { config.modkey, config.shift },
  key = "e",
  description = "enable practical event-based window management",
  group = "clients",
  on_press = function()
    somewm.base.logger.info("'Shift+e' key pressed, enabling practical event-based window management")
    dofile("practical_event_example.lua")
  end,
})

-- Monitor and Tag testing
somewm.key({
  modifiers = { config.modkey },
  key = "m",
  description = "test monitor API",
  group = "clients",
  on_press = function()
    somewm.base.logger.info("'m' key pressed, testing monitor API")
    dofile("test_monitor_api.lua")
  end,
})

somewm.key({
  modifiers = { config.modkey, config.shift },
  key = "m",
  description = "test monitor management",
  group = "clients",
  on_press = function()
    somewm.base.logger.info("'Shift+m' key pressed, testing monitor management")
    dofile("test_monitor_manipulation.lua")
  end,
})

somewm.key({
  modifiers = { config.modkey },
  key = "t",
  description = "test tag API",
  group = "clients",
  on_press = function()
    somewm.base.logger.info("'t' key pressed, testing tag API")
    dofile("test_tag_api.lua")
  end,
})

somewm.key({
  modifiers = { config.modkey, config.shift },
  key = "t",
  description = "test tag management",
  group = "clients",
  on_press = function()
    somewm.base.logger.info("'Shift+t' key pressed, testing tag management")
    dofile("test_tag_manipulation.lua")
  end,
})

-- Practical client manipulation
somewm.key({
  modifiers = { config.modkey },
  key = "f",
  description = "toggle focused client fullscreen",
  group = "clients",
  on_press = function()
    local focused = somewm.get_focused_client()
    if focused then
      focused.fullscreen = not focused.fullscreen
      somewm.base.logger.info("Toggled fullscreen for: " .. (focused.title or "Untitled"))
    end
  end,
})

somewm.key({
  modifiers = { config.modkey, config.shift },
  key = "space",
  description = "toggle focused client floating",
  group = "clients",
  on_press = function()
    local focused = somewm.get_focused_client()
    if focused then
      focused.floating = not focused.floating
      somewm.base.logger.info("Toggled floating for: " .. (focused.title or "Untitled"))
    end
  end,
})

somewm.key({
  modifiers = { config.modkey },
  key = "q",
  description = "close focused client",
  group = "clients",
  on_press = function()
    local focused = somewm.get_focused_client()
    if focused then
      local title = focused.title or "Untitled"
      focused:close()
      somewm.base.logger.info("Closed client: " .. title)
    end
  end,
})

-- Window automation rules
somewm.add_window_rule(
  { class = "firefox" },
  { set_tag = "web", set_floating = false },
  "Firefox to web tag"
)

somewm.add_window_rule(
  { class = "mpv" },
  { set_floating = true, focus = true },
  "MPV floating and focused"
)

somewm.add_window_rule(
  { title = ".*[Tt]erminal.*" },
  { set_tag = "term" },
  "Terminals to term tag"
)

-- Help system
somewm.key({
  modifiers = { config.modkey },
  key = "h",
  description = "show keybinding help",
  group = "help",
  on_press = function()
    somewm.debug.show_help()
  end,
})

-- Debug utilities
somewm.key({
  modifiers = { config.modkey, config.shift },
  key = "F1",
  description = "show SomeWM statistics",
  group = "debug",
  on_press = function()
    somewm.debug.show_stats()
  end,
})

-- Initialize compositor hello world (maintaining compatibility)
Some.hello_world()

somewm.base.logger.info("SomeWM configuration loaded using 3-layer architecture")