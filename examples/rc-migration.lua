-- SomeWM Migration Example Configuration
-- Shows how to migrate from old API to new 3-layer architecture
-- Demonstrates old vs new patterns without compatibility layer

local somewm = require("somewm")

-- Initialize SomeWM
somewm.init({
  stack_insert_mode = "bottom",
  smart_behaviors = true
})

-- Configuration
local config = {
  terminal = "wezterm",
  modkey = "logo"
}

-- === NEW API USAGE (RECOMMENDED) ===

-- Use new unified API
somewm.key({
  modifiers = { config.modkey },
  key = "Return",
  description = "launch terminal (new API)",
  group = "applications",
  on_press = function()
    somewm.spawn(config.terminal)  -- New API
  end,
})

-- Use property access
somewm.key({
  modifiers = { config.modkey },
  key = "f",
  description = "toggle fullscreen (new API)",
  group = "clients",
  on_press = function()
    local focused = somewm.get_focused_client()  -- New API
    if focused then
      focused.fullscreen = not focused.fullscreen  -- Property access
      somewm.notify("Fullscreen toggled", 2)  -- New widget API
    end
  end,
})

-- === MIGRATION EXAMPLES ===

-- Example: Old require pattern vs new unified API
somewm.key({
  modifiers = { config.modkey },
  key = "t",
  description = "demonstrate old vs new patterns",
  group = "migration",
  on_press = function()
    -- OLD PATTERN (don't use):
    -- local client = require("client")
    -- local focused = client.get_focused()
    -- local title = client.get_title(focused)
    -- client.toggle_floating(focused)
    
    -- NEW PATTERN (recommended):
    local focused = somewm.get_focused_client()
    if focused then
      local title = focused.title  -- Property access
      focused.floating = not focused.floating  -- Property setter
      somewm.notify("New API: " .. (title or "Unknown"), 2)
    end
  end,
})

-- Example: Widget creation patterns
somewm.key({
  modifiers = { config.modkey },
  key = "w",
  description = "demonstrate widget patterns",
  group = "migration",
  on_press = function()
    -- OLD PATTERN (don't use):
    -- local widgets = require("widgets")
    -- widgets.create_notification("Old API", 3)
    
    -- NEW PATTERN (recommended):
    somewm.notify("New unified API", 3)
  end,
})

-- Example: Logging patterns
somewm.key({
  modifiers = { config.modkey },
  key = "l",
  description = "demonstrate logging patterns",
  group = "migration",
  on_press = function()
    -- OLD PATTERN (don't use):
    -- local logger = require("logger")
    -- logger.info("Old logging")
    
    -- NEW PATTERN (recommended):
    somewm.base.logger.info("New logging via unified API")
    somewm.notify("Check logs for migration example", 2)
  end,
})

-- === WINDOW RULES (NEW API) ===

-- Modern declarative rules
somewm.add_window_rule(
  { class = "firefox" },
  { set_tag = "web", set_floating = false },
  "Firefox to web workspace"
)

somewm.add_window_rule(
  { title = ".*[Tt]erminal.*" },
  { set_tag = "term" },
  "Terminals to term workspace"
)

-- === EVENT HANDLING (NEW API) ===

-- Use new signal system
somewm.core.client.connect_signal("manage", function(client)
  somewm.base.logger.info(string.format("New client managed: %s", 
    client.title or "Untitled"))
  
  -- Welcome notification for new windows
  somewm.notify(string.format("Welcome: %s", client.class or "New Window"), 2)
end)

-- === MIGRATION COMPLETE ===

somewm.key({
  modifiers = { config.modkey, "Shift" },
  key = "C",
  description = "migration completed successfully",
  group = "migration",
  on_press = function()
    somewm.notify("Migration to new API complete!", 3)
    somewm.base.logger.info("All code now uses new 3-layer architecture")
  end,
})

-- === COMPARISON EXAMPLES ===

-- Example showing old vs new patterns
somewm.key({
  modifiers = { config.modkey },
  key = "o",
  description = "old vs new API comparison",
  group = "test",
  on_press = function()
    local focused = somewm.get_focused_client()
    if not focused then return end
    
    -- OLD WAY (still works with compatibility):
    -- local client = require("client")
    -- local focused = client.get_focused()
    -- local title = client.get_title(focused)
    -- client.toggle_fullscreen(focused)
    -- local widgets = require("widgets")
    -- widgets.create_notification("Old: " .. title, 3)
    
    -- NEW WAY (recommended):
    local title = focused.title
    focused.fullscreen = not focused.fullscreen
    somewm.notify("New: " .. (title or "Untitled"), 3)
    
    somewm.base.logger.info("Demonstrated old vs new API patterns")
  end,
})

-- Initialize compositor
Some.hello_world()

-- Startup notification
somewm.notify("Migration example loaded - demonstrates old vs new patterns", 5)

somewm.base.logger.info("Migration configuration loaded")
somewm.base.logger.info("Shows side-by-side comparison of old vs new API patterns")
somewm.base.logger.info("Use keybindings to see migration examples in action")