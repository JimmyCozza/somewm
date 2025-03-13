local lgi = require("lgi")
local cairo = lgi.cairo
local drawable = require("basic_drawable")
local logger = require("logger")

local widgets = {}

-- The main widget manager
widgets.active_widgets = {}

-- Test function that doesn't rely on the C draw_widget function
function widgets.test_notification(text, timeout)
  logger.info("== Widget Test Function Called ==")
  logger.info(string.format("Creating test notification with text: '%s'", text or "Test"))
  
  -- Let's try to use lgi directly
  local surface = cairo.ImageSurface.create(cairo.Format.ARGB32, 300, 100)
  local cr = cairo.Context.create(surface)
  
  logger.debug("Created test surface and context")
  
  -- Draw background
  cr:set_source_rgba(0.2, 0.2, 0.2, 0.8)
  cr:rectangle(0, 0, 300, 100)
  cr:fill()
  
  -- Draw border
  cr:set_source_rgb(0.3, 0.6, 1)
  cr:set_line_width(2)
  cr:rectangle(1, 1, 298, 98)
  cr:stroke()
  
  -- Draw text
  cr:set_source_rgb(1, 1, 1)
  cr:select_font_face("Sans", cairo.FontSlant.NORMAL, cairo.FontWeight.BOLD)
  cr:set_font_size(16)
  
  local test_text = text or "Test Notification"
  local text_extents = cr:text_extents(test_text)
  local x = (300 - text_extents.width) / 2
  local y = (100 + text_extents.height) / 2
  
  cr:move_to(x, y)
  cr:show_text(test_text)
  
  logger.info("Test notification drawing completed")
  logger.info("== Widget Test Function Completed ==")
  
  -- We would save this to a file if we wanted to verify
  -- surface:write_to_png("test_notification.png")
  
  return true
end

-- Basic widget drawing function using Cairo
-- This will be called by the C function
function widgets.draw_simple_widget(width, height, surface_pointer, text)
  logger.debug(string.format("Drawing widget: %dx%d with text '%s'", width, height, text or ""))
  
  -- Use our notification drawer from the basic_drawable module
  if surface_pointer then
    drawable.draw_notification(width, height, surface_pointer, text)
    logger.debug("Drew on surface successfully")
  else
    logger.warn("No surface pointer provided, widget won't be displayed")
  end
  
  -- Return success
  return true
end

-- Create a notification widget
function widgets.create_notification(text, timeout)
  logger.info(string.format("Creating notification with text: '%s'", text))
  
  local widget = {
    text = text,
    timeout = timeout or 3, -- Default timeout of 3 seconds
    width = 300,
    height = 100,
    x = 50,
    y = 50
  }
  
  -- Store the widget
  table.insert(widgets.active_widgets, widget)
  logger.debug(string.format("Added widget to active_widgets, count: %d", #widgets.active_widgets))
  
  -- Show the widget
  widgets.show_widget(widget)
  
  return widget
end

-- Show a widget on screen
function widgets.show_widget(widget)
  logger.info(string.format("Showing widget at position %d,%d with size %dx%d", 
                           widget.x, widget.y, widget.width, widget.height))
  
  -- Call the C function to draw the widget
  logger.debug("Calling Some.draw_widget function")
  Some.draw_widget(
    widget.width, 
    widget.height, 
    widget.x, 
    widget.y, 
    "widgets.draw_simple_widget",
    widget.text
  )
  logger.debug("Returned from Some.draw_widget")
  
  -- Set a timer to hide the widget after timeout
  -- In a real implementation, you would set up a timer here
  logger.info(string.format("Widget will be visible for %d seconds", widget.timeout))
  
  -- For demonstration purposes, schedule hiding after timeout
  -- In a real implementation, you would use a proper timer mechanism
  -- This is just simulating the concept
  logger.debug(string.format("(In a real implementation, the widget would be hidden after %d seconds)", widget.timeout))
end

-- Hide a widget
function widgets.hide_widget(widget)
  logger.info("Hiding widget")
  
  -- Find and remove the widget
  for i, w in ipairs(widgets.active_widgets) do
    if w == widget then
      table.remove(widgets.active_widgets, i)
      logger.debug(string.format("Removed widget from active_widgets, remaining: %d", #widgets.active_widgets))
      break
    end
  end
  
  -- In a real implementation, you would remove the widget from the scene
  logger.debug("Widget hidden")
end

return widgets