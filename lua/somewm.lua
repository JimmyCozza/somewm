-- SomeWM unified library entry point
-- Provides complete 3-layer architecture: foundation + core + ui
-- Inspired by AwesomeWM's modular design

local somewm = {}

-- Import all three layers
local foundation = require("foundation")
local core = require("core")
local ui = require("ui")

-- Export layers directly
somewm.foundation = foundation
somewm.core = core
somewm.ui = ui

-- Convenience aliases for common operations
somewm.spawn = function(cmd)
  if core.spawn then
    return core.spawn(cmd)
  else
    -- Fallback to direct Some.spawn if core.spawn not available
    foundation.logger.warn("Using fallback Some.spawn - core.spawn not available")
    return Some.spawn(cmd)
  end
end

somewm.quit = function()
  -- Emit shutdown signals before quitting
  foundation.signal.emit("shutdown")
  ui.clear_all()
  
  -- Call compositor quit
  if Some.quit then
    Some.quit()
  else
    foundation.logger.error("Some.quit not available")
  end
end

-- Widget convenience functions
somewm.notify = function(text, timeout, config)
  return ui.notify(text, timeout, config)
end

somewm.create_notification = function(text, timeout, config)
  return ui.widgets.create_notification(text, timeout, config)
end

-- Keybinding convenience functions
somewm.bind_key = function(modifiers, key, callback, description, group)
  return ui.bind_key(modifiers, key, callback, description, group)
end

somewm.key = function(config)
  return ui.keybindings.add(config)
end

-- Automation convenience functions
somewm.add_rule = function(config)
  return ui.automation.add_rule(config)
end

somewm.add_window_rule = function(conditions, actions, description)
  return ui.add_window_rule(conditions, actions, description)
end

-- Client convenience functions
somewm.get_focused_client = function()
  return core.client.get_focused()
end

somewm.get_clients = function()
  return core.client.get_all()
end

-- Configuration helpers
somewm.config = {
  set_option = function(key, value)
    if key == "stack_insert_mode" then
      general_options = general_options or {}
      general_options.stack_insert_mode = value
      foundation.logger.info("Set stack_insert_mode to: " .. tostring(value))
    else
      foundation.logger.warn("Unknown config option: " .. tostring(key))
    end
  end,
  
  get_option = function(key)
    if key == "stack_insert_mode" then
      return general_options and general_options.stack_insert_mode or "bottom"
    else
      foundation.logger.warn("Unknown config option: " .. tostring(key))
      return nil
    end
  end
}

-- Enable smart behaviors by default
somewm.enable_smart_behaviors = function()
  ui.enable_smart_behaviors()
end

-- Initialization function
somewm.init = function(config)
  config = config or {}
  
  foundation.logger.info("SomeWM library initializing...")
  
  -- Set default config options
  if config.stack_insert_mode then
    somewm.config.set_option("stack_insert_mode", config.stack_insert_mode)
  end
  
  -- Enable smart behaviors if requested
  if config.smart_behaviors ~= false then
    somewm.enable_smart_behaviors()
  end
  
  -- Initialize logger if not already done
  if foundation.logger.init then
    foundation.logger.init()
  end
  
  foundation.logger.info("SomeWM library initialized")
  
  return somewm
end

-- Backward compatibility helpers
somewm.compat = {
  -- Legacy widget functions
  show_widget = function(widget)
    foundation.logger.warn("somewm.compat.show_widget is deprecated, use ui.widgets directly")
    return ui.widgets.show_widget(widget)
  end,
  
  hide_widget = function(widget)
    foundation.logger.warn("somewm.compat.hide_widget is deprecated, use ui.widgets directly")
    return ui.widgets.hide_widget(widget)
  end,
  
  -- Legacy client functions that might use old require("client")
  client = {
    get_focused = function()
      return core.client.get_focused()
    end,
    get_title = function(client)
      return client and client.title or nil
    end,
    close = function(client)
      if client and client.close then
        client:close()
      end
    end,
    toggle_fullscreen = function(client)
      if client then
        client.fullscreen = not client.fullscreen
      end
    end,
    toggle_floating = function(client)
      if client then
        client.floating = not client.floating
      end
    end
  }
}

-- Statistics and debugging
somewm.get_stats = function()
  return {
    foundation = foundation.signal.get_stats(),
    core = core.client and core.client.get_stats and core.client.get_stats() or {},
    ui = ui.get_stats()
  }
end

somewm.debug = {
  show_help = function()
    ui.show_help()
  end,
  
  list_signals = function()
    foundation.logger.info("Global signals: " .. table.concat(foundation.signal.get_signal_names(), ", "))
  end,
  
  show_stats = function()
    local stats = somewm.get_stats()
    foundation.logger.info("SomeWM Stats:")
    foundation.logger.info("  Foundation signals: " .. (stats.foundation and #stats.foundation or 0))
    foundation.logger.info("  UI widgets: " .. (stats.ui.widgets or 0))
    foundation.logger.info("  UI keybindings: " .. (stats.ui.keybindings or 0))
    foundation.logger.info("  UI automation rules: " .. (stats.ui.automation or 0))
  end
}

-- Version information
somewm.version = {
  major = 0,
  minor = 4,
  patch = 0,
  string = "0.4.0-dev",
  codename = "Phase5"
}

-- Module metadata
somewm._info = {
  name = "SomeWM",
  description = "A dwl-based Wayland compositor with Lua scripting",
  architecture = "3-layer (foundation/core/ui)",
  phase = 5
}

return somewm