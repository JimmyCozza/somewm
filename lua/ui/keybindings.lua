-- UI keybindings layer for SomeWM
-- High-level keybinding management using base.signal
-- Inspired by AwesomeWM's awful.key system

local base = require("base")

local keybindings = {}

-- Keybinding registry
keybindings.bindings = {}
keybindings.groups = {}

-- Modifier mapping
local modifier_map = {
  Mod4 = 0x40,
  logo = 0x40,
  Super = 0x40,
  Shift = 0x01,
  Control = 0x04,
  Ctrl = 0x04,
  Alt = 0x08,
  Mod1 = 0x08,
}

-- Key symbol lookup (wrapper around C function)
local function get_keysym(key)
  if type(get_keysym_native) == "function" then
    return get_keysym_native(key)
  else
    base.logger.error("get_keysym_native function not available")
    return nil
  end
end

-- Convert modifier names to bitmask
local function parse_modifiers(modifiers)
  local mods = 0
  
  if type(modifiers) == "string" then
    modifiers = {modifiers}
  end
  
  for _, mod in ipairs(modifiers or {}) do
    local flag = modifier_map[mod]
    if flag then
      mods = mods | flag
    else
      base.logger.warn("Unknown modifier: " .. tostring(mod))
    end
  end
  
  return mods
end

-- Keybinding object class
function keybindings.create_binding(config)
  local binding = base.object.new()
  
  -- Required properties
  if not config.modifiers or not config.key then
    error("Keybinding requires modifiers and key", 2)
  end
  
  -- Set properties
  binding:set_private("modifiers", config.modifiers)
  binding:set_private("key", config.key)
  binding:set_private("description", config.description or "")
  binding:set_private("group", config.group or "misc")
  binding:set_private("on_press", config.on_press)
  binding:set_private("on_release", config.on_release)
  
  -- Property accessors
  binding:add_property("modifiers", {
    getter = function(self) return self:get_private().modifiers end,
    setter = function(self, value)
      self:set_private("modifiers", value)
      self:_update_binding()
    end
  })
  
  binding:add_property("key", {
    getter = function(self) return self:get_private().key end,
    setter = function(self, value)
      self:set_private("key", value)
      self:_update_binding()
    end
  })
  
  binding:add_property("description", {
    getter = function(self) return self:get_private().description end,
    setter = function(self, value) self:set_private("description", value) end
  })
  
  binding:add_property("group", {
    getter = function(self) return self:get_private().group end,
    setter = function(self, value) self:set_private("group", value) end
  })
  
  binding:add_property("enabled", {
    getter = function(self) return self:get_private().enabled ~= false end,
    setter = function(self, value)
      local old_value = self:get_private().enabled
      self:set_private("enabled", value)
      
      if value and not old_value then
        self:enable()
      elseif not value and old_value then
        self:disable()
      end
    end
  })
  
  -- Internal methods
  function binding:_update_binding()
    if self.enabled then
      self:disable()
      self:enable()
    end
  end
  
  function binding:_register_with_compositor()
    local mods = parse_modifiers(self.modifiers)
    local keysym = get_keysym(self.key)
    
    if not keysym then
      base.logger.error("Unknown key: " .. tostring(self.key))
      return false
    end
    
    local on_press = self:get_private().on_press
    local on_release = self:get_private().on_release
    
    -- Register with compositor (wrapper around C function)
    if type(register_key_binding) == "function" then
      base.logger.debug(string.format("Registering keybinding: %s+%s", 
        table.concat(self.modifiers, "+"), self.key))
      
      register_key_binding(mods, keysym, on_press, on_release)
      return true
    else
      base.logger.error("register_key_binding function not available")
      return false
    end
  end
  
  -- Public methods
  function binding:enable()
    if self:_register_with_compositor() then
      self:set_private("enabled", true)
      self:emit_signal("enabled")
      base.logger.info(string.format("Enabled keybinding: %s+%s (%s)", 
        table.concat(self.modifiers, "+"), self.key, self.description))
      return true
    end
    return false
  end
  
  function binding:disable()
    -- TODO: Implement unregister_key_binding in C
    self:set_private("enabled", false)
    self:emit_signal("disabled")
    base.logger.info(string.format("Disabled keybinding: %s+%s", 
      table.concat(self.modifiers, "+"), self.key))
  end
  
  function binding:trigger(action)
    action = action or "press"
    
    if action == "press" and self:get_private().on_press then
      base.logger.debug(string.format("Triggering keybinding: %s+%s (press)", 
        table.concat(self.modifiers, "+"), self.key))
      
      local success, err = pcall(self:get_private().on_press)
      if not success then
        base.logger.error(string.format("Error in keybinding callback: %s", err))
      end
      
      self:emit_signal("triggered", "press")
    elseif action == "release" and self:get_private().on_release then
      base.logger.debug(string.format("Triggering keybinding: %s+%s (release)", 
        table.concat(self.modifiers, "+"), self.key))
      
      local success, err = pcall(self:get_private().on_release)
      if not success then
        base.logger.error(string.format("Error in keybinding release callback: %s", err))
      end
      
      self:emit_signal("triggered", "release")
    end
  end
  
  function binding:get_id()
    return table.concat(self.modifiers, "+") .. "+" .. self.key
  end
  
  function binding:destroy()
    self:disable()
    
    -- Remove from registry
    local id = self:get_id()
    keybindings.bindings[id] = nil
    
    -- Remove from group
    if keybindings.groups[self.group] then
      for i, binding in ipairs(keybindings.groups[self.group]) do
        if binding == self then
          table.remove(keybindings.groups[self.group], i)
          break
        end
      end
    end
    
    self:emit_signal("destroy")
    base.object.destroy(self)
  end
  
  return binding
end

-- Add a new keybinding
function keybindings.add(config)
  local binding = keybindings.create_binding(config)
  local id = binding:get_id()
  
  -- Check for conflicts
  if keybindings.bindings[id] then
    base.logger.warn(string.format("Keybinding conflict: %s already registered", id))
    keybindings.bindings[id]:destroy()
  end
  
  -- Register binding
  keybindings.bindings[id] = binding
  
  -- Add to group
  if not keybindings.groups[binding.group] then
    keybindings.groups[binding.group] = {}
  end
  table.insert(keybindings.groups[binding.group], binding)
  
  -- Enable the binding
  binding:enable()
  
  return binding
end

-- Remove a keybinding
function keybindings.remove(modifiers, key)
  local id = table.concat(modifiers, "+") .. "+" .. key
  local binding = keybindings.bindings[id]
  
  if binding then
    binding:destroy()
    return true
  end
  
  return false
end

-- Get a keybinding by modifiers and key
function keybindings.get(modifiers, key)
  local id = table.concat(modifiers, "+") .. "+" .. key
  return keybindings.bindings[id]
end

-- Get all keybindings in a group
function keybindings.get_group(group)
  return keybindings.groups[group] or {}
end

-- Get all keybinding groups
function keybindings.get_groups()
  local groups = {}
  for group, _ in pairs(keybindings.groups) do
    table.insert(groups, group)
  end
  table.sort(groups)
  return groups
end

-- Get all keybindings
function keybindings.get_all()
  local bindings = {}
  for _, binding in pairs(keybindings.bindings) do
    table.insert(bindings, binding)
  end
  return bindings
end

-- Enable/disable all keybindings
function keybindings.enable_all()
  for _, binding in pairs(keybindings.bindings) do
    binding:enable()
  end
end

function keybindings.disable_all()
  for _, binding in pairs(keybindings.bindings) do
    binding:disable()
  end
end

-- Clear all keybindings
function keybindings.clear_all()
  for _, binding in pairs(keybindings.bindings) do
    binding:destroy()
  end
  keybindings.bindings = {}
  keybindings.groups = {}
end

-- Convenience function for creating simple keybindings
function keybindings.key(modifiers, key, callback, description, group)
  return keybindings.add({
    modifiers = modifiers,
    key = key,
    on_press = callback,
    description = description or "",
    group = group or "misc"
  })
end

-- Generate help text for keybindings
function keybindings.get_help_text()
  local help = {}
  local groups = keybindings.get_groups()
  
  for _, group in ipairs(groups) do
    table.insert(help, string.format("\n=== %s ===", group:upper()))
    
    local group_bindings = keybindings.get_group(group)
    table.sort(group_bindings, function(a, b)
      return a:get_id() < b:get_id()
    end)
    
    for _, binding in ipairs(group_bindings) do
      local key_combo = table.concat(binding.modifiers, "+") .. "+" .. binding.key
      local desc = binding.description ~= "" and binding.description or "No description"
      table.insert(help, string.format("  %-20s : %s", key_combo, desc))
    end
  end
  
  return table.concat(help, "\n")
end

-- Export compatibility with awful.key
keybindings.awful_key_compat = setmetatable({}, {
  __call = function(_, args)
    return keybindings.add({
      modifiers = args.modifiers,
      key = args.key,
      on_press = args.on_press,
      on_release = args.on_release,
      description = args.description,
      group = args.group
    })
  end
})

return keybindings