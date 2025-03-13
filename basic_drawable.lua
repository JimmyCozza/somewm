local lgi = require("lgi")
local cairo = lgi.cairo

function draw_surface(width, height, cairo_surface_pointer)
  local surface = cairo.Surface.wrap_pointer(cairo_surface_pointer)
  local cr = cairo.Context.create(surface)

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
end

-- Draw a simple notification widget
function draw_notification(width, height, cairo_surface_pointer, text)
  local surface = cairo.Surface.wrap_pointer(cairo_surface_pointer)
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
  local text_extents = cr:text_extents(text or "Notification")
  local x = (width - text_extents.width) / 2
  local y = (height + text_extents.height) / 2
  
  cr:move_to(x, y)
  cr:show_text(text or "Notification")

  -- Clean up
  cr:surface():finish()
end

return {
  draw_surface = draw_surface,
  draw_notification = draw_notification,
}
