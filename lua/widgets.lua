local lgi = require("lgi")
local cairo = lgi.cairo
local drawable = require("basic_drawable")
local logger = require("logger")
local wayland_surface = require("wayland_surface")

local widgets = {}

widgets.active_widgets = {}

function widgets.test_notification(text, timeout)
  logger.info("== Widget Test Function Called ==")
  logger.info(string.format("Creating test notification with text: '%s'", text or "Test"))

  -- Test LGI directly
  logger.debug("Testing LGI drawing capability")

  local ok, err = pcall(function()
    local surface = cairo.ImageSurface.create(cairo.Format.ARGB32, 300, 100)
    local cr = cairo.Context.create(surface)

    logger.debug("Created test surface and context")

    cr:set_source_rgba(0.2, 0.2, 0.2, 0.8)
    cr:rectangle(0, 0, 300, 100)
    cr:fill()

    cr:set_source_rgb(0.3, 0.6, 1)
    cr:set_line_width(2)
    cr:rectangle(1, 1, 298, 98)
    cr:stroke()

    cr:set_source_rgb(1, 1, 1)
    cr:select_font_face("Sans", cairo.FontSlant.NORMAL, cairo.FontWeight.BOLD)
    cr:set_font_size(16)

    local test_text = text or "Test Notification"
    local text_extents = cr:text_extents(test_text)
    local x = (300 - text_extents.width) / 2
    local y = (100 + text_extents.height) / 2

    cr:move_to(x, y)
    cr:show_text(test_text)
  end)

  if ok then
    logger.info("LGI drawing test completed successfully")
  else
    logger.error("LGI drawing test failed: " .. tostring(err))
  end

  logger.debug("Now trying Wayland surface method")
  local test_text = text or "Test Notification"
  local result = wayland_surface.create_widget_surface(300, 100, 100, 100, test_text)
  if result then
    logger.info("Wayland surface created successfully")
  else
    logger.error("Failed to create Wayland surface")

    logger.debug("Trying to create notification through our API as a last resort")
    local widget = widgets.create_notification(test_text, timeout or 5)
    if widget then
      logger.info("Created notification widget successfully as a fallback")
      result = widget
    else
      logger.error("All notification methods failed")
    end
  end

  logger.info("== Widget Test Function Completed ==")
  return result
end

function widgets.draw_simple_widget(width, height, cairo_context, text)
  logger.debug(string.format("Drawing widget: %dx%d with text '%s'", width, height, text or ""))

  if cairo_context then
    local ok, err = pcall(function()
      drawable.draw_notification(width, height, cairo_context, text)
    end)

    if ok then
      logger.debug("Drew on Cairo context successfully")
    else
      logger.error("Error drawing on Cairo context: " .. tostring(err))
      return false
    end
  else
    logger.warn("No Cairo context provided, widget won't be displayed")
    return false
  end

  return true
end

function widgets.create_notification(text, timeout)
  logger.info(string.format("Creating notification with text: '%s'", text))

  local width = 300
  local height = 100
  local x = 50 -- TODO: Get actual screen dimensions to calculate better positioning
  local y = 50

  logger.debug("Calling Some.create_widget function")
  Some.create_widget(text, timeout or 5)

  local widget_ptr = {}
  widget_ptr.text = text
  widget_ptr.timeout = timeout or 5
  widget_ptr.width = width
  widget_ptr.height = height
  widget_ptr.x = x
  widget_ptr.y = y

  table.insert(widgets.active_widgets, widget_ptr)
  logger.debug(string.format("Added widget to active_widgets, count: %d", #widgets.active_widgets))

  logger.debug("Widget created successfully, drawing content...")

  logger.debug("Attempting to create Wayland surface directly")
  local surface_created = wayland_surface.create_widget_surface(
    widget_ptr.width,
    widget_ptr.height,
    widget_ptr.x,
    widget_ptr.y,
    widget_ptr.text
  )

  if surface_created then
    logger.info("Widget displayed using Wayland surface")
  else
    logger.warn("Could not create wayland surface for widget")
  end

  widget_ptr.created_at = os.time()

  logger.info(string.format("Widget will be visible for %d seconds", widget_ptr.timeout))
  logger.debug(
    string.format("(In a real implementation, the widget would be hidden after %d seconds)", widget_ptr.timeout)
  )

  return widget_ptr
end

-- Show a widget on screen (legacy function)
function widgets.show_widget(widget)
  logger.warn("widgets.show_widget is deprecated, use create_notification instead")

  if type(widget) == "userdata" then
    logger.info("Received widget pointer, already visible")
    return true
  elseif type(widget) == "table" and widget.text then
    logger.info("Converting legacy widget to new API")
    return widgets.create_notification(widget.text, widget.timeout)
  else
    logger.error("Invalid widget passed to show_widget")
    return false
  end
end

function widgets.hide_widget(widget)
  logger.info("Hiding widget")

  if type(widget) == "table" then
    for i, w in ipairs(widgets.active_widgets) do
      if w == widget then
        table.remove(widgets.active_widgets, i)
        logger.debug(string.format("Removed widget from active_widgets, remaining: %d", #widgets.active_widgets))
        break
      end
    end

    Some.destroy_widget()
    logger.debug("Widget destroyed")
    return true
  elseif type(widget) == "table" and widget.surface_id then
    wayland_surface.destroy_widget_surface(widget.surface_id)
    widget.surface_id = nil

    for i, w in ipairs(widgets.active_widgets) do
      if w == widget then
        table.remove(widgets.active_widgets, i)
        logger.debug(string.format("Removed widget from active_widgets, remaining: %d", #widgets.active_widgets))
        break
      end
    end

    logger.debug("Legacy widget hidden")
    return true
  else
    logger.error("Invalid widget passed to hide_widget")
    return false
  end
end

return widgets
