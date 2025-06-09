-- Core layer for SomeWM
-- Window manager functionality based on AwesomeWM's awful/ architecture
-- Requires foundation layer and provides high-level compositor control

-- Import foundation layer
local foundation = require("foundation")

-- Core layer modules with lazy loading to prevent circular dependencies
local core = {}

-- Lazy loading pattern from AwesomeWM
local function lazy_require(module_name)
  return setmetatable({}, {
    __index = function(_, key)
      local module = require("core." .. module_name)
      return module[key]
    end,
    __newindex = function(_, key, value)
      local module = require("core." .. module_name)
      module[key] = value
    end
  })
end

-- Core modules
core.client = lazy_require("client")
core.monitor = lazy_require("monitor") 
core.tag = lazy_require("tag")
core.rules = lazy_require("rules")

-- Initialize core systems
function core.init()
  -- Initialize foundation first
  foundation.init()
  foundation.logger.info("Core layer initializing")
  
  -- Initialize tag system
  core.tag.get_count() -- This triggers tag initialization
  
  -- Set up global client event handling
  foundation.signal.connect("client::new", function(c_client)
    local client = core.client.create_client_object(c_client)
    if client then
      foundation.signal.emit("client::manage", client)
      -- Apply rules to new client
      core.rules.apply_to_client(client)
    end
  end)
  
  -- Set up cleanup handlers
  foundation.signal.connect("client::destroyed", function(c_client)
    core.client.cleanup_client(c_client)
  end)
  
  foundation.signal.connect("monitor::destroyed", function(c_monitor)
    core.monitor.cleanup_monitor(c_monitor)
  end)
  
  foundation.logger.info("Core layer initialized")
  foundation.signal.emit("core::ready")
  
  return true
end

-- Clean shutdown of core systems
function core.shutdown()
  foundation.logger.info("Core layer shutting down")
  
  -- Clear all rules
  core.rules.clear()
  
  -- Emit shutdown signal
  foundation.signal.emit("core::shutdown")
  
  -- Shutdown foundation
  foundation.shutdown()
end

-- Core version information
core._VERSION = "1.0.0"
core._DESCRIPTION = "SomeWM Core Layer - Window manager functionality"
core._LICENSE = "MIT"

-- Utility functions for common operations

-- Get the focused screen/monitor
function core.get_focused_screen()
  return core.monitor.get_focused() or core.monitor.get_primary()
end

-- Get current workspace/tag information
function core.get_current_workspace()
  local screen = core.get_focused_screen()
  if not screen then return nil end
  
  local tag_mask = screen.tags
  local tag_list = core.tag.mask_to_list(tag_mask)
  
  return {
    screen = screen,
    tags = tag_list,
    tag_names = {},
    clients = {}
  }
end

-- Spawn application with enhanced features
function core.spawn(cmd, properties)
  properties = properties or {}
  
  -- Use foundation logger
  foundation.logger.info("Spawning: " .. cmd)
  
  -- Store properties for upcoming client
  if properties.rule then
    -- Add temporary rule for this spawn
    local spawn_rule = {
      rule = properties.rule,
      properties = properties.properties or {},
      description = "Temporary spawn rule for: " .. cmd,
      stop_processing = properties.stop_processing
    }
    
    local rule_id = core.rules.add(spawn_rule)
    
    -- Remove rule after timeout (in case app doesn't start)
    foundation.signal.connect_once("client::manage", function()
      core.rules.remove(rule_id)
    end)
  end
  
  -- Spawn using C API
  return Some.spawn(cmd)
end

-- Advanced client management
function core.manage_client(client, options)
  options = options or {}
  
  foundation.logger.debug("Managing client: " .. (client.title or "unknown"))
  
  -- Apply focus if requested
  if options.focus then
    client:focus()
  end
  
  -- Apply rules if not disabled
  if options.apply_rules ~= false then
    core.rules.apply_to_client(client)
  end
  
  -- Custom callback
  if options.callback and type(options.callback) == "function" then
    options.callback(client)
  end
  
  foundation.signal.emit("core::client_managed", client, options)
end

-- Layout management utilities
function core.arrange_clients(screen, layout_name)
  screen = screen or core.get_focused_screen()
  if not screen then return end
  
  layout_name = layout_name or "tile"
  
  foundation.logger.debug("Arranging clients with layout: " .. layout_name)
  
  -- Use monitor's layout calculation
  core.monitor.apply_layout(screen, layout_name)
  
  foundation.signal.emit("core::layout_applied", screen, layout_name)
end

-- Tag management utilities
function core.view_tag(tag_number, screen)
  screen = screen or core.get_focused_screen()
  if not screen then return false end
  
  local success = core.tag.view_on_monitor(screen, tag_number)
  if success then
    foundation.signal.emit("core::tag_viewed", tag_number, screen)
  end
  
  return success
end

function core.toggle_tag(tag_number, screen)
  screen = screen or core.get_focused_screen()
  if not screen then return false end
  
  local tag_mask = 1 << (tag_number - 1)
  local current_tags = screen.tags
  local new_tags = current_tags ~ tag_mask  -- XOR to toggle
  
  screen.tags = new_tags
  foundation.signal.emit("core::tag_toggled", tag_number, screen)
  
  return true
end

-- Client-to-tag assignment
function core.move_client_to_tag(client, tag_number)
  if not client or tag_number < 1 or tag_number > core.tag.get_count() then
    return false
  end
  
  local tag_mask = 1 << (tag_number - 1)
  client.tags = tag_mask
  
  foundation.signal.emit("core::client_moved_to_tag", client, tag_number)
  return true
end

function core.toggle_client_tag(client, tag_number)
  if not client or tag_number < 1 or tag_number > core.tag.get_count() then
    return false
  end
  
  local tag_mask = 1 << (tag_number - 1)
  client.tags = client.tags ~ tag_mask  -- XOR to toggle
  
  foundation.signal.emit("core::client_tag_toggled", client, tag_number)
  return true
end

-- Core statistics and debugging
function core.get_stats()
  local clients = core.client.get_all()
  local monitors = core.monitor.get_all()
  local rules_stats = core.rules.get_stats()
  
  return {
    clients = {
      total = #clients,
      floating = 0,
      fullscreen = 0,
      focused = core.client.get_focused()
    },
    monitors = {
      total = #monitors,
      focused = core.monitor.get_focused()
    },
    tags = {
      total = core.tag.get_count(),
      active = core.tag.get_active_list(),
      occupied = core.tag.get_occupied_list(),
      urgent = core.tag.get_urgent_list()
    },
    rules = rules_stats
  }
end

-- Core signal handling
function core.connect_signal(signal_name, callback)
  foundation.signal.connect("core::" .. signal_name, callback)
end

function core.disconnect_signal(signal_name, callback)
  foundation.signal.disconnect("core::" .. signal_name, callback)
end

-- Export core layer
return core