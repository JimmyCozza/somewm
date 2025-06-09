-- UI automation layer for SomeWM
-- Smart window behaviors and automation using foundation.signal and core APIs
-- Inspired by AwesomeWM's ruled.client and smart focus systems

local foundation = require("foundation")
local core = require("core")

local automation = {}

-- Automation rule registry
automation.rules = {}
automation.behaviors = {}
automation.enabled = true

-- Rule types
automation.RULE_TYPES = {
  WINDOW_SPAWN = "window_spawn",
  WINDOW_FOCUS = "window_focus",
  WINDOW_CLOSE = "window_close",
  WINDOW_MOVE = "window_move",
  TAG_SWITCH = "tag_switch",
  MONITOR_CHANGE = "monitor_change"
}

-- Create automation rule
function automation.create_rule(config)
  local rule = foundation.object.new()
  
  -- Required properties
  rule:set_private("type", config.type or automation.RULE_TYPES.WINDOW_SPAWN)
  rule:set_private("conditions", config.conditions or {})
  rule:set_private("actions", config.actions or {})
  rule:set_private("callback", config.callback)
  rule:set_private("priority", config.priority or 50)
  rule:set_private("enabled", config.enabled ~= false)
  rule:set_private("description", config.description or "")
  
  -- Property accessors
  rule:add_property("type", {
    getter = function(self) return self:get_private().type end,
    setter = function(self, value)
      self:set_private("type", value)
      self:_update_registration()
    end
  })
  
  rule:add_property("enabled", {
    getter = function(self) return self:get_private().enabled end,
    setter = function(self, value)
      local old_value = self:get_private().enabled
      self:set_private("enabled", value)
      
      if value ~= old_value then
        self:_update_registration()
        self:emit_signal("property::enabled", value)
      end
    end
  })
  
  rule:add_property("priority", {
    getter = function(self) return self:get_private().priority end,
    setter = function(self, value)
      self:set_private("priority", value)
      automation._sort_rules()
    end
  })
  
  -- Internal methods
  function rule:_update_registration()
    -- Re-register rule with automation system
    automation._register_rule(self)
  end
  
  function rule:_matches_conditions(context)
    local conditions = self:get_private().conditions
    
    for key, expected in pairs(conditions) do
      local actual = context[key]
      
      if type(expected) == "function" then
        if not expected(actual, context) then
          return false
        end
      elseif type(expected) == "string" then
        if type(actual) == "string" then
          if not actual:match(expected) then
            return false
          end
        else
          if actual ~= expected then
            return false
          end
        end
      elseif type(expected) == "table" then
        local found = false
        for _, value in ipairs(expected) do
          if actual == value then
            found = true
            break
          end
        end
        if not found then
          return false
        end
      else
        if actual ~= expected then
          return false
        end
      end
    end
    
    return true
  end
  
  function rule:_execute_actions(context)
    local actions = self:get_private().actions
    local callback = self:get_private().callback
    
    foundation.logger.debug(string.format("Executing automation rule: %s", 
      self:get_private().description))
    
    -- Execute predefined actions
    for action, params in pairs(actions) do
      self:_execute_action(action, params, context)
    end
    
    -- Execute custom callback
    if callback and type(callback) == "function" then
      local success, err = pcall(callback, context, self)
      if not success then
        foundation.logger.error(string.format("Error in automation callback: %s", err))
      end
    end
    
    self:emit_signal("executed", context)
  end
  
  function rule:_execute_action(action, params, context)
    local client = context.client
    
    if action == "set_tag" and client then
      if type(params) == "string" then
        client:move_to_tag(params)
      elseif type(params) == "number" then
        client:move_to_tag_index(params)
      end
      
    elseif action == "set_floating" and client then
      client.floating = params
      
    elseif action == "set_fullscreen" and client then
      client.fullscreen = params
      
    elseif action == "focus" and client then
      client:focus()
      
    elseif action == "move" and client and type(params) == "table" then
      if params.x and params.y then
        client:move(params.x, params.y)
      end
      
    elseif action == "resize" and client and type(params) == "table" then
      if params.width and params.height then
        client:resize(params.width, params.height)
      end
      
    elseif action == "close" and client then
      client:close()
      
    elseif action == "spawn" and type(params) == "string" then
      core.spawn(params)
      
    elseif action == "notify" and type(params) == "string" then
      -- This would integrate with ui.widgets
      foundation.logger.info("Automation notification: " .. params)
      
    else
      foundation.logger.warn(string.format("Unknown automation action: %s", action))
    end
  end
  
  -- Public methods
  function rule:test(context)
    return self:_matches_conditions(context)
  end
  
  function rule:execute(context)
    if not self.enabled then
      return false
    end
    
    if self:_matches_conditions(context) then
      self:_execute_actions(context)
      return true
    end
    
    return false
  end
  
  function rule:destroy()
    automation._unregister_rule(self)
    self:emit_signal("destroy")
    foundation.object.destroy(self)
  end
  
  return rule
end

-- Internal rule management
function automation._register_rule(rule)
  if not rule.enabled then
    return
  end
  
  local rule_type = rule.type
  if not automation.rules[rule_type] then
    automation.rules[rule_type] = {}
  end
  
  -- Remove existing registration
  automation._unregister_rule(rule)
  
  -- Add to rules list
  table.insert(automation.rules[rule_type], rule)
  
  -- Sort by priority
  automation._sort_rules()
end

function automation._unregister_rule(rule)
  for rule_type, rules in pairs(automation.rules) do
    for i, r in ipairs(rules) do
      if r == rule then
        table.remove(rules, i)
        break
      end
    end
  end
end

function automation._sort_rules()
  for _, rules in pairs(automation.rules) do
    table.sort(rules, function(a, b)
      return a.priority > b.priority
    end)
  end
end

function automation._execute_rules(rule_type, context)
  if not automation.enabled then
    return 0
  end
  
  local rules = automation.rules[rule_type] or {}
  local executed = 0
  
  for _, rule in ipairs(rules) do
    if rule:execute(context) then
      executed = executed + 1
    end
  end
  
  return executed
end

-- Public API for adding rules
function automation.add_rule(config)
  local rule = automation.create_rule(config)
  automation._register_rule(rule)
  
  foundation.logger.info(string.format("Added automation rule: %s (type: %s, priority: %d)", 
    rule:get_private().description, rule.type, rule.priority))
  
  return rule
end

-- Convenience functions for common rules
function automation.add_window_rule(conditions, actions, description)
  return automation.add_rule({
    type = automation.RULE_TYPES.WINDOW_SPAWN,
    conditions = conditions,
    actions = actions,
    description = description or "Window rule"
  })
end

function automation.add_focus_rule(conditions, actions, description)
  return automation.add_rule({
    type = automation.RULE_TYPES.WINDOW_FOCUS,
    conditions = conditions,
    actions = actions,
    description = description or "Focus rule"
  })
end

-- Smart behaviors
function automation.enable_smart_focus()
  automation.add_rule({
    type = automation.RULE_TYPES.WINDOW_FOCUS,
    conditions = {},
    callback = function(context)
      local client = context.client
      if client and client.urgent then
        client.urgent = false
      end
    end,
    description = "Clear urgent flag on focus",
    priority = 100
  })
end

function automation.enable_smart_placement()
  automation.add_rule({
    type = automation.RULE_TYPES.WINDOW_SPAWN,
    conditions = {
      floating = true
    },
    callback = function(context)
      local client = context.client
      if not client then return end
      
      -- Center floating windows
      local monitor = client.monitor
      if monitor then
        local mx, my = monitor.x, monitor.y
        local mw, mh = monitor.width, monitor.height
        local cw, ch = client.width, client.height
        
        local x = mx + (mw - cw) / 2
        local y = my + (mh - ch) / 2
        
        client:move(math.floor(x), math.floor(y))
      end
    end,
    description = "Center floating windows",
    priority = 75
  })
end

function automation.enable_tag_persistence()
  local last_tags = {}
  
  automation.add_rule({
    type = automation.RULE_TYPES.WINDOW_SPAWN,
    conditions = {},
    callback = function(context)
      local client = context.client
      if not client then return end
      
      local class = client.class
      if class and last_tags[class] then
        client:move_to_tag(last_tags[class])
      end
    end,
    description = "Restore last used tag for application class",
    priority = 25
  })
  
  automation.add_rule({
    type = automation.RULE_TYPES.WINDOW_CLOSE,
    conditions = {},
    callback = function(context)
      local client = context.client
      if client and client.class and client.tag then
        last_tags[client.class] = client.tag.name
      end
    end,
    description = "Remember tag for application class",
    priority = 100
  })
end

-- Connect to core events
function automation.init()
  -- Connect to client events if core.client exists
  if core.client then
    core.client.connect_signal("manage", function(client)
      automation._execute_rules(automation.RULE_TYPES.WINDOW_SPAWN, {
        client = client,
        class = client.class,
        title = client.title,
        floating = client.floating
      })
    end)
    
    core.client.connect_signal("focus", function(client)
      automation._execute_rules(automation.RULE_TYPES.WINDOW_FOCUS, {
        client = client,
        class = client.class,
        title = client.title
      })
    end)
    
    core.client.connect_signal("unmanage", function(client)
      automation._execute_rules(automation.RULE_TYPES.WINDOW_CLOSE, {
        client = client,
        class = client.class,
        title = client.title
      })
    end)
  end
  
  foundation.logger.info("Automation system initialized")
end

-- Control automation system
function automation.enable()
  automation.enabled = true
  foundation.logger.info("Automation system enabled")
end

function automation.disable()
  automation.enabled = false
  foundation.logger.info("Automation system disabled")
end

function automation.clear_all_rules()
  for _, rules in pairs(automation.rules) do
    for _, rule in ipairs(rules) do
      rule:destroy()
    end
  end
  automation.rules = {}
  foundation.logger.info("All automation rules cleared")
end

-- Get statistics
function automation.get_stats()
  local stats = {
    enabled = automation.enabled,
    total_rules = 0,
    by_type = {}
  }
  
  for rule_type, rules in pairs(automation.rules) do
    stats.by_type[rule_type] = #rules
    stats.total_rules = stats.total_rules + #rules
  end
  
  return stats
end

-- Get all rules
function automation.get_rules(rule_type)
  if rule_type then
    return automation.rules[rule_type] or {}
  else
    local all_rules = {}
    for _, rules in pairs(automation.rules) do
      for _, rule in ipairs(rules) do
        table.insert(all_rules, rule)
      end
    end
    return all_rules
  end
end

return automation