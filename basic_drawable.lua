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
function draw_notification(width, height, cairo_surface_pointer, text)
  print("[DEBUG] draw_notification called - size: " .. width .. "x" .. height .. ", text: " .. (text or "<nil>"))
  
  -- Safety check
  if not cairo_surface_pointer then
    print("[ERROR] No cairo surface pointer provided to draw_notification")
    return false
  end
  
  -- Wrap the cairo surface pointer with error handling
  local surface = nil
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

  print("[DEBUG] Creating context and starting to draw notification")
  local cr = cairo.Context.create(surface)

  -- Draw background
  cr:set_source_rgba(0.2, 0.2, 0.2, 0.8) -- Semi-transparent dark background
  cr:rectangle(0, 0, width, height)
  cr:fill()

  -- Draw border
  cr:set_source_rgb(0.3, 0.6, 1) -- Blue border
  cr:set_line_width(2)
  cr:rectangle(1, 1, width - 2, height - 2)
  cr:stroke()

  -- Draw text
  cr:set_source_rgb(1, 1, 1)
  cr:select_font_face("Sans", cairo.FontSlant.NORMAL, cairo.FontWeight.BOLD)
  cr:set_font_size(16)
  
  -- Center the text
  local text_to_display = text or "Notification"
  local text_extents = cr:text_extents(text_to_display)
  local x = (width - text_extents.width) / 2
  local y = (height + text_extents.height) / 2
  
  print("[DEBUG] Drawing text: '" .. text_to_display .. "' at position " .. x .. "," .. y)
  cr:move_to(x, y)
  cr:show_text(text_to_display)

  -- Clean up
  cr:surface():finish()
  print("[DEBUG] Notification drawing completed successfully")
  return true
end

return {
  draw_surface = draw_surface,
  draw_notification = draw_notification,
}
