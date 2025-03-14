local lgi = require("lgi")
local cairo = lgi.cairo

function draw_surface(width, height, cairo_surface_pointer)
  print("[DEBUG] draw_surface called with dimensions: " .. width .. "x" .. height)
  local surface = nil
  
  -- Safety check
  if not cairo_surface_pointer then
    print("[ERROR] No cairo surface pointer provided to draw_surface")
    return false
  end
  
  -- Wrap the cairo surface pointer with error handling
  local ok, err = pcall(function()
    surface = cairo.Surface.wrap_pointer(cairo_surface_pointer)
  end)
  
  if not ok then
    print("[ERROR] Failed to wrap cairo surface pointer: " .. tostring(err))
    return false
  end
  
  if not surface then
    print("[ERROR] Failed to create cairo surface")
    return false
  end
  
  local cr = cairo.Context.create(surface)

  print("[DEBUG] Drawing to cairo surface")
  cr:set_source_rgb(1, 1, 1)
  cr:paint()

  cr:set_source_rgb(0, 0, 1)
  cr:rectangle(50, 50, width - 100, height - 100)
  cr:fill()

  cr:set_source_rgb(0, 0, 0)
  cr:select_font_face("Sans", cairo.FontSlant.NORMAL, cairo.FontWeight.BOLD)
  cr:set_font_size(24)
  cr:move_to(100, 100)
  cr:show_text("Hello, SomeWM!")
  
  print("[DEBUG] Drawing completed successfully")
  return true
end

-- Draw a simple notification widget
function draw_notification(width, height, cairo_context, text)
  local logger = require("logger")
  logger.debug("draw_notification called - size: " .. width .. "x" .. height .. ", text: " .. (text or "<nil>"))
  
  -- Safety check
  if not cairo_context then
    logger.error("No cairo context provided to draw_notification")
    return false
  end
  
  -- Wrap the cairo context pointer with error handling
  local cr = nil
  local ok, err = pcall(function()
    cr = cairo.Context.wrap(cairo_context)
  end)
  
  if not ok then
    logger.error("Failed to wrap cairo context: " .. tostring(err))
    return false
  end
  
  if not cr then
    logger.error("Failed to create cairo context")
    return false
  end

  logger.debug("Starting to draw notification with Cairo")

  -- Draw background with rounded corners
  cr:save()
  local radius = 10
  
  -- Path for rounded rectangle
  cr:new_sub_path()
  cr:arc(width - radius, radius, radius, -math.pi/2, 0)
  cr:arc(width - radius, height - radius, radius, 0, math.pi/2)
  cr:arc(radius, height - radius, radius, math.pi/2, math.pi)
  cr:arc(radius, radius, radius, math.pi, 3*math.pi/2)
  cr:close_path()
  
  -- Fill with semi-transparent background
  cr:set_source_rgba(0.2, 0.2, 0.2, 0.9) -- Semi-transparent dark background
  cr:fill_preserve()
  
  -- Draw border
  cr:set_source_rgb(0.3, 0.6, 1) -- Blue border
  cr:set_line_width(2)

  cr:stroke()
  cr:restore()

  -- Add a subtle gradient overlay
  local pattern = cairo.LinearGradient.create(0, 0, 0, height)
  pattern:add_color_stop_rgba(0, 1, 1, 1, 0.05) -- Top: slightly lighter
  pattern:add_color_stop_rgba(1, 0, 0, 0, 0.05) -- Bottom: slightly darker
  
  cr:save()
  cr:rectangle(0, 0, width, height)
  cr:set_source(pattern)
  cr:fill()
  cr:restore()

  -- Draw text
  cr:set_source_rgb(1, 1, 1)
  cr:select_font_face("Sans", cairo.FontSlant.NORMAL, cairo.FontWeight.BOLD)
  cr:set_font_size(16)
  
  -- Center the text
  local text_to_display = text or "Notification"
  local text_extents = cr:text_extents(text_to_display)
  local x = (width - text_extents.width) / 2
  local y = (height + text_extents.height) / 2
  
  -- Add text shadow for better readability
  cr:save()
  cr:set_source_rgba(0, 0, 0, 0.5)
  cr:move_to(x + 1, y + 1)
  cr:show_text(text_to_display)
  cr:restore()
  
  -- Draw the main text
  cr:set_source_rgb(1, 1, 1)
  cr:move_to(x, y)
  cr:show_text(text_to_display)

  -- Add a small indicator in the bottom right
  local time_text = os.date("%H:%M")
  cr:set_font_size(10)
  local time_extents = cr:text_extents(time_text)
  cr:set_source_rgba(0.8, 0.8, 0.8, 0.7)
  cr:move_to(width - time_extents.width - 10, height - 10)
  cr:show_text(time_text)

  -- Log completion
  logger.debug("Notification drawing completed successfully")
  return true
end

return {
  draw_surface = draw_surface,
  draw_notification = draw_notification,
}
