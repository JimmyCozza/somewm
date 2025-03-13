local lgi = require("lgi")
local cairo = lgi.cairo
local drawable = require("basic_drawable")

local widgets = {}

-- The main widget manager
widgets.active_widgets = {}

-- Basic widget drawing function using Cairo
-- This will be called by the C function
function widgets.draw_simple_widget(width, height, surface_pointer, text)
  print("Lua: Drawing a simple widget " .. width .. "x" .. height)
  
  -- Use our notification drawer from the basic_drawable module
  if surface_pointer then
    drawable.draw_notification(width, height, surface_pointer, text)
  else
    print("Warning: No surface pointer provided, widget won't be displayed")
  end
  
  -- Return success
  return true
end

-- Create a notification widget
function widgets.create_notification(text, timeout)
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
  
  -- Show the widget
  widgets.show_widget(widget)
  
  return widget
end

-- Show a widget on screen
function widgets.show_widget(widget)
  -- Call the C function to draw the widget
  Some.draw_widget(
    widget.width, 
    widget.height, 
    widget.x, 
    widget.y, 
    "widgets.draw_simple_widget",
    widget.text
  )
  
  -- Set a timer to hide the widget after timeout
  -- In a real implementation, you would set up a timer here
  print("Widget will be visible for " .. widget.timeout .. " seconds")
  
  -- For demonstration purposes, schedule hiding after timeout
  -- In a real implementation, you would use a proper timer mechanism
  -- This is just simulating the concept
  print("(In a real implementation, the widget would be hidden after " .. widget.timeout .. " seconds)")
end

-- Hide a widget
function widgets.hide_widget(widget)
  -- Find and remove the widget
  for i, w in ipairs(widgets.active_widgets) do
    if w == widget then
      table.remove(widgets.active_widgets, i)
      break
    end
  end
  
  -- In a real implementation, you would remove the widget from the scene
  print("Hiding widget")
end

return widgets
