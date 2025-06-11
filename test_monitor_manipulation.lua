-- Test Monitor Management (Phase 4 - WRITE)
-- Tests monitor manipulation functionality

local somewm = require("somewm")
local monitor = somewm.core.monitor
local logger = somewm.base.logger

logger.info("=== Monitor Management Test (Phase 4 - WRITE) ===")

local monitors = monitor.get_all()
if #monitors == 0 then
  logger.info("No monitors found, skipping manipulation tests")
  return
end

local focused = monitor.get_focused()
if not focused then
  logger.info("No focused monitor, using first monitor")
  focused = monitors[1]
end

logger.info("Testing on monitor: " .. (monitor.get_name(focused) or "Unknown"))

-- Store original values
local original_factor = monitor.get_master_factor(focused)
local original_count = monitor.get_master_count(focused)
local original_tags = monitor.get_tags(focused)

logger.info("Original state:")
logger.info("  Master Factor: " .. original_factor)
logger.info("  Master Count: " .. original_count)
logger.info("  Tags: " .. original_tags)

-- Test master factor manipulation
logger.info("--- Testing Master Factor ---")
monitor.set_master_factor(focused, 0.7)
logger.info("Set master factor to 0.7, current: " .. monitor.get_master_factor(focused))

monitor.set_master_factor(focused, 0.4)
logger.info("Set master factor to 0.4, current: " .. monitor.get_master_factor(focused))

-- Test master count manipulation
logger.info("--- Testing Master Count ---")
monitor.set_master_count(focused, 2)
logger.info("Set master count to 2, current: " .. monitor.get_master_count(focused))

monitor.set_master_count(focused, 1)
logger.info("Set master count to 1, current: " .. monitor.get_master_count(focused))

-- Test tag manipulation
logger.info("--- Testing Tag Management ---")
monitor.set_tags(focused, 1)  -- First tag only
logger.info("Set to tag 1, current: " .. monitor.get_tags(focused))

monitor.set_tags(focused, 3)  -- First and second tags (binary 11 = 3)
logger.info("Set to tags 1+2, current: " .. monitor.get_tags(focused))

-- Test monitor focus switching (if multiple monitors)
if #monitors > 1 then
  logger.info("--- Testing Monitor Focus ---")
  for i, m in ipairs(monitors) do
    if m ~= focused then
      logger.info("Switching focus to monitor " .. i .. ": " .. (monitor.get_name(m) or "Unknown"))
      monitor.focus(m)
      local new_focused = monitor.get_focused()
      logger.info("Focus switched: " .. (new_focused == m and "success" or "failed"))
      break
    end
  end
  
  -- Switch back to original
  monitor.focus(focused)
  logger.info("Switched back to original monitor")
end

-- Restore original values
logger.info("--- Restoring Original State ---")
monitor.set_master_factor(focused, original_factor)
monitor.set_master_count(focused, original_count)
monitor.set_tags(focused, original_tags)

logger.info("Final state:")
logger.info("  Master Factor: " .. monitor.get_master_factor(focused))
logger.info("  Master Count: " .. monitor.get_master_count(focused))
logger.info("  Tags: " .. monitor.get_tags(focused))

logger.info("=== Monitor Management Test Complete ===")