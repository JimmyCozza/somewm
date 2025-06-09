-- Core client management for SomeWM
-- Based on AwesomeWM's awful.client with base.object integration

local base = require("base")

local client = {}

-- Weak table to store client objects by C pointer
local client_objects = setmetatable({}, { __mode = "v" })

-- Create a client object wrapper with base.object features
local function create_client_object(c_client)
  if not c_client then return nil end
  
  -- Check if we already have an object for this client
  if client_objects[c_client] then
    return client_objects[c_client]
  end
  
  -- Create new client object based on base.object
  local obj = base.object.new()
  
  -- Store the C client pointer privately
  obj:set_private("c_client", c_client)
  
  -- Add property definitions with getters/setters
  obj:add_property("title", {
    getter = function(self)
      local c = self:get_private().c_client
      return c and Some.client_get_title(c) or nil
    end
  })
  
  obj:add_property("appid", {
    getter = function(self)
      local c = self:get_private().c_client
      return c and Some.client_get_appid(c) or nil
    end
  })
  
  obj:add_property("pid", {
    getter = function(self)
      local c = self:get_private().c_client
      return c and Some.client_get_pid(c) or nil
    end
  })
  
  obj:add_property("geometry", {
    getter = function(self)
      local c = self:get_private().c_client
      return c and Some.client_get_geometry(c) or base.geometry.rectangle(0, 0, 0, 0)
    end,
    setter = function(self, geom)
      local c = self:get_private().c_client
      if c and geom then
        Some.client_set_geometry(c, geom.x, geom.y, geom.width, geom.height)
        self:emit_signal("property::geometry", geom)
      end
    end
  })
  
  obj:add_property("floating", {
    getter = function(self)
      local c = self:get_private().c_client
      return c and Some.client_get_floating(c) or false
    end,
    setter = function(self, floating)
      local c = self:get_private().c_client
      if c then
        Some.client_set_floating(c, floating)
        self:emit_signal("property::floating", floating)
      end
    end
  })
  
  obj:add_property("fullscreen", {
    getter = function(self)
      local c = self:get_private().c_client
      return c and Some.client_get_fullscreen(c) or false
    end,
    setter = function(self, fullscreen)
      local c = self:get_private().c_client
      if c then
        Some.client_set_fullscreen(c, fullscreen)
        self:emit_signal("property::fullscreen", fullscreen)
      end
    end
  })
  
  obj:add_property("tags", {
    getter = function(self)
      local c = self:get_private().c_client
      return c and Some.client_get_tags(c) or 0
    end,
    setter = function(self, tags)
      local c = self:get_private().c_client
      if c then
        Some.client_set_tags(c, tags)
        self:emit_signal("property::tags", tags)
      end
    end
  })
  
  -- Add client-specific methods
  function obj:focus()
    local c = self:get_private().c_client
    if c then
      Some.client_focus(c)
      self:emit_signal("request::activate", "client.focus")
    end
  end
  
  function obj:close()
    local c = self:get_private().c_client
    if c then
      Some.client_close(c)
      self:emit_signal("request::close")
    end
  end
  
  function obj:kill()
    local c = self:get_private().c_client
    if c then
      Some.client_kill(c)
      self:emit_signal("request::kill")
    end
  end
  
  -- Convenience methods using properties
  function obj:toggle_floating()
    self.floating = not self.floating
  end
  
  function obj:toggle_fullscreen()
    self.fullscreen = not self.fullscreen
  end
  
  function obj:move(x, y)
    local geom = self.geometry
    self.geometry = base.geometry.rectangle(x, y, geom.width, geom.height)
  end
  
  function obj:resize(w, h)
    local geom = self.geometry
    self.geometry = base.geometry.rectangle(geom.x, geom.y, w, h)
  end
  
  function obj:move_relative(dx, dy)
    local geom = self.geometry
    self:move(geom.x + dx, geom.y + dy)
  end
  
  function obj:resize_relative(dw, dh)
    local geom = self.geometry
    self:resize(geom.width + dw, geom.height + dh)
  end
  
  -- Info method for debugging
  function obj:info()
    return string.format(
      "%s (%s) [PID:%s] - %dx%d+%d+%d, tags:%d, floating:%s, fullscreen:%s",
      self.title or "Untitled",
      self.appid or "unknown", 
      self.pid or "unknown",
      self.geometry.width, self.geometry.height, self.geometry.x, self.geometry.y,
      self.tags, tostring(self.floating), tostring(self.fullscreen)
    )
  end
  
  -- Store in our weak table
  client_objects[c_client] = obj
  
  return obj
end

-- Public API functions

-- Get all clients as objects
function client.get_all()
  local c_clients = Some.client_get_all()
  local objects = {}
  
  for i, c in ipairs(c_clients) do
    objects[i] = create_client_object(c)
  end
  
  return objects
end

-- Get focused client as object
function client.get_focused()
  local c_client = Some.client_get_focused()
  return create_client_object(c_client)
end

-- Convenience functions
function client.get_all_titles()
  local clients = client.get_all()
  local titles = {}
  for i, c in ipairs(clients) do
    titles[i] = c.title or "Untitled"
  end
  return titles
end

function client.find_by_title(title)
  local clients = client.get_all()
  for _, c in ipairs(clients) do
    if c.title == title then
      return c
    end
  end
  return nil
end

function client.find_by_appid(appid)
  local clients = client.get_all()
  for _, c in ipairs(clients) do
    if c.appid == appid then
      return c
    end
  end
  return nil
end

function client.find_by_pid(pid)
  local clients = client.get_all()
  for _, c in ipairs(clients) do
    if c.pid == pid then
      return c
    end
  end
  return nil
end

-- Signal handling (delegates to global signals for now)
function client.connect_signal(signal_name, callback)
  base.signal.connect("client::" .. signal_name, callback)
end

function client.disconnect_signal(signal_name, callback)
  base.signal.disconnect("client::" .. signal_name, callback)
end

-- Convenience signal connections
function client.on_map(callback)
  client.connect_signal("map", callback)
end

function client.on_unmap(callback)
  client.connect_signal("unmap", callback)
end

function client.on_focus(callback)
  client.connect_signal("focus", callback)
end

function client.on_unfocus(callback)
  client.connect_signal("unfocus", callback)
end

function client.on_title_change(callback)
  client.connect_signal("title_change", callback)
end

function client.on_fullscreen(callback)
  client.connect_signal("fullscreen", callback)
end

function client.on_floating(callback)
  client.connect_signal("floating", callback)
end

-- Property-based signal handlers
function client.on_property_change(property, callback)
  client.connect_signal("property::" .. property, callback)
end

-- Advanced client operations using base.geometry
function client.arrange_tiled(clients, area, master_count)
  master_count = master_count or 1
  
  if #clients == 0 then return end
  
  -- Use base.geometry for layout calculations
  if #clients == 1 then
    clients[1].geometry = area
    return
  end
  
  if master_count >= #clients then
    -- All clients are masters, split horizontally
    local areas = base.geometry.split_horizontal(area, #clients)
    for i, c in ipairs(clients) do
      c.geometry = areas[i]
    end
  else
    -- Split between master and stack areas
    local master_area, stack_area = area, area
    if master_count > 0 then
      master_area = base.geometry.rectangle(area.x, area.y, area.width / 2, area.height)
      stack_area = base.geometry.rectangle(area.x + area.width / 2, area.y, area.width / 2, area.height)
      
      -- Arrange masters
      local master_areas = base.geometry.split_vertical(master_area, master_count)
      for i = 1, master_count do
        if clients[i] then
          clients[i].geometry = master_areas[i]
        end
      end
    end
    
    -- Arrange stack
    local stack_count = #clients - master_count
    if stack_count > 0 then
      local stack_areas = base.geometry.split_vertical(stack_area, stack_count)
      for i = 1, stack_count do
        if clients[master_count + i] then
          clients[master_count + i].geometry = stack_areas[i]
        end
      end
    end
  end
end

-- Cleanup function for when clients are destroyed
function client.cleanup_client(c_client)
  if client_objects[c_client] then
    local obj = client_objects[c_client]
    obj:emit_signal("destroy")
    obj:destroy()
    client_objects[c_client] = nil
  end
end

return client