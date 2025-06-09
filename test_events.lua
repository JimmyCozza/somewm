-- Test script for event system using new 3-layer architecture
local somewm = require("somewm")

somewm.foundation.logger.info("Testing client event system...")

-- Test 1: Basic event registration using new signal system
somewm.foundation.logger.info("Registering event handlers...")

-- Use the new signal system from core.client
if somewm.core.client and somewm.core.client.connect_signal then
  -- Map event - when new clients appear
  somewm.core.client.connect_signal("manage", function(c)
    local info = string.format("%s (%s)", c.title or "Untitled", c.class or "Unknown")
    somewm.foundation.logger.info("EVENT: Client managed - " .. info)
  end)

  -- Unmap event - when clients are destroyed
  somewm.core.client.connect_signal("unmanage", function(c)
    local info = string.format("%s (%s)", c.title or "Untitled", c.class or "Unknown")
    somewm.foundation.logger.info("EVENT: Client unmanaged - " .. info)
  end)

  -- Focus events
  somewm.core.client.connect_signal("focus", function(c)
    local info = string.format("%s (%s)", c.title or "Untitled", c.class or "Unknown")
    somewm.foundation.logger.info("EVENT: Client focused - " .. info)
  end)

  somewm.core.client.connect_signal("unfocus", function(c)
    local info = string.format("%s (%s)", c.title or "Untitled", c.class or "Unknown")
    somewm.foundation.logger.info("EVENT: Client unfocused - " .. info)
  end)

  -- Property change events
  somewm.core.client.connect_signal("property::title", function(c, new_title)
    local info = string.format("%s (%s)", new_title or "Untitled", c.class or "Unknown")
    somewm.foundation.logger.info("EVENT: Client title changed - " .. info)
  end)

  somewm.core.client.connect_signal("property::fullscreen", function(c, new_fullscreen)
    local state = new_fullscreen and "entered" or "exited"
    local info = string.format("%s (%s)", c.title or "Untitled", c.class or "Unknown")
    somewm.foundation.logger.info("EVENT: Client " .. state .. " fullscreen - " .. info)
  end)

  somewm.core.client.connect_signal("property::floating", function(c, new_floating)
    local state = new_floating and "became floating" or "became tiled"
    local info = string.format("%s (%s)", c.title or "Untitled", c.class or "Unknown")
    somewm.foundation.logger.info("EVENT: Client " .. state .. " - " .. info)
  end)

  somewm.foundation.logger.info("Event handlers registered successfully!")
else
  somewm.foundation.logger.warn("Core client signal system not available")
end

-- Test 2: Global signal registration
somewm.foundation.signal.connect("test_signal", function(data)
  somewm.foundation.logger.info("EVENT: Test signal received with data: " .. tostring(data))
end)

-- Emit test signal
somewm.foundation.signal.emit("test_signal", "Hello from test!")

-- Test 3: UI automation events (if available)
if somewm.ui.automation then
  -- Add a test automation rule
  somewm.ui.automation.add_rule({
    type = somewm.ui.automation.RULE_TYPES.WINDOW_SPAWN,
    conditions = {},
    callback = function(context)
      local client = context.client
      if client then
        somewm.foundation.logger.info("AUTOMATION: Processing new window - " .. (client.title or "Untitled"))
      end
    end,
    description = "Log all new windows",
    priority = 10
  })
  
  somewm.foundation.logger.info("Automation rule registered")
end

somewm.foundation.logger.info("Event system test setup complete.")
somewm.foundation.logger.info("")
somewm.foundation.logger.info("Now try:")
somewm.foundation.logger.info("  - Opening a new window (manage event)")
somewm.foundation.logger.info("  - Closing a window (unmanage event)")
somewm.foundation.logger.info("  - Switching focus between windows (focus/unfocus events)")
somewm.foundation.logger.info("  - Changing window titles (property::title event)")
somewm.foundation.logger.info("  - Toggling fullscreen with Super+f (property::fullscreen event)")
somewm.foundation.logger.info("  - Toggling floating with Super+Shift+Space (property::floating event)")
somewm.foundation.logger.info("")
somewm.foundation.logger.info("All events will be logged to see the system in action!")
somewm.foundation.logger.info("Event system uses new signal-based architecture with property change notifications")