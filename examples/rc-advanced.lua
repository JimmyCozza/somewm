-- SomeWM Advanced Configuration Example
-- Demonstrates advanced features of the 3-layer architecture

local somewm = require("somewm")

-- Initialize with full feature set
somewm.init({
  stack_insert_mode = "top",
  smart_behaviors = true
})

-- Advanced configuration
local config = {
  terminal = "wezterm",
  browser = "firefox",
  editor = "nvim",
  modkey = "logo",
  shift = "Shift",
  ctrl = "Control"
}

-- === APPLICATION LAUNCHERS ===
somewm.key({
  modifiers = { config.modkey },
  key = "Return",
  description = "launch terminal",
  group = "applications",
  on_press = function()
    somewm.spawn(config.terminal)
  end,
})

somewm.key({
  modifiers = { config.modkey },
  key = "b",
  description = "launch browser",
  group = "applications",
  on_press = function()
    somewm.spawn(config.browser)
  end,
})

somewm.key({
  modifiers = { config.modkey },
  key = "e",
  description = "launch editor",
  group = "applications",
  on_press = function()
    somewm.spawn(string.format("%s -e %s", config.terminal, config.editor))
  end,
})

-- === WINDOW MANAGEMENT ===
somewm.key({
  modifiers = { config.modkey },
  key = "f",
  description = "toggle fullscreen",
  group = "clients",
  on_press = function()
    local focused = somewm.get_focused_client()
    if focused then
      focused.fullscreen = not focused.fullscreen
      somewm.notify(string.format("Fullscreen: %s", focused.fullscreen and "ON" or "OFF"), 2)
    end
  end,
})

somewm.key({
  modifiers = { config.modkey, config.shift },
  key = "space",
  description = "toggle floating",
  group = "clients",
  on_press = function()
    local focused = somewm.get_focused_client()
    if focused then
      focused.floating = not focused.floating
      somewm.notify(string.format("Floating: %s", focused.floating and "ON" or "OFF"), 2)
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
      somewm.notify(string.format("Closed: %s", title), 2)
    end
  end,
})

-- === ADVANCED WINDOW RULES ===

-- Development environment
somewm.add_window_rule(
  { class = "code" },
  { set_tag = "dev", set_floating = false },
  "VS Code to dev workspace"
)

-- Terminal applications
somewm.add_window_rule(
  { class = "wezterm" },
  { set_tag = "term" },
  "Terminals to term workspace"
)

-- Media applications
somewm.add_window_rule(
  { class = "mpv" },
  { set_floating = true, focus = true },
  "MPV floating and focused"
)

-- Communication apps
somewm.add_window_rule(
  { class = "discord" },
  { set_tag = "chat", set_floating = false },
  "Discord to chat workspace"
)

-- Browser behavior
somewm.add_window_rule(
  { class = "firefox" },
  { set_tag = "web", set_floating = false },
  "Firefox to web workspace"
)

-- Floating dialogs
somewm.add_window_rule(
  { title = ".*[Dd]ialog.*" },
  { set_floating = true },
  "Dialogs floating"
)

-- === CUSTOM AUTOMATION ===

-- Smart terminal positioning
somewm.ui.automation.add_rule({
  type = somewm.ui.automation.RULE_TYPES.WINDOW_SPAWN,
  conditions = { 
    class = "wezterm",
    floating = true 
  },
  callback = function(context)
    local client = context.client
    if client then
      -- Center and resize terminal
      client:move(100, 100)
      client:resize(800, 600)
      somewm.notify("Terminal positioned", 1)
    end
  end,
  description = "Position floating terminals",
  priority = 80
})

-- Focus follows mouse for specific applications
somewm.ui.automation.add_rule({
  type = somewm.ui.automation.RULE_TYPES.WINDOW_FOCUS,
  conditions = { 
    class = function(class) 
      return class and (class:match("editor") or class:match("code"))
    end 
  },
  callback = function(context)
    local client = context.client
    if client and client.urgent then
      client.urgent = false
      somewm.notify(string.format("Focused: %s", client.title or "Editor"), 1)
    end
  end,
  description = "Clear urgent on editor focus",
  priority = 90
})

-- === WIDGETS AND NOTIFICATIONS ===

-- System status widget
somewm.key({
  modifiers = { config.modkey },
  key = "s",
  description = "show system status",
  group = "widgets",
  on_press = function()
    -- Get system info
    local clients = somewm.get_clients()
    local stats = somewm.get_stats()
    
    local status = string.format(
      "Clients: %d | Widgets: %d | Rules: %d",
      #clients,
      stats.ui.widgets or 0,
      stats.ui.automation or 0
    )
    
    somewm.notify(status, 5)
  end,
})

-- Help system
somewm.key({
  modifiers = { config.modkey },
  key = "h",
  description = "show help",
  group = "help",
  on_press = function()
    somewm.debug.show_help()
    somewm.notify("Help shown in logs", 2)
  end,
})

-- === CLIENT EVENT HANDLING ===

-- React to new windows
somewm.core.client.connect_signal("manage", function(client)
  somewm.base.logger.info(string.format("New client: %s (%s)", 
    client.title or "Untitled", client.class or "Unknown"))
  
  -- Show notification for new windows
  somewm.notify(string.format("New: %s", client.class or "Window"), 2)
end)

-- React to client focus changes
somewm.core.client.connect_signal("focus", function(client)
  somewm.base.logger.debug(string.format("Focused: %s", 
    client.title or "Untitled"))
end)

-- === POWER MANAGEMENT ===
somewm.key({
  modifiers = { config.modkey, config.shift },
  key = "Q",
  description = "quit SomeWM",
  group = "power",
  on_press = function()
    somewm.notify("Goodbye!", 2)
    -- Add small delay to show notification
    somewm.base.signal.connect_once("shutdown", function()
      somewm.base.logger.info("SomeWM shutting down...")
    end)
    somewm.quit()
  end,
})

-- === DEBUGGING ===
somewm.key({
  modifiers = { config.modkey, config.shift },
  key = "F1",
  description = "debug information",
  group = "debug",
  on_press = function()
    somewm.debug.show_stats()
    somewm.debug.list_signals()
  end,
})

-- === INITIALIZE ===

-- Enable additional smart behaviors
somewm.ui.automation.enable_smart_focus()
somewm.ui.automation.enable_smart_placement()
somewm.ui.automation.enable_tag_persistence()

-- Initialize compositor
Some.hello_world()

-- Welcome notification
somewm.notify("SomeWM Advanced Config Loaded", 3)

somewm.base.logger.info("Advanced SomeWM configuration loaded with full feature set")