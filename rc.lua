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
    Some.spawn("pamixer -i 5")
  end,
})

awful.key({
  modifiers = {},
  key = "XF86AudioLowerVolume",
  description = "lower volume",
  group = "media",
  on_press = function()
    Some.spawn("pamixer -d 5")
  end,
})

awful.key({
  modifiers = {},
  key = "XF86AudioMute",
  description = "toggle mute",
  group = "media",
  on_press = function()
    Some.spawn("pamixer -t")
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

Some.hello_world()
