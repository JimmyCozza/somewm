-- Test script for Phase 3: Event System
local logger = require("logger")
local client = require("client")

logger.info("Testing client event system...")

-- Test 1: Basic event registration
logger.info("Registering event handlers...")

-- Map event - when new clients appear
client.on_map(function(c, data)
  logger.info("EVENT: Client mapped - " .. client.info(c))
end)

-- Unmap event - when clients are destroyed
client.on_unmap(function(c, data)
  logger.info("EVENT: Client unmapped - " .. client.info(c))
end)

-- Focus events
client.on_focus(function(c, data)
  logger.info("EVENT: Client focused - " .. client.info(c))
end)

client.on_unfocus(function(c, data)
  logger.info("EVENT: Client unfocused - " .. client.info(c))
end)

-- Title change event
client.on_title_change(function(c, data)
  logger.info("EVENT: Client title changed - " .. client.info(c))
end)

-- Fullscreen event
client.on_fullscreen(function(c, data)
  local state = client.is_fullscreen(c) and "entered" or "exited"
  logger.info("EVENT: Client " .. state .. " fullscreen - " .. client.info(c))
end)

-- Floating event
client.on_floating(function(c, data)
  local state = client.is_floating(c) and "became floating" or "became tiled"
  logger.info("EVENT: Client " .. state .. " - " .. client.info(c))
end)

logger.info("Event handlers registered successfully!")
logger.info("Event system test setup complete.")
logger.info("")
logger.info("Now try:")
logger.info("  - Opening a new window (map event)")
logger.info("  - Closing a window (unmap event)")
logger.info("  - Switching focus between windows (focus/unfocus events)")
logger.info("  - Changing window titles (title_change event)")
logger.info("  - Toggling fullscreen with Super+f (fullscreen event)")
logger.info("  - Toggling floating with Super+Shift+Space (floating event)")
logger.info("")
logger.info("All events will be logged to see the system in action!")