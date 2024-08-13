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

return {
  draw_surface = draw_surface,
}
