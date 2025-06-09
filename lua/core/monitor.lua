-- Core monitor management for SomeWM
-- Based on AwesomeWM's awful.screen with base.object integration

local base = require("base")

local monitor = {}

-- Weak table to store monitor objects by C pointer
local monitor_objects = setmetatable({}, { __mode = "v" })

-- Create a monitor object wrapper with base.object features
local function create_monitor_object(c_monitor)
  if not c_monitor then return nil end
  
  -- Check if we already have an object for this monitor
  if monitor_objects[c_monitor] then
    return monitor_objects[c_monitor]
  end
  
  -- Create new monitor object based on base.object
  local obj = base.object.new()
  
  -- Store the C monitor pointer privately
  obj:set_private("c_monitor", c_monitor)
  
  -- Add property definitions with getters/setters
  obj:add_property("name", {
    getter = function(self)
      local m = self:get_private().c_monitor
      return m and Some.monitor_get_name(m) or nil
    end
  })
  
  obj:add_property("geometry", {
    getter = function(self)
      local m = self:get_private().c_monitor
      return m and Some.monitor_get_geometry(m) or base.geometry.rectangle(0, 0, 0, 0)
    end
  })
  
  obj:add_property("workarea", {
    getter = function(self)
      local m = self:get_private().c_monitor
      return m and Some.monitor_get_workarea(m) or base.geometry.rectangle(0, 0, 0, 0)
    end
  })
  
  obj:add_property("layout_symbol", {
    getter = function(self)
      local m = self:get_private().c_monitor
      return m and Some.monitor_get_layout_symbol(m) or ""
    end
  })
  
  obj:add_property("master_factor", {
    getter = function(self)
      local m = self:get_private().c_monitor
      return m and Some.monitor_get_master_factor(m) or 0.6
    end,
    setter = function(self, factor)
      local m = self:get_private().c_monitor
      if m and factor then
        Some.monitor_set_master_factor(m, factor)
        self:emit_signal("property::master_factor", factor)
      end
    end
  })
  
  obj:add_property("master_count", {
    getter = function(self)
      local m = self:get_private().c_monitor
      return m and Some.monitor_get_master_count(m) or 1
    end,
    setter = function(self, count)
      local m = self:get_private().c_monitor
      if m and count then
        Some.monitor_set_master_count(m, count)
        self:emit_signal("property::master_count", count)
      end
    end
  })
  
  obj:add_property("tags", {
    getter = function(self)
      local m = self:get_private().c_monitor
      return m and Some.monitor_get_tags(m) or 0
    end,
    setter = function(self, tags)
      local m = self:get_private().c_monitor
      if m then
        Some.monitor_set_tags(m, tags)
        self:emit_signal("property::tags", tags)
      end
    end
  })
  
  obj:add_property("enabled", {
    getter = function(self)
      local m = self:get_private().c_monitor
      return m and Some.monitor_get_enabled(m) or false
    end
  })
  
  -- Add monitor-specific methods
  function obj:focus()
    local m = self:get_private().c_monitor
    if m then
      Some.monitor_focus(m)
      self:emit_signal("request::activate", "monitor.focus")
    end
  end
  
  -- Convenience methods for layout management
  function obj:adjust_master_factor(delta)
    local current = self.master_factor
    local new_factor = math.max(0.1, math.min(0.9, current + delta))
    self.master_factor = new_factor
  end
  
  function obj:adjust_master_count(delta)
    local current = self.master_count
    local new_count = math.max(0, current + delta)
    self.master_count = new_count
  end
  
  -- Get available tiling area for clients
  function obj:get_tiling_area()
    return self.workarea
  end
  
  -- Get clients on this monitor
  function obj:get_clients()
    local core_client = require("core.client")
    local all_clients = core_client.get_all()
    local monitor_clients = {}
    
    for _, client in ipairs(all_clients) do
      -- Check if client's geometry intersects with monitor
      if base.geometry.intersects(client.geometry, self.geometry) then
        table.insert(monitor_clients, client)
      end
    end
    
    return monitor_clients
  end
  
  -- Get visible clients (non-minimized, on current tags)
  function obj:get_visible_clients()
    local clients = self:get_clients()
    local visible = {}
    
    for _, client in ipairs(clients) do
      -- Check if client is on current tags
      if client.tags & self.tags ~= 0 then
        table.insert(visible, client)
      end
    end
    
    return visible
  end
  
  -- Info method for debugging
  function obj:info()
    return {
      name = self.name,
      geometry = self.geometry,
      workarea = self.workarea,
      layout_symbol = self.layout_symbol,
      master_factor = self.master_factor,
      master_count = self.master_count,
      tags = self.tags,
      enabled = self.enabled
    }
  end
  
  -- Store in our weak table
  monitor_objects[c_monitor] = obj
  
  return obj
end

-- Public API functions

-- Get all monitors as objects
function monitor.get_all()
  local c_monitors = Some.monitor_get_all()
  local objects = {}
  
  for i, m in ipairs(c_monitors) do
    objects[i] = create_monitor_object(m)
  end
  
  return objects
end

-- Get focused monitor as object
function monitor.get_focused()
  local c_monitor = Some.monitor_get_focused()
  return create_monitor_object(c_monitor)
end

-- Get primary monitor (first one or focused)
function monitor.get_primary()
  local focused = monitor.get_focused()
  if focused then
    return focused
  end
  
  local monitors = monitor.get_all()
  if #monitors > 0 then
    return monitors[1]
  end
  
  return nil
end

-- Convenience functions
function monitor.find_by_name(name)
  local monitors = monitor.get_all()
  for _, m in ipairs(monitors) do
    if m.name == name then
      return m
    end
  end
  return nil
end

function monitor.get_all_info()
  local monitors = monitor.get_all()
  local info_list = {}
  
  for i, m in ipairs(monitors) do
    info_list[i] = m:info()
  end
  
  return info_list
end

-- Monitor layout calculations
function monitor.calculate_layout(monitor_obj, layout_name)
  layout_name = layout_name or "tile"
  
  local clients = monitor_obj:get_visible_clients()
  local area = monitor_obj:get_tiling_area()
  
  if #clients == 0 then return {} end
  
  if layout_name == "tile" then
    -- Calculate tiled layout using base.geometry
    local master_count = math.min(monitor_obj.master_count, #clients)
    local master_width = area.width * monitor_obj.master_factor
    
    local geometries = {}
    
    if master_count == #clients then
      -- All clients are masters
      local master_areas = base.geometry.split_vertical(area, master_count)
      for i, client in ipairs(clients) do
        geometries[client] = master_areas[i]
      end
    else
      -- Split between master and stack
      local master_area = base.geometry.rectangle(
        area.x, area.y, master_width, area.height
      )
      local stack_area = base.geometry.rectangle(
        area.x + master_width, area.y, area.width - master_width, area.height
      )
      
      -- Arrange masters
      if master_count > 0 then
        local master_areas = base.geometry.split_vertical(master_area, master_count)
        for i = 1, master_count do
          geometries[clients[i]] = master_areas[i]
        end
      end
      
      -- Arrange stack
      local stack_count = #clients - master_count
      if stack_count > 0 then
        local stack_areas = base.geometry.split_vertical(stack_area, stack_count)
        for i = 1, stack_count do
          geometries[clients[master_count + i]] = stack_areas[i]
        end
      end
    end
    
    return geometries
    
  elseif layout_name == "max" then
    -- Maximize all clients
    local geometries = {}
    for _, client in ipairs(clients) do
      geometries[client] = area
    end
    return geometries
    
  elseif layout_name == "floating" then
    -- Keep current geometries for floating
    local geometries = {}
    for _, client in ipairs(clients) do
      geometries[client] = client.geometry
    end
    return geometries
  end
  
  return {}
end

-- Apply layout to monitor
function monitor.apply_layout(monitor_obj, layout_name)
  local geometries = monitor.calculate_layout(monitor_obj, layout_name)
  
  for client, geometry in pairs(geometries) do
    if not client.floating then
      client.geometry = geometry
    end
  end
  
  base.signal.emit("monitor::layout_applied", monitor_obj, layout_name)
end

-- Signal handling (delegates to global signals)
function monitor.connect_signal(signal_name, callback)
  base.signal.connect("monitor::" .. signal_name, callback)
end

function monitor.disconnect_signal(signal_name, callback)
  base.signal.disconnect("monitor::" .. signal_name, callback)
end

-- Monitor-specific signal handlers
function monitor.on_added(callback)
  monitor.connect_signal("added", callback)
end

function monitor.on_removed(callback)
  monitor.connect_signal("removed", callback)
end

function monitor.on_property_change(property, callback)
  monitor.connect_signal("property::" .. property, callback)
end

-- Cleanup function for when monitors are destroyed
function monitor.cleanup_monitor(c_monitor)
  if monitor_objects[c_monitor] then
    local obj = monitor_objects[c_monitor]
    obj:emit_signal("destroy")
    obj:destroy()
    monitor_objects[c_monitor] = nil
  end
end

return monitor