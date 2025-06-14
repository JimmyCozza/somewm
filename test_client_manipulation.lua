-- Test script for client manipulation using new 3-layer architecture
local somewm = require("somewm")

somewm.base.logger.info("Testing client manipulation API...")

-- Get focused client for testing
local focused = somewm.get_focused_client()
if not focused then
  somewm.base.logger.info("No focused client - please focus a window first")
  return
end

local client_info = string.format("%s (%s)", focused.title or "Untitled", focused.class or "Unknown")
somewm.base.logger.info("Testing with focused client: " .. client_info)

-- Test 1: Get original state
local original_x, original_y = focused.x, focused.y
local original_width, original_height = focused.width, focused.height
local original_floating = focused.floating
local original_fullscreen = focused.fullscreen

somewm.base.logger.info("Original state:")
somewm.base.logger.info("  Geometry: " .. original_x .. "," .. original_y .. " " .. original_width .. "x" .. original_height)
somewm.base.logger.info("  Floating: " .. tostring(original_floating))
somewm.base.logger.info("  Fullscreen: " .. tostring(original_fullscreen))

-- Test 2: Toggle floating using property access
somewm.base.logger.info("Testing floating toggle...")
focused.floating = not focused.floating
somewm.base.logger.info("After toggle floating: " .. tostring(focused.floating))

-- Wait a moment and toggle back
os.execute("sleep 1")
focused.floating = original_floating
somewm.base.logger.info("After toggle back: " .. tostring(focused.floating))

-- Test 3: Move window using method
somewm.base.logger.info("Testing move...")
if focused.move then
  focused:move(original_x + 50, original_y + 50)
  somewm.base.logger.info("After move: " .. focused.x .. "," .. focused.y)
  
  -- Move back
  os.execute("sleep 1")
  focused:move(original_x, original_y)
  somewm.base.logger.info("Moved back to original position")
else
  somewm.base.logger.warn("Move method not available")
end

-- Test 4: Resize window using method
somewm.base.logger.info("Testing resize...")
if focused.resize then
  focused:resize(original_width + 100, original_height + 50)
  somewm.base.logger.info("After resize: " .. focused.width .. "x" .. focused.height)
  
  -- Resize back
  os.execute("sleep 1")
  focused:resize(original_width, original_height)
  somewm.base.logger.info("Resized back to original size")
else
  somewm.base.logger.warn("Resize method not available")
end

-- Test 5: Test fullscreen toggle
somewm.base.logger.info("Testing fullscreen toggle...")
focused.fullscreen = not focused.fullscreen
somewm.base.logger.info("After fullscreen toggle: " .. tostring(focused.fullscreen))

os.execute("sleep 1")
focused.fullscreen = original_fullscreen
somewm.base.logger.info("Restored original fullscreen state")

-- Test 6: Focus test
somewm.base.logger.info("Testing focus function...")
if focused.focus then
  focused:focus()
  somewm.base.logger.info("Focus function completed")
else
  somewm.base.logger.warn("Focus method not available")
end

somewm.base.logger.info("Property-based manipulation tests completed!")

-- Test 7: Test with multiple clients
local all_clients = somewm.get_clients()
if #all_clients > 1 then
  somewm.base.logger.info("Testing with multiple clients...")
  for i, c in ipairs(all_clients) do
    if c ~= focused then
      somewm.base.logger.info("Focusing client " .. i .. ": " .. (c.title or "Untitled"))
      if c.focus then
        c:focus()
      end
      break
    end
  end
  
  -- Focus back to original
  os.execute("sleep 1")
  if focused.focus then
    focused:focus()
  end
  somewm.base.logger.info("Focused back to original client")
else
  somewm.base.logger.info("Only one client available - skipping multi-client test")
end

-- Test 8: Property change notifications
somewm.base.logger.info("Testing property change notifications...")
if focused.connect_signal then
  focused:connect_signal("property::title", function(c, new_title)
    somewm.base.logger.info("Title changed to: " .. (new_title or "None"))
  end)
  
  focused:connect_signal("property::floating", function(c, new_floating)
    somewm.base.logger.info("Floating changed to: " .. tostring(new_floating))
  end)
  
  somewm.base.logger.info("Property change listeners registered")
else
  somewm.base.logger.warn("Signal system not available")
end

somewm.base.logger.info("Client manipulation API test complete!")
somewm.base.logger.info("New API uses property access (client.floating = true) and method calls (client:move(x, y))")