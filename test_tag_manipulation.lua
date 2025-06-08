-- Test Tag Management (Phase 4 - WRITE)
-- Tests tag manipulation functionality

local tag = require("tag")
local logger = require("logger")

logger.info("=== Tag Management Test (Phase 4 - WRITE) ===")

-- Store original state
local original_tags = tag.get_current()
logger.info("Original tags (bitmask): " .. original_tags)
logger.info("Original active tags: [" .. table.concat(tag.get_active_list(), ", ") .. "]")

-- Test individual tag viewing
logger.info("--- Testing Individual Tag Viewing ---")
for i = 1, math.min(3, tag.get_count()) do
  logger.info("Switching to tag " .. i)
  local success = tag.view(i)
  if success then
    local current = tag.get_current()
    local active_list = tag.get_active_list()
    logger.info("  Success! Current tags: " .. current .. " [" .. table.concat(active_list, ", ") .. "]")
  else
    logger.info("  Failed to switch to tag " .. i)
  end
  
  -- Small delay to see the change
  os.execute("sleep 0.5")
end

-- Test tag toggling
logger.info("--- Testing Tag Toggling ---")
tag.view(1)  -- Start with tag 1
logger.info("Starting with tag 1: [" .. table.concat(tag.get_active_list(), ", ") .. "]")

tag.toggle(2)  -- Add tag 2
logger.info("Toggled tag 2: [" .. table.concat(tag.get_active_list(), ", ") .. "]")

tag.toggle(3)  -- Add tag 3
logger.info("Toggled tag 3: [" .. table.concat(tag.get_active_list(), ", ") .. "]")

tag.toggle(2)  -- Remove tag 2
logger.info("Toggled tag 2 again: [" .. table.concat(tag.get_active_list(), ", ") .. "]")

-- Test direct mask manipulation
logger.info("--- Testing Direct Mask Manipulation ---")
local test_mask = tag.list_to_mask({1, 4})
logger.info("Setting tags 1 and 4 (mask " .. test_mask .. ")")
tag.set_current(test_mask)
logger.info("Current tags: [" .. table.concat(tag.get_active_list(), ", ") .. "]")

-- Test toggle view with mask
logger.info("--- Testing Toggle View with Mask ---")
local toggle_mask = tag.list_to_mask({2, 3})
logger.info("Toggling tags 2 and 3 (mask " .. toggle_mask .. ")")
tag.toggle_view(toggle_mask)
logger.info("After toggle: [" .. table.concat(tag.get_active_list(), ", ") .. "]")

-- Test monitor-specific tag manipulation (if multiple monitors)
local monitor = require("monitor")
local monitors = monitor.get_all()
if #monitors > 1 then
  logger.info("--- Testing Monitor-Specific Tag Management ---")
  for i, m in ipairs(monitors) do
    local monitor_name = monitor.get_name(m) or ("Monitor " .. i)
    local original_monitor_tags = tag.get_current_for_monitor(m)
    
    logger.info("Monitor " .. monitor_name .. " original tags: " .. original_monitor_tags)
    
    -- Set different tags on each monitor
    local new_tags = i  -- Monitor 1 gets tag 1, monitor 2 gets tag 2, etc.
    logger.info("Setting monitor " .. monitor_name .. " to tag " .. new_tags)
    tag.set_current_for_monitor(m, new_tags)
    
    local current_monitor_tags = tag.get_current_for_monitor(m)
    logger.info("Monitor " .. monitor_name .. " new tags: " .. current_monitor_tags)
    
    -- Test view on specific monitor
    if i == 1 then
      logger.info("Testing view_on_monitor for " .. monitor_name)
      tag.view_on_monitor(m, 3)
      local after_view = tag.get_current_for_monitor(m)
      logger.info("After view_on_monitor(3): " .. after_view)
    end
  end
end

-- Test error handling
logger.info("--- Testing Error Handling ---")
local invalid_result1 = tag.view(0)  -- Invalid tag number
logger.info("view(0) result: " .. tostring(invalid_result1))

local invalid_result2 = tag.view(tag.get_count() + 1)  -- Out of range
logger.info("view(" .. (tag.get_count() + 1) .. ") result: " .. tostring(invalid_result2))

local invalid_result3 = tag.toggle(0)  -- Invalid tag number
logger.info("toggle(0) result: " .. tostring(invalid_result3))

-- Restore original state
logger.info("--- Restoring Original State ---")
tag.set_current(original_tags)
logger.info("Restored tags: [" .. table.concat(tag.get_active_list(), ", ") .. "]")

-- If we modified monitor tags, restore those too
if #monitors > 1 then
  logger.info("Restoring monitor-specific tags...")
  for i, m in ipairs(monitors) do
    tag.set_current_for_monitor(m, original_tags)
  end
end

logger.info("Final verification - current tags: [" .. table.concat(tag.get_active_list(), ", ") .. "]")
logger.info("=== Tag Management Test Complete ===")