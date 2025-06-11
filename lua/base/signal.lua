-- Base signal system for SomeWM
-- Global signal handling for cross-module communication

local signal = {}

-- Global signal registry
local signals = {}

-- Connect a callback to a global signal
function signal.connect(signal_name, callback)
  if type(signal_name) ~= "string" then
    error("Signal name must be a string", 2)
  end
  
  if type(callback) ~= "function" then
    error("Callback must be a function", 2)
  end
  
  if not signals[signal_name] then
    signals[signal_name] = {}
  end
  
  table.insert(signals[signal_name], callback)
end

-- Disconnect a callback from a global signal
function signal.disconnect(signal_name, callback)
  if not signals[signal_name] then
    return false
  end
  
  for i, cb in ipairs(signals[signal_name]) do
    if cb == callback then
      table.remove(signals[signal_name], i)
      return true
    end
  end
  
  return false
end

-- Disconnect all callbacks from a signal
function signal.disconnect_all(signal_name)
  if signals[signal_name] then
    signals[signal_name] = {}
    return true
  end
  return false
end

-- Emit a global signal
function signal.emit(signal_name, ...)
  if not signals[signal_name] then
    return 0
  end
  
  local count = 0
  for _, callback in ipairs(signals[signal_name]) do
    local success, err = pcall(callback, ...)
    if success then
      count = count + 1
    else
      print("Error in global signal callback for " .. signal_name .. ": " .. tostring(err))
    end
  end
  
  return count
end

-- Check if a signal has any connected callbacks
function signal.has_callbacks(signal_name)
  return signals[signal_name] and #signals[signal_name] > 0
end

-- Get the number of callbacks connected to a signal
function signal.count_callbacks(signal_name)
  return signals[signal_name] and #signals[signal_name] or 0
end

-- Get all registered signal names
function signal.get_signal_names()
  local names = {}
  for name, _ in pairs(signals) do
    table.insert(names, name)
  end
  table.sort(names)
  return names
end

-- Get signal statistics for debugging
function signal.get_stats()
  local stats = {}
  for name, callbacks in pairs(signals) do
    stats[name] = #callbacks
  end
  return stats
end

-- Clear all signals (useful for testing)
function signal.clear_all()
  signals = {}
end

-- Create a signal emitter object (for convenience)
function signal.create_emitter()
  local emitter = {}
  local emitter_signals = {}
  
  function emitter:connect_signal(signal_name, callback)
    if not emitter_signals[signal_name] then
      emitter_signals[signal_name] = {}
    end
    table.insert(emitter_signals[signal_name], callback)
  end
  
  function emitter:disconnect_signal(signal_name, callback)
    if not emitter_signals[signal_name] then
      return false
    end
    
    for i, cb in ipairs(emitter_signals[signal_name]) do
      if cb == callback then
        table.remove(emitter_signals[signal_name], i)
        return true
      end
    end
    return false
  end
  
  function emitter:emit_signal(signal_name, ...)
    if not emitter_signals[signal_name] then
      return 0
    end
    
    local count = 0
    for _, callback in ipairs(emitter_signals[signal_name]) do
      local success, err = pcall(callback, self, ...)
      if success then
        count = count + 1
      else
        print("Error in emitter signal callback for " .. signal_name .. ": " .. tostring(err))
      end
    end
    return count
  end
  
  function emitter:has_signal(signal_name)
    return emitter_signals[signal_name] and #emitter_signals[signal_name] > 0
  end
  
  return emitter
end

-- Create a signal connection that automatically disconnects
function signal.connect_once(signal_name, callback)
  local wrapper
  wrapper = function(...)
    signal.disconnect(signal_name, wrapper)
    callback(...)
  end
  
  signal.connect(signal_name, wrapper)
  return wrapper
end

-- Create a debounced signal connection
function signal.connect_debounced(signal_name, callback, delay)
  delay = delay or 0.1
  local timer = nil
  
  local wrapper = function(...)
    local args = {...}
    
    -- Cancel existing timer
    if timer then
      -- Note: This would need integration with the timer system
      -- For now, we'll implement a simple version
      timer = nil
    end
    
    -- Create new timer (simplified - real implementation would use timer system)
    timer = function()
      callback(table.unpack(args))
    end
    
    -- In a real implementation, this would use base.timer
    -- For now, we'll call it immediately
    timer()
  end
  
  signal.connect(signal_name, wrapper)
  return wrapper
end

-- Signal middleware system
local middleware = {}

function signal.add_middleware(func)
  table.insert(middleware, func)
end

function signal.remove_middleware(func)
  for i, mw in ipairs(middleware) do
    if mw == func then
      table.remove(middleware, i)
      return true
    end
  end
  return false
end

-- Enhanced emit with middleware support
local original_emit = signal.emit
function signal.emit(signal_name, ...)
  local args = {...}
  
  -- Apply middleware
  for _, mw in ipairs(middleware) do
    local success, result = pcall(mw, signal_name, args)
    if success and result == false then
      -- Middleware canceled the signal
      return 0
    end
  end
  
  return original_emit(signal_name, table.unpack(args))
end

return signal