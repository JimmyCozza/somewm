-- Test Monitor API (Phase 4 - READ)
-- Tests all monitor data access functionality

local somewm = require("somewm")
local monitor = somewm.core.monitor
local logger = somewm.foundation.logger

logger.info("=== Monitor API Test (Phase 4 - READ) ===")

-- Test monitor enumeration
local monitors = monitor.get_all()
logger.info("Found " .. #monitors .. " monitor(s)")

-- Test focused monitor
local focused = monitor.get_focused()
if focused then
  logger.info("Focused monitor: " .. (monitor.get_name(focused) or "Unknown"))
else
  logger.info("No focused monitor")
end

-- Test monitor properties for each monitor
for i, m in ipairs(monitors) do
  logger.info("--- Monitor " .. i .. " ---")
  logger.info("  Name: " .. (monitor.get_name(m) or "Unknown"))
  
  local geo = monitor.get_geometry(m)
  if geo then
    logger.info("  Geometry: " .. geo.x .. "x" .. geo.y .. " " .. geo.width .. "x" .. geo.height)
  end
  
  local workarea = monitor.get_workarea(m)
  if workarea then
    logger.info("  Work Area: " .. workarea.x .. "x" .. workarea.y .. " " .. workarea.width .. "x" .. workarea.height)
  end
  
  logger.info("  Layout: " .. (monitor.get_layout_symbol(m) or "Unknown"))
  logger.info("  Master Factor: " .. monitor.get_master_factor(m))
  logger.info("  Master Count: " .. monitor.get_master_count(m))
  logger.info("  Tags: " .. monitor.get_tags(m))
  logger.info("  Enabled: " .. tostring(monitor.is_enabled(m)))
end

-- Test convenience functions
logger.info("--- Convenience Functions ---")
local primary = monitor.get_primary()
if primary then
  logger.info("Primary monitor: " .. (monitor.get_name(primary) or "Unknown"))
end

-- Test find by name
if #monitors > 0 then
  local first_name = monitor.get_name(monitors[1])
  if first_name then
    local found = monitor.find_by_name(first_name)
    logger.info("Find by name '" .. first_name .. "': " .. (found and "found" or "not found"))
  end
end

-- Test monitor info function
logger.info("--- Monitor Info Test ---")
if #monitors > 0 then
  local info = monitor.info(monitors[1])
  if info then
    -- Get keys from info table
    local keys = {}
    for k, _ in pairs(info) do
      table.insert(keys, k)
    end
    logger.info("Monitor info keys: " .. table.concat(keys, ", "))
  end
end

logger.info("=== Monitor API Test Complete ===")