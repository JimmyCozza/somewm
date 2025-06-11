-- Base object system for SomeWM
-- Based on AwesomeWM's gears.object with signals and property management

local object = {}

-- Weak table to store object metadata
local objects_data = setmetatable({}, { __mode = "k" })

-- Create a new object with signal support
function object.new()
  local obj = {}
  
  -- Initialize object metadata
  objects_data[obj] = {
    signals = {},
    properties = {},
    private = {}
  }
  
  -- Set metatable for property access
  setmetatable(obj, {
    __index = function(self, key)
      local data = objects_data[self]
      if not data then return nil end
      
      -- Check for getter function
      if data.properties[key] and data.properties[key].getter then
        return data.properties[key].getter(self)
      end
      
      -- Check for private storage
      if data.private[key] ~= nil then
        return data.private[key]
      end
      
      -- Check for object methods
      return object[key]
    end,
    
    __newindex = function(self, key, value)
      local data = objects_data[self]
      if not data then return end
      
      -- Check for setter function
      if data.properties[key] and data.properties[key].setter then
        data.properties[key].setter(self, value)
        return
      end
      
      -- Store in private data
      local old_value = data.private[key]
      data.private[key] = value
      
      -- Emit property change signal
      if old_value ~= value then
        self:emit_signal("property::" .. key, value, old_value)
      end
    end
  })
  
  return obj
end

-- Connect a signal to a callback
function object:connect_signal(signal_name, callback)
  if type(callback) ~= "function" then
    error("Callback must be a function", 2)
  end
  
  local data = objects_data[self]
  if not data then
    error("Object not properly initialized", 2)
  end
  
  if not data.signals[signal_name] then
    data.signals[signal_name] = {}
  end
  
  table.insert(data.signals[signal_name], callback)
end

-- Disconnect a signal callback
function object:disconnect_signal(signal_name, callback)
  local data = objects_data[self]
  if not data or not data.signals[signal_name] then
    return
  end
  
  for i, cb in ipairs(data.signals[signal_name]) do
    if cb == callback then
      table.remove(data.signals[signal_name], i)
      break
    end
  end
end

-- Emit a signal to all connected callbacks
function object:emit_signal(signal_name, ...)
  local data = objects_data[self]
  if not data or not data.signals[signal_name] then
    return
  end
  
  -- Call all connected callbacks
  for _, callback in ipairs(data.signals[signal_name]) do
    local success, err = pcall(callback, self, ...)
    if not success then
      print("Error in signal callback for " .. signal_name .. ": " .. tostring(err))
    end
  end
end

-- Add a property with optional getter/setter
function object:add_property(name, config)
  config = config or {}
  
  local data = objects_data[self]
  if not data then
    error("Object not properly initialized", 2)
  end
  
  data.properties[name] = {
    getter = config.getter,
    setter = config.setter
  }
end

-- Get private data for an object
function object:get_private()
  local data = objects_data[self]
  return data and data.private or {}
end

-- Set private data for an object
function object:set_private(key, value)
  local data = objects_data[self]
  if data then
    data.private[key] = value
  end
end

-- Check if object has a signal connected
function object:has_signal(signal_name)
  local data = objects_data[self]
  return data and data.signals[signal_name] and #data.signals[signal_name] > 0
end

-- Get all connected signals
function object:get_signals()
  local data = objects_data[self]
  if not data then return {} end
  
  local signals = {}
  for name, callbacks in pairs(data.signals) do
    signals[name] = #callbacks
  end
  return signals
end

-- Cleanup object data (useful for garbage collection)
function object:destroy()
  local data = objects_data[self]
  if data then
    -- Clear all signals
    for signal_name, _ in pairs(data.signals) do
      data.signals[signal_name] = {}
    end
    -- Remove from weak table
    objects_data[self] = nil
  end
  
  self:emit_signal("destroy")
end

return object