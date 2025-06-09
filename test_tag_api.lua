-- Test Tag API (Phase 4 - READ)
-- Tests all tag data access functionality

local somewm = require("somewm")
local tag = somewm.core.tag
local logger = somewm.base.logger

logger.info("=== Tag API Test (Phase 4 - READ) ===")

-- Test basic tag information
local tag_count = tag.get_count()
logger.info("Tag count: " .. tag_count)

local current_tags = tag.get_current()
logger.info("Current tags (bitmask): " .. current_tags)

local occupied_tags = tag.get_occupied()
logger.info("Occupied tags (bitmask): " .. occupied_tags)

local urgent_tags = tag.get_urgent()
logger.info("Urgent tags (bitmask): " .. urgent_tags)

-- Test tag mask conversion functions
logger.info("--- Tag Mask Conversions ---")
local active_list = tag.get_active_list()
logger.info("Active tags list: [" .. table.concat(active_list, ", ") .. "]")

local occupied_list = tag.get_occupied_list()
logger.info("Occupied tags list: [" .. table.concat(occupied_list, ", ") .. "]")

local urgent_list = tag.get_urgent_list()
logger.info("Urgent tags list: [" .. table.concat(urgent_list, ", ") .. "]")

-- Test individual tag status
logger.info("--- Individual Tag Status ---")
for i = 1, tag_count do
  local active = tag.is_active(i)
  local occupied = tag.is_occupied(i)
  local urgent = tag.is_urgent(i)
  logger.info("Tag " .. i .. ": active=" .. tostring(active) .. 
              ", occupied=" .. tostring(occupied) .. ", urgent=" .. tostring(urgent))
end

-- Test tag names
logger.info("--- Tag Names ---")
local names = tag.get_names()
logger.info("Default tag names: [" .. table.concat(names, ", ") .. "]")

-- Test custom tag names
tag.set_names({"web", "term", "code", "media", "misc"})
logger.info("Custom tag names set")
for i = 1, tag_count do
  logger.info("Tag " .. i .. " name: " .. tag.get_name(i))
end

-- Test comprehensive status
logger.info("--- Comprehensive Tag Status ---")
local status = tag.get_status()
for _, tag_info in ipairs(status) do
  logger.info("Tag " .. tag_info.number .. " (" .. tag_info.name .. "): " ..
              "active=" .. tostring(tag_info.active) .. 
              ", occupied=" .. tostring(tag_info.occupied) .. 
              ", urgent=" .. tostring(tag_info.urgent))
end

-- Test mask conversion round-trip
logger.info("--- Mask Conversion Round-Trip Test ---")
local test_list = {1, 3, 5}
local test_mask = tag.list_to_mask(test_list)
local result_list = tag.mask_to_list(test_mask)
logger.info("Original list: [" .. table.concat(test_list, ", ") .. "]")
logger.info("Converted to mask: " .. test_mask)
logger.info("Converted back to list: [" .. table.concat(result_list, ", ") .. "]")

-- Test monitor-specific tag functions
local monitor = somewm.core.monitor
local monitors = monitor.get_all()
if #monitors > 0 then
  logger.info("--- Monitor-Specific Tag Functions ---")
  for i, m in ipairs(monitors) do
    local monitor_tags = tag.get_current_for_monitor(m)
    logger.info("Monitor " .. i .. " (" .. (monitor.get_name(m) or "Unknown") .. ") tags: " .. monitor_tags)
  end
end

logger.info("=== Tag API Test Complete ===")