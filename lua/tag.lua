-- Tag API module for SomeWM
-- Provides a high-level interface to tag/workspace management functions

local tag = {}
local monitor = require("monitor")

-- Get tag count
function tag.get_count()
  return Some.tag_get_count()
end

-- Current tag functions
function tag.get_current()
  return Some.tag_get_current()
end

function tag.set_current(tags)
  Some.tag_set_current(tags)
end

function tag.toggle_view(tags)
  Some.tag_toggle_view(tags)
end

-- Tag state functions
function tag.get_occupied()
  return Some.tag_get_occupied()
end

function tag.get_urgent()
  return Some.tag_get_urgent()
end

-- Tag manipulation for specific monitors
function tag.get_current_for_monitor(m)
  return Some.monitor_get_tags(m)
end

function tag.set_current_for_monitor(m, tags)
  Some.monitor_set_tags(m, tags)
end

-- Convenience functions
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

function tag.view_on_monitor(m, tag_number)
  if tag_number < 1 or tag_number > tag.get_count() then
    return false
  end
  
  local tag_mask = 1 << (tag_number - 1)
  tag.set_current_for_monitor(m, tag_mask)
  return true
end

-- Helper functions to work with tag bitmasks
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

-- Get tag names (default numbered tags)
function tag.get_names()
  local names = {}
  local count = tag.get_count()
  
  for i = 1, count do
    names[i] = tostring(i)
  end
  
  return names
end

-- Set custom tag names (stored in Lua, not in C)
local custom_tag_names = nil

function tag.set_names(names)
  custom_tag_names = {}
  for i, name in ipairs(names) do
    custom_tag_names[i] = name
  end
end

function tag.get_name(tag_number)
  if custom_tag_names and custom_tag_names[tag_number] then
    return custom_tag_names[tag_number]
  end
  
  return tostring(tag_number)
end

-- Check if a tag is visible/active
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

-- Get comprehensive tag status
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
      urgent = (urgent & mask) ~= 0
    }
  end
  
  return status
end

-- Helper function to get active tag numbers
function tag.get_active_list()
  return tag.mask_to_list(tag.get_current())
end

function tag.get_occupied_list()
  return tag.mask_to_list(tag.get_occupied())
end

function tag.get_urgent_list()
  return tag.mask_to_list(tag.get_urgent())
end

return tag