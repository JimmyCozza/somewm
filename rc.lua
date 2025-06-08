local awful = require("awful")
local widgets = require("widgets")
local logger = require("logger")
local drawable = require("basic_drawable")

-- Initialize logger
logger.init()
logger.info("SomeWM starting up")

local modkey = "logo"
local shift = "Shift"

general_options = {
  -- Controls where new windows are inserted in the stack
  -- Valid values: "top" or "bottom"
  -- "top": New windows appear at the top/left of the stack
  -- "bottom": New windows appear at the bottom/right of the stack
  stack_insert_mode = "bottom",
}

awful.key({
  modifiers = { modkey },
  key = "p",
  description = "launch bemenu",
  group = "applications",
  on_press = function()
    Some.spawn("bemenu-run")
  end,
})

awful.key({
  modifiers = { modkey },
  key = "Return",
  description = "launch wezterm",
  group = "applications",
  on_press = function()
    Some.spawn("wezterm")
  end,
})

awful.key({
  modifiers = {},
  key = "XF86AudioRaiseVolume",
  description = "raise volume",
  group = "media",
  on_press = function()
    Some.spawn("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+")
  end,
})

awful.key({
  modifiers = {},
  key = "XF86AudioLowerVolume",
  description = "lower volume",
  group = "media",
  on_press = function()
    Some.spawn("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-")
  end,
})

awful.key({
  modifiers = {},
  key = "XF86AudioMute",
  description = "toggle mute",
  group = "media",
  on_press = function()
    Some.spawn("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle")
  end,
})

awful.key({
  modifiers = { modkey, shift },
  key = "P",
  description = "screenshot to clipboard",
  group = "applications",
  on_press = function()
    Some.spawn('grim -g "$(slurp)" - | wl-copy')
  end,
})

awful.key({
  modifiers = { modkey, shift },
  key = "S",
  description = "suspend system",
  group = "power",
  on_press = function()
    Some.spawn("systemctl suspend")
  end,
})

awful.key({
  modifiers = { modkey, shift },
  key = "H",
  description = "hibernate system",
  group = "power",
  on_press = function()
    Some.spawn("systemctl hibernate")
  end,
})

awful.key({
  modifiers = { modkey, shift },
  key = "R",
  description = "reboot system",
  group = "power",
  on_press = function()
    Some.spawn("systemctl reboot")
  end,
})

awful.key({
  modifiers = { modkey, shift },
  key = "Q",
  description = "quit SomeWM",
  group = "power",
  on_press = function()
    Some.quit()
  end,
})

-- Add a keybinding to show a widget
awful.key({
  modifiers = { modkey },
  key = "w",
  description = "show a test widget",
  group = "widgets",
  on_press = function()
    logger.info("'w' key pressed, creating notification widget")
    local ok, err = pcall(function()
      widgets.create_notification("Hello from SomeWM!", 5)
    end)
    if not ok then
      logger.error("Failed to create widget: " .. tostring(err))
    else
      logger.info("Widget creation successful")
    end
  end,
})

-- Add a keybinding to test LGI directly without C integration
awful.key({
  modifiers = { modkey },
  key = "g",
  description = "test lgi widget drawing",
  group = "widgets",
  on_press = function()
    logger.info("'g' key pressed, running direct LGI test")
    local ok, err = pcall(function()
      widgets.test_notification("Direct LGI Test", 5)
    end)
    if not ok then
      logger.error("Failed to run LGI test: " .. tostring(err))
    else
      logger.info("LGI test completed successfully")
    end
  end,
})

-- Add a keybinding specifically for testing the notification system
awful.key({
  modifiers = { modkey },
  key = "n",
  description = "test notification system",
  group = "widgets",
  on_press = function()
    logger.info("'n' key pressed, testing notification system")

    -- Use the system's notification directly
    local wayland_surface = require("wayland_surface")
    wayland_surface.create_widget_surface(300, 100, 50, 50, "Test Notification via system notification")
  end,
})

-- Add a keybinding to test alternative notification methods
awful.key({
  modifiers = { modkey },
  key = "d",
  description = "test menu-based notification",
  group = "widgets",
  on_press = function()
    logger.info("'d' key pressed, testing menu-based notification")

    -- Use the direct message display function
    local wayland_surface = require("wayland_surface")
    wayland_surface.display_message("Test menu-based notification")
  end,
})

-- Add a keybinding to test the client API
awful.key({
  modifiers = { modkey },
  key = "c",
  description = "test client API",
  group = "clients",
  on_press = function()
    logger.info("'c' key pressed, testing client API")
    dofile("test_client_api.lua")
  end,
})

-- Add a keybinding to test client manipulation
awful.key({
  modifiers = { modkey, shift },
  key = "c",
  description = "test client manipulation",
  group = "clients",
  on_press = function()
    logger.info("'Shift+c' key pressed, testing client manipulation")
    dofile("test_client_manipulation.lua")
  end,
})

-- Add a keybinding to test the event system
awful.key({
  modifiers = { modkey },
  key = "e",
  description = "setup event system tests",
  group = "clients",
  on_press = function()
    logger.info("'e' key pressed, setting up event system tests")
    dofile("test_events.lua")
  end,
})

-- Add a keybinding for practical event examples
awful.key({
  modifiers = { modkey, shift },
  key = "e",
  description = "enable practical event-based window management",
  group = "clients",
  on_press = function()
    logger.info("'Shift+e' key pressed, enabling practical event-based window management")
    dofile("practical_event_example.lua")
  end,
})

-- Phase 4: Monitor & Tag Management Tests
awful.key({
  modifiers = { modkey },
  key = "m",
  description = "test monitor API",
  group = "clients",
  on_press = function()
    logger.info("'m' key pressed, testing monitor API")
    dofile("test_monitor_api.lua")
  end,
})

awful.key({
  modifiers = { modkey, shift },
  key = "m",
  description = "test monitor management",
  group = "clients",
  on_press = function()
    logger.info("'Shift+m' key pressed, testing monitor management")
    dofile("test_monitor_manipulation.lua")
  end,
})

awful.key({
  modifiers = { modkey },
  key = "t",
  description = "test tag API",
  group = "clients",
  on_press = function()
    logger.info("'t' key pressed, testing tag API")
    dofile("test_tag_api.lua")
  end,
})

awful.key({
  modifiers = { modkey, shift },
  key = "t",
  description = "test tag management",
  group = "clients",
  on_press = function()
    logger.info("'Shift+t' key pressed, testing tag management")
    dofile("test_tag_manipulation.lua")
  end,
})

-- Add some practical client manipulation keybindings
awful.key({
  modifiers = { modkey },
  key = "f",
  description = "toggle focused client fullscreen",
  group = "clients",
  on_press = function()
    local client = require("client")
    local focused = client.get_focused()
    if focused then
      client.toggle_fullscreen(focused)
      logger.info("Toggled fullscreen for: " .. (client.get_title(focused) or "Untitled"))
    end
  end,
})

awful.key({
  modifiers = { modkey, shift },
  key = "space",
  description = "toggle focused client floating",
  group = "clients",
  on_press = function()
    local client = require("client")
    local focused = client.get_focused()
    if focused then
      client.toggle_floating(focused)
      logger.info("Toggled floating for: " .. (client.get_title(focused) or "Untitled"))
    end
  end,
})

awful.key({
  modifiers = { modkey },
  key = "q",
  description = "close focused client",
  group = "clients",
  on_press = function()
    local client = require("client")
    local focused = client.get_focused()
    if focused then
      local title = client.get_title(focused) or "Untitled"
      client.close(focused)
      logger.info("Closed client: " .. title)
    end
  end,
})


Some.hello_world()
