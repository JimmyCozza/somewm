-- UI layer initialization for SomeWM
-- High-level user interface and automation modules
-- Inspired by AwesomeWM's modular architecture

local foundation = require("foundation")

-- Lazy loading table to prevent circular dependencies
local ui = {}

-- Create lazy loading metatable
local lazy_modules = {
  widgets = "ui.widgets",
  keybindings = "ui.keybindings", 
  automation = "ui.automation"
}

setmetatable(ui, {
  __index = function(table, key)
    local module_path = lazy_modules[key]
    if module_path then
      foundation.logger.debug("Lazy loading UI module: " .. module_path)
      local module = require(module_path)
      rawset(table, key, module)
      return module
    end
    return nil
  end
})

-- Initialize automation system when ui is loaded
local function init_automation()
  if ui.automation and ui.automation.init then
    ui.automation.init()
  end
end

-- Auto-initialize when first accessed
local original_index = getmetatable(ui).__index
setmetatable(ui, {
  __index = function(table, key)
    local result = original_index(table, key)
    
    -- Initialize automation on first module access
    if not rawget(table, "_initialized") and result then
      rawset(table, "_initialized", true)
      -- Delay initialization to avoid circular dependencies
      local timer = foundation.signal.connect_once("ui_ready", init_automation)
      foundation.signal.emit("ui_ready")
    end
    
    return result
  end
})

-- Convenience functions for common operations
function ui.notify(text, timeout, config)
  return ui.widgets.create_notification(text, timeout, config)
end

function ui.bind_key(modifiers, key, callback, description, group)
  return ui.keybindings.key(modifiers, key, callback, description, group)
end

function ui.add_window_rule(conditions, actions, description)
  return ui.automation.add_window_rule(conditions, actions, description)
end

-- Bulk operations
function ui.clear_all()
  if rawget(ui, "widgets") then
    ui.widgets.clear_all()
  end
  if rawget(ui, "keybindings") then  
    ui.keybindings.clear_all()
  end
  if rawget(ui, "automation") then
    ui.automation.clear_all_rules()
  end
  foundation.logger.info("All UI components cleared")
end

function ui.get_stats()
  local stats = {
    widgets = rawget(ui, "widgets") and #ui.widgets.get_active_widgets() or 0,
    keybindings = rawget(ui, "keybindings") and #ui.keybindings.get_all() or 0,
    automation = rawget(ui, "automation") and ui.automation.get_stats().total_rules or 0
  }
  return stats
end

-- Enable common smart behaviors
function ui.enable_smart_behaviors()
  ui.automation.enable_smart_focus()
  ui.automation.enable_smart_placement()
  ui.automation.enable_tag_persistence()
  foundation.logger.info("Smart behaviors enabled")
end

-- Help system
function ui.show_help()
  if rawget(ui, "keybindings") then
    local help_text = ui.keybindings.get_help_text()
    foundation.logger.info("Keybinding Help:\n" .. help_text)
    
    -- Could also show as notification
    if rawget(ui, "widgets") then
      ui.notify("Help displayed in logs", 3)
    end
  end
end

return ui