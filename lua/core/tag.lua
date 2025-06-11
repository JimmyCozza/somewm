-- Core tag/workspace management for SomeWM
-- Based on AwesomeWM's awful.tag with base.object integration

local base = require("base")

local tag = {}

-- Tag configuration and state storage
local tag_config = {
  count = nil,  -- Will be retrieved from C
  names = {},   -- Custom tag names
  layouts = {}  -- Per-tag layout settings
}

-- Initialize tag system
local function init_tags()
  if not tag_config.count then
    tag_config.count = Some.tag_get_count()
    
    -- Set default names
    for i = 1, tag_config.count do
      tag_config.names[i] = tostring(i)
      tag_config.layouts[i] = "tile"
    end
  end
end

-- Tag object creation (represents a single tag)
local function create_tag_object(tag_number)
  if not tag_number or tag_number < 1 or tag_number > tag.get_count() then
    return nil
  end
  
  local obj = base.object.new()
  
  -- Store tag number privately
  obj:set_private("tag_number", tag_number)
  
  -- Add properties
  obj:add_property("number", {
    getter = function(self)
      return self:get_private().tag_number
    end
  })
  
  obj:add_property("name", {
    getter = function(self)
      local num = self:get_private().tag_number
      return tag_config.names[num] or tostring(num)
    end,
    setter = function(self, name)
      local num = self:get_private().tag_number
      tag_config.names[num] = name
      self:emit_signal("property::name", name)
    end
  })
  
  obj:add_property("active", {
    getter = function(self)
      local num = self:get_private().tag_number
      return tag.is_active(num)
    end
  })
  
  obj:add_property("occupied", {
    getter = function(self)
      local num = self:get_private().tag_number
      return tag.is_occupied(num)
    end
  })
  
  obj:add_property("urgent", {
    getter = function(self)
      local num = self:get_private().tag_number
      return tag.is_urgent(num)
    end
  })
  
  obj:add_property("layout", {
    getter = function(self)
      local num = self:get_private().tag_number
      return tag_config.layouts[num] or "tile"
    end,
    setter = function(self, layout)
      local num = self:get_private().tag_number
      tag_config.layouts[num] = layout
      self:emit_signal("property::layout", layout)
      base.signal.emit("tag::layout_changed", self, layout)
    end
  })
  
  -- Tag methods
  function obj:view()
    local num = self:get_private().tag_number
    return tag.view(num)
  end
  
  function obj:toggle()
    local num = self:get_private().tag_number
    return tag.toggle(num)
  end
  
  function obj:view_on_monitor(monitor)
    local num = self:get_private().tag_number
    if monitor and monitor.get_private then
      local m = monitor:get_private().c_monitor
      return tag.view_on_monitor(m, num)
    end
    return false
  end
  
  function obj:get_clients()
    local core_client = require("core.client")
    local all_clients = core_client.get_all()
    local tag_clients = {}
    local tag_mask = 1 << (self.number - 1)
    
    for _, client in ipairs(all_clients) do
      if client.tags & tag_mask ~= 0 then
        table.insert(tag_clients, client)
      end
    end
    
    return tag_clients
  end
  
  function obj:get_visible_clients()
    if not self.active then
      return {}
    end
    return self:get_clients()
  end
  
  return obj
end

-- Public API functions

-- Get tag count
function tag.get_count()
  init_tags()
  return tag_config.count
end

-- Get all tag objects
function tag.get_all()
  local tags = {}
  local count = tag.get_count()
  
  for i = 1, count do
    tags[i] = create_tag_object(i)
  end
  
  return tags
end

-- Get tag object by number
function tag.get(tag_number)
  return create_tag_object(tag_number)
end

-- Current tag functions (using bitmasks)
function tag.get_current()
  return Some.tag_get_current()
end

function tag.set_current(tags)
  Some.tag_set_current(tags)
  base.signal.emit("tag::view_changed", tags)
end

function tag.toggle_view(tags)
  Some.tag_toggle_view(tags)
  base.signal.emit("tag::view_toggled", tags)
end

-- Tag state functions
function tag.get_occupied()
  return Some.tag_get_occupied()
end

function tag.get_urgent()
  return Some.tag_get_urgent()
end

-- Monitor-specific tag functions
function tag.get_current_for_monitor(monitor)
  if monitor and monitor.get_private then
    local m = monitor:get_private().c_monitor
    return Some.monitor_get_tags(m)
  end
  return 0
end

function tag.set_current_for_monitor(monitor, tags)
  if monitor and monitor.get_private then
    local m = monitor:get_private().c_monitor
    Some.monitor_set_tags(m, tags)
    base.signal.emit("tag::monitor_view_changed", monitor, tags)
  end
end

-- Convenience functions for individual tags
function tag.view(tag_number)
  if tag_number < 1 or tag_number > tag.get_count() then
    return false
  end
  
  local tag_mask = 1 << (tag_number - 1)
  tag.set_current(tag_mask)
  return true
end

function tag.toggle(tag_number)
  if tag_number < 1 or tag_number > tag.get_count() then
    return false
  end
  
  local tag_mask = 1 << (tag_number - 1)
  tag.toggle_view(tag_mask)
  return true
end

function tag.view_on_monitor(monitor, tag_number)
  if tag_number < 1 or tag_number > tag.get_count() then
    return false
  end
  
  local tag_mask = 1 << (tag_number - 1)
  tag.set_current_for_monitor(monitor, tag_mask)
  return true
end

-- Bitmask utility functions
function tag.mask_to_list(mask)
  local tags = {}
  local count = tag.get_count()
  
  for i = 1, count do
    if (mask & (1 << (i - 1))) ~= 0 then
      table.insert(tags, i)
    end
  end
  
  return tags
end

function tag.list_to_mask(tag_list)
  local mask = 0
  
  for _, tag_num in ipairs(tag_list) do
    if tag_num >= 1 and tag_num <= tag.get_count() then
      mask = mask | (1 << (tag_num - 1))
    end
  end
  
  return mask
end

-- Tag naming functions
function tag.get_names()
  init_tags()
  local names = {}
  for i = 1, tag_config.count do
    names[i] = tag_config.names[i]
  end
  return names
end

function tag.set_names(names)
  init_tags()
  for i, name in ipairs(names) do
    if i <= tag_config.count then
      tag_config.names[i] = name
    end
  end
  base.signal.emit("tag::names_changed", names)
end

function tag.get_name(tag_number)
  init_tags()
  return tag_config.names[tag_number] or tostring(tag_number)
end

function tag.set_name(tag_number, name)
  init_tags()
  if tag_number >= 1 and tag_number <= tag_config.count then
    tag_config.names[tag_number] = name
    base.signal.emit("tag::name_changed", tag_number, name)
  end
end

-- Tag state checking functions
function tag.is_active(tag_number)
  local current = tag.get_current()
  local tag_mask = 1 << (tag_number - 1)
  return (current & tag_mask) ~= 0
end

function tag.is_occupied(tag_number)
  local occupied = tag.get_occupied()
  local tag_mask = 1 << (tag_number - 1)
  return (occupied & tag_mask) ~= 0
end

function tag.is_urgent(tag_number)
  local urgent = tag.get_urgent()
  local tag_mask = 1 << (tag_number - 1)
  return (urgent & tag_mask) ~= 0
end

-- Comprehensive tag status
function tag.get_status()
  local count = tag.get_count()
  local current = tag.get_current()
  local occupied = tag.get_occupied()
  local urgent = tag.get_urgent()
  local status = {}
  
  for i = 1, count do
    local mask = 1 << (i - 1)
    status[i] = {
      number = i,
      name = tag.get_name(i),
      active = (current & mask) ~= 0,
      occupied = (occupied & mask) ~= 0,
      urgent = (urgent & mask) ~= 0,
      layout = tag_config.layouts[i] or "tile"
    }
  end
  
  return status
end

-- Active/occupied/urgent lists
function tag.get_active_list()
  return tag.mask_to_list(tag.get_current())
end

function tag.get_occupied_list()
  return tag.mask_to_list(tag.get_occupied())
end

function tag.get_urgent_list()
  return tag.mask_to_list(tag.get_urgent())
end

-- Layout management
function tag.set_layout(tag_number, layout)
  init_tags()
  if tag_number >= 1 and tag_number <= tag_config.count then
    tag_config.layouts[tag_number] = layout
    base.signal.emit("tag::layout_changed", tag_number, layout)
  end
end

function tag.get_layout(tag_number)
  init_tags()
  return tag_config.layouts[tag_number] or "tile"
end

-- Advanced tag operations
function tag.swap(tag1, tag2)
  if tag1 < 1 or tag1 > tag.get_count() or tag2 < 1 or tag2 > tag.get_count() then
    return false
  end
  
  -- Swap names
  local name1 = tag_config.names[tag1]
  local name2 = tag_config.names[tag2]
  tag_config.names[tag1] = name2
  tag_config.names[tag2] = name1
  
  -- Swap layouts
  local layout1 = tag_config.layouts[tag1]
  local layout2 = tag_config.layouts[tag2]
  tag_config.layouts[tag1] = layout2
  tag_config.layouts[tag2] = layout1
  
  base.signal.emit("tag::swapped", tag1, tag2)
  return true
end

-- Multiple tag selection
function tag.view_multiple(tag_list)
  local mask = tag.list_to_mask(tag_list)
  tag.set_current(mask)
end

function tag.view_none()
  tag.set_current(0)
end

function tag.view_all()
  local all_mask = (1 << tag.get_count()) - 1
  tag.set_current(all_mask)
end

-- Signal handling
function tag.connect_signal(signal_name, callback)
  base.signal.connect("tag::" .. signal_name, callback)
end

function tag.disconnect_signal(signal_name, callback)
  base.signal.disconnect("tag::" .. signal_name, callback)
end

-- Tag-specific signal handlers
function tag.on_view_changed(callback)
  tag.connect_signal("view_changed", callback)
end

function tag.on_layout_changed(callback)
  tag.connect_signal("layout_changed", callback)
end

function tag.on_name_changed(callback)
  tag.connect_signal("name_changed", callback)
end

return tag