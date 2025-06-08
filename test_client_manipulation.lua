-- Test script for Phase 2: Client Manipulation API
local logger = require("logger")
local client = require("client")

logger.info("Testing client manipulation API...")

-- Get focused client for testing
local focused = client.get_focused()
if not focused then
  logger.info("No focused client - please focus a window first")
  return
end

logger.info("Testing with focused client: " .. client.info(focused))

-- Test 1: Get original state
local original_geometry = client.get_geometry(focused)
local original_floating = client.is_floating(focused)
local original_fullscreen = client.is_fullscreen(focused)
local original_tags = client.get_tags(focused)

logger.info("Original state:")
logger.info("  Geometry: " .. original_geometry.x .. "," .. original_geometry.y .. " " .. original_geometry.width .. "x" .. original_geometry.height)
logger.info("  Floating: " .. tostring(original_floating))
logger.info("  Fullscreen: " .. tostring(original_fullscreen))
logger.info("  Tags: " .. original_tags)

-- Test 2: Toggle floating
logger.info("Testing floating toggle...")
client.toggle_floating(focused)
logger.info("After toggle floating: " .. tostring(client.is_floating(focused)))

-- Wait a moment and toggle back
os.execute("sleep 1")
client.toggle_floating(focused)
logger.info("After toggle back: " .. tostring(client.is_floating(focused)))

-- Test 3: Move window
logger.info("Testing move...")
client.move(focused, original_geometry.x + 50, original_geometry.y + 50)
local new_geometry = client.get_geometry(focused)
logger.info("After move: " .. new_geometry.x .. "," .. new_geometry.y)

-- Move back
os.execute("sleep 1")
client.move(focused, original_geometry.x, original_geometry.y)
logger.info("Moved back to original position")

-- Test 4: Resize window
logger.info("Testing resize...")
client.resize(focused, original_geometry.width + 100, original_geometry.height + 50)
new_geometry = client.get_geometry(focused)
logger.info("After resize: " .. new_geometry.width .. "x" .. new_geometry.height)

-- Resize back
os.execute("sleep 1")
client.resize(focused, original_geometry.width, original_geometry.height)
logger.info("Resized back to original size")

-- Test 5: Relative movements
logger.info("Testing relative move...")
client.move_relative(focused, 25, 25)
new_geometry = client.get_geometry(focused)
logger.info("After relative move: " .. new_geometry.x .. "," .. new_geometry.y)

client.move_relative(focused, -25, -25)
logger.info("Moved back with relative move")

-- Test 6: Test tag manipulation (be careful with this one)
logger.info("Testing tag manipulation...")
local new_tags = original_tags
if new_tags == 1 then
  new_tags = 2  -- Move to tag 2
else
  new_tags = 1  -- Move to tag 1
end

logger.info("Moving to tags: " .. new_tags)
client.set_tags(focused, new_tags)

-- Move back to original tags
os.execute("sleep 1")
client.set_tags(focused, original_tags)
logger.info("Moved back to original tags: " .. original_tags)

-- Test 7: Focus test (focus self - should be no-op but test the function)
logger.info("Testing focus function...")
client.focus(focused)
logger.info("Focus function completed")

logger.info("All manipulation tests completed successfully!")

-- Test 8: Test with multiple clients
local all_clients = client.get_all()
if #all_clients > 1 then
  logger.info("Testing with multiple clients...")
  for i, c in ipairs(all_clients) do
    if c ~= focused then
      logger.info("Focusing client " .. i .. ": " .. (client.get_title(c) or "Untitled"))
      client.focus(c)
      break
    end
  end
  
  -- Focus back to original
  os.execute("sleep 1")
  client.focus(focused)
  logger.info("Focused back to original client")
else
  logger.info("Only one client available - skipping multi-client test")
end

logger.info("Client manipulation API test complete!")