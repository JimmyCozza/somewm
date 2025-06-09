-- Core rules system for SomeWM
-- Based on AwesomeWM's ruled.client for declarative window automation

local base = require("base")

local rules = {}

-- Rules storage
local rule_list = {}
local rule_id_counter = 0

-- Rule matching engine
local function match_rule(rule, client)
  if not rule.rule then return false end
  
  -- Check each rule condition
  for property, expected in pairs(rule.rule) do
    local actual
    
    -- Get the actual property value from client
    if property == "class" or property == "appid" then
      actual = client.appid
    elseif property == "title" then
      actual = client.title
    elseif property == "floating" then
      actual = client.floating
    elseif property == "fullscreen" then
      actual = client.fullscreen
    elseif property == "pid" then
      actual = client.pid
    elseif property == "tags" then
      actual = client.tags
    else
      -- Custom property or geometry check
      if property == "geometry" then
        actual = client.geometry
      else
        -- Try to get custom property
        actual = client:get_private()[property]
      end
    end
    
    -- Match against expected value
    if type(expected) == "string" then
      -- String matching (supports patterns)
      if type(actual) ~= "string" or not string.match(actual, expected) then
        return false
      end
    elseif type(expected) == "number" then
      if actual ~= expected then
        return false
      end
    elseif type(expected) == "boolean" then
      if actual ~= expected then
        return false
      end
    elseif type(expected) == "function" then
      -- Function-based matching
      if not expected(actual, client) then
        return false
      end
    elseif type(expected) == "table" then
      if property == "geometry" then
        -- Geometry matching
        for geo_prop, geo_val in pairs(expected) do
          if actual[geo_prop] ~= geo_val then
            return false
          end
        end
      else
        -- Table-based matching (e.g., list contains value)
        local found = false
        for _, val in ipairs(expected) do
          if actual == val then
            found = true
            break
          end
        end
        if not found then
          return false
        end
      end
    else
      -- Direct comparison
      if actual ~= expected then
        return false
      end
    end
  end
  
  return true
end

-- Apply rule properties to client
local function apply_rule_properties(rule, client)
  if not rule.properties then return end
  
  base.logger.debug("Applying rule properties to client: " .. (client.title or "unknown"))
  
  for property, value in pairs(rule.properties) do
    if type(value) == "function" then
      -- Function-based property assignment
      local result = value(client)
      if result ~= nil then
        if property == "geometry" then
          client.geometry = result
        else
          client[property] = result
        end
      end
    else
      -- Direct property assignment
      if property == "floating" then
        client.floating = value
      elseif property == "fullscreen" then
        client.fullscreen = value
      elseif property == "tags" then
        client.tags = value
      elseif property == "geometry" then
        if type(value) == "table" then
          client.geometry = value
        end
      else
        -- Custom property
        client:set_private(property, value)
      end
    end
  end
end

-- Apply rule signals to client
local function apply_rule_signals(rule, client)
  if not rule.signals then return end
  
  base.logger.debug("Connecting rule signals for client: " .. (client.title or "unknown"))
  
  for signal_name, callback in pairs(rule.signals) do
    client:connect_signal(signal_name, callback)
  end
end

-- Apply rule callbacks
local function apply_rule_callbacks(rule, client)
  if rule.callback and type(rule.callback) == "function" then
    base.logger.debug("Executing rule callback for client: " .. (client.title or "unknown"))
    
    local success, err = pcall(rule.callback, client)
    if not success then
      base.logger.error("Rule callback error: " .. tostring(err))
    end
  end
end

-- Main rule application function
local function apply_rules_to_client(client)
  base.logger.debug("Applying rules to client: " .. (client.title or "unknown"))
  
  for _, rule in ipairs(rule_list) do
    if rule.enabled ~= false and match_rule(rule, client) then
      base.logger.debug("Rule matched: " .. (rule.description or "unnamed rule"))
      
      -- Apply in order: properties, signals, callbacks
      apply_rule_properties(rule, client)
      apply_rule_signals(rule, client)
      apply_rule_callbacks(rule, client)
      
      -- Check if this rule should stop further processing
      if rule.stop_processing then
        base.logger.debug("Rule processing stopped by rule: " .. (rule.description or "unnamed rule"))
        break
      end
    end
  end
end

-- Public API

-- Add a new rule
function rules.add(rule)
  if not rule or not rule.rule then
    error("Rule must have a 'rule' table with matching conditions", 2)
  end
  
  rule_id_counter = rule_id_counter + 1
  rule.id = rule.id or rule_id_counter
  rule.enabled = rule.enabled ~= false  -- Default to enabled
  
  table.insert(rule_list, rule)
  
  base.logger.info("Added rule: " .. (rule.description or "rule #" .. rule.id))
  base.signal.emit("rules::rule_added", rule)
  
  return rule.id
end

-- Remove a rule by ID
function rules.remove(rule_id)
  for i, rule in ipairs(rule_list) do
    if rule.id == rule_id then
      table.remove(rule_list, i)
      base.logger.info("Removed rule: " .. (rule.description or "rule #" .. rule_id))
      base.signal.emit("rules::rule_removed", rule_id)
      return true
    end
  end
  return false
end

-- Enable/disable a rule
function rules.enable(rule_id)
  for _, rule in ipairs(rule_list) do
    if rule.id == rule_id then
      rule.enabled = true
      base.signal.emit("rules::rule_enabled", rule_id)
      return true
    end
  end
  return false
end

function rules.disable(rule_id)
  for _, rule in ipairs(rule_list) do
    if rule.id == rule_id then
      rule.enabled = false
      base.signal.emit("rules::rule_disabled", rule_id)
      return true
    end
  end
  return false
end

-- Get all rules
function rules.get_all()
  return rule_list
end

-- Get rule by ID
function rules.get(rule_id)
  for _, rule in ipairs(rule_list) do
    if rule.id == rule_id then
      return rule
    end
  end
  return nil
end

-- Clear all rules
function rules.clear()
  rule_list = {}
  base.logger.info("All rules cleared")
  base.signal.emit("rules::all_cleared")
end

-- Apply rules to a specific client
function rules.apply_to_client(client)
  apply_rules_to_client(client)
end

-- Apply rules to all existing clients
function rules.apply_to_all_clients()
  local core_client = require("core.client")
  local clients = core_client.get_all()
  
  for _, client in ipairs(clients) do
    apply_rules_to_client(client)
  end
  
  base.logger.info("Applied rules to " .. #clients .. " clients")
end

-- Rule validation
function rules.validate_rule(rule)
  if not rule then
    return false, "Rule cannot be nil"
  end
  
  if not rule.rule or type(rule.rule) ~= "table" then
    return false, "Rule must have a 'rule' table with matching conditions"
  end
  
  if rule.properties and type(rule.properties) ~= "table" then
    return false, "Rule properties must be a table"
  end
  
  if rule.signals and type(rule.signals) ~= "table" then
    return false, "Rule signals must be a table"
  end
  
  if rule.callback and type(rule.callback) ~= "function" then
    return false, "Rule callback must be a function"
  end
  
  return true, "Rule is valid"
end

-- Debugging functions
function rules.debug_client_match(client)
  base.logger.debug("Testing rules against client: " .. (client.title or "unknown"))
  
  local matches = {}
  for _, rule in ipairs(rule_list) do
    if rule.enabled ~= false and match_rule(rule, client) then
      table.insert(matches, {
        id = rule.id,
        description = rule.description or "unnamed rule"
      })
    end
  end
  
  return matches
end

function rules.get_stats()
  local stats = {
    total_rules = #rule_list,
    enabled_rules = 0,
    disabled_rules = 0
  }
  
  for _, rule in ipairs(rule_list) do
    if rule.enabled ~= false then
      stats.enabled_rules = stats.enabled_rules + 1
    else
      stats.disabled_rules = stats.disabled_rules + 1
    end
  end
  
  return stats
end

-- Built-in rule templates
rules.templates = {
  -- Float specific applications
  floating = function(classes)
    return {
      rule = { class = table.concat(classes, "|") },
      properties = { floating = true },
      description = "Float applications: " .. table.concat(classes, ", ")
    }
  end,
  
  -- Assign applications to specific tags
  tag_assignment = function(class, tag_number)
    return {
      rule = { class = class },
      properties = { tags = 1 << (tag_number - 1) },
      description = "Assign " .. class .. " to tag " .. tag_number
    }
  end,
  
  -- Maximize specific applications
  maximize = function(classes)
    return {
      rule = { class = table.concat(classes, "|") },
      properties = { fullscreen = true },
      description = "Maximize applications: " .. table.concat(classes, ", ")
    }
  end,
  
  -- Smart geometry placement
  smart_placement = function(class, area_function)
    return {
      rule = { class = class },
      properties = { 
        geometry = area_function,
        floating = true 
      },
      description = "Smart placement for " .. class
    }
  end
}

-- Connect to client events for automatic rule application
base.signal.connect("client::map", function(client)
  apply_rules_to_client(client)
end)

-- Signal handling
function rules.connect_signal(signal_name, callback)
  base.signal.connect("rules::" .. signal_name, callback)
end

function rules.disconnect_signal(signal_name, callback)
  base.signal.disconnect("rules::" .. signal_name, callback)
end

return rules