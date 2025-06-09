-- UI widgets layer for SomeWM
-- High-level widget creation and management using base.object
-- Inspired by AwesomeWM's wibox system

local base = require("base")
local lgi = require("lgi")
local cairo = lgi.cairo
local drawable = require("basic_drawable")
local wayland_surface = require("wayland_surface")

local widgets = {}

-- Active widgets registry
widgets.active_widgets = {}

-- Widget base class using base.object
function widgets.create_widget_base()
  local widget = base.object.new()
  
  -- Widget properties
  widget:add_property("width", {
    getter = function(self)
      return self:get_private().width or 100
    end,
    setter = function(self, value)
      self:set_private("width", value)
      self:emit_signal("property::width", value)
      self:_update_geometry()
    end
  })
  
  widget:add_property("height", {
    getter = function(self)
      return self:get_private().height or 50
    end,
    setter = function(self, value)
      self:set_private("height", value)
      self:emit_signal("property::height", value)
      self:_update_geometry()
    end
  })
  
  widget:add_property("x", {
    getter = function(self)
      return self:get_private().x or 0
    end,
    setter = function(self, value)
      self:set_private("x", value)
      self:emit_signal("property::x", value)
      self:_update_geometry()
    end
  })
  
  widget:add_property("y", {
    getter = function(self)
      return self:get_private().y or 0
    end,
    setter = function(self, value)
      self:set_private("y", value)
      self:emit_signal("property::y", value)
      self:_update_geometry()
    end
  })
  
  widget:add_property("visible", {
    getter = function(self)
      return self:get_private().visible ~= false
    end,
    setter = function(self, value)
      local old_value = self:get_private().visible
      self:set_private("visible", value)
      self:emit_signal("property::visible", value)
      
      if value and not old_value then
        self:show()
      elseif not value and old_value then
        self:hide()
      end
    end
  })
  
  widget:add_property("text", {
    getter = function(self)
      return self:get_private().text or ""
    end,
    setter = function(self, value)
      self:set_private("text", value)
      self:emit_signal("property::text", value)
      self:_update_content()
    end
  })
  
  -- Internal methods
  function widget:_update_geometry()
    self:emit_signal("geometry_changed")
    if self.visible then
      self:_redraw()
    end
  end
  
  function widget:_update_content()
    self:emit_signal("content_changed")
    if self.visible then
      self:_redraw()
    end
  end
  
  function widget:_redraw()
    -- Override in subclasses
    self:emit_signal("redraw")
  end
  
  -- Public methods
  function widget:show()
    if not self.visible then
      self.visible = true
    end
    self:emit_signal("show")
  end
  
  function widget:hide()
    if self.visible then
      self.visible = false
    end
    self:emit_signal("hide")
  end
  
  function widget:destroy()
    self:hide()
    
    -- Remove from active widgets
    for i, w in ipairs(widgets.active_widgets) do
      if w == self then
        table.remove(widgets.active_widgets, i)
        break
      end
    end
    
    self:emit_signal("destroy")
    base.object.destroy(self)
  end
  
  return widget
end

-- Notification widget class
function widgets.create_notification(text, timeout, config)
  config = config or {}
  
  local notification = widgets.create_widget_base()
  
  -- Set notification properties
  notification.width = config.width or 300
  notification.height = config.height or 100
  notification.x = config.x or 50
  notification.y = config.y or 50
  notification.text = text or ""
  notification:set_private("timeout", timeout or 5)
  notification:set_private("surface_id", nil)
  
  -- Override redraw for notification-specific rendering
  function notification:_redraw()
    if not self.visible then
      return
    end
    
    base.logger.debug(string.format("Drawing notification: %dx%d at (%d,%d) with text '%s'", 
      self.width, self.height, self.x, self.y, self.text))
    
    -- Create Wayland surface
    local surface_created = wayland_surface.create_widget_surface(
      self.width, self.height, self.x, self.y, self.text
    )
    
    if surface_created then
      base.logger.info("Notification displayed using Wayland surface")
      self:set_private("surface_id", surface_created)
    else
      base.logger.warn("Could not create Wayland surface for notification")
    end
  end
  
  function notification:hide()
    if self:get_private().surface_id then
      wayland_surface.destroy_widget_surface(self:get_private().surface_id)
      self:set_private("surface_id", nil)
    end
    
    -- Call parent hide
    widgets.create_widget_base().hide(self)
  end
  
  -- Auto-hide after timeout
  if notification:get_private().timeout > 0 then
    -- In a real implementation, this would use base.timer
    -- For now, we'll use a simple approach
    notification:set_private("created_at", os.time())
  end
  
  -- Add to active widgets registry
  table.insert(widgets.active_widgets, notification)
  
  -- Show the notification
  notification:show()
  
  base.logger.info(string.format("Created notification with text: '%s', timeout: %d", 
    text, notification:get_private().timeout))
  
  return notification
end

-- Test widget functionality
function widgets.test_notification(text, timeout)
  base.logger.info("== Widget Test Function Called ==")
  base.logger.info(string.format("Creating test notification with text: '%s'", text or "Test"))
  
  -- Test LGI directly first
  base.logger.debug("Testing LGI drawing capability")
  
  local ok, err = pcall(function()
    local surface = cairo.ImageSurface.create(cairo.Format.ARGB32, 300, 100)
    local cr = cairo.Context.create(surface)
    
    base.logger.debug("Created test surface and context")
    
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
    base.logger.info("LGI drawing test completed successfully")
  else
    base.logger.error("LGI drawing test failed: " .. tostring(err))
  end
  
  -- Create notification using new API
  local notification = widgets.create_notification(text or "Test Notification", timeout or 5)
  
  base.logger.info("== Widget Test Function Completed ==")
  return notification
end

-- Draw simple widget using Cairo (for backward compatibility)
function widgets.draw_simple_widget(width, height, cairo_context, text)
  base.logger.debug(string.format("Drawing widget: %dx%d with text '%s'", width, height, text or ""))
  
  if cairo_context then
    local ok, err = pcall(function()
      drawable.draw_notification(width, height, cairo_context, text)
    end)
    
    if ok then
      base.logger.debug("Drew on Cairo context successfully")
    else
      base.logger.error("Error drawing on Cairo context: " .. tostring(err))
      return false
    end
  else
    base.logger.warn("No Cairo context provided, widget won't be displayed")
    return false
  end
  
  return true
end

-- Legacy compatibility functions
function widgets.show_widget(widget)
  base.logger.warn("widgets.show_widget is deprecated, use widget:show() instead")
  
  if type(widget) == "table" and widget.show then
    widget:show()
    return true
  elseif type(widget) == "table" and widget.text then
    base.logger.info("Converting legacy widget to new API")
    return widgets.create_notification(widget.text, widget.timeout)
  else
    base.logger.error("Invalid widget passed to show_widget")
    return false
  end
end

function widgets.hide_widget(widget)
  base.logger.warn("widgets.hide_widget is deprecated, use widget:hide() instead")
  
  if type(widget) == "table" and widget.hide then
    widget:hide()
    return true
  else
    base.logger.error("Invalid widget passed to hide_widget")
    return false
  end
end

-- Get all active widgets
function widgets.get_active_widgets()
  return widgets.active_widgets
end

-- Clear all widgets
function widgets.clear_all()
  for _, widget in ipairs(widgets.active_widgets) do
    if widget.destroy then
      widget:destroy()
    end
  end
  widgets.active_widgets = {}
end

-- Wibar (window bar) widget class
function widgets.create_wibar(config)
  config = config or {}
  
  local wibar = widgets.create_widget_base()
  
  -- Set wibar properties with defaults
  wibar.width = config.width or 1920  -- Full screen width by default
  wibar.height = config.height or 30
  wibar.x = config.x or 0
  wibar.y = config.y or 0
  wibar.layer = config.layer or "top"
  wibar.anchor = config.anchor or "top"
  wibar.exclusive = config.exclusive ~= false  -- Default to true
  wibar:set_private("surface_id", nil)
  wibar:set_private("background_color", config.background_color or {0.2, 0.2, 0.2, 0.9})
  wibar:set_private("border_color", config.border_color or {0.3, 0.6, 1.0, 1.0})
  wibar:set_private("border_width", config.border_width or 1)
  
  -- Wibar-specific properties
  wibar:add_property("layer", {
    getter = function(self)
      return self:get_private().layer or "top"
    end,
    setter = function(self, value)
      self:set_private("layer", value)
      self:emit_signal("property::layer", value)
      if self.visible then
        self:_redraw()
      end
    end
  })
  
  wibar:add_property("anchor", {
    getter = function(self)
      return self:get_private().anchor or "top"
    end,
    setter = function(self, value)
      self:set_private("anchor", value)
      self:emit_signal("property::anchor", value)
      if self.visible then
        self:_redraw()
      end
    end
  })
  
  wibar:add_property("exclusive", {
    getter = function(self)
      return self:get_private().exclusive ~= false
    end,
    setter = function(self, value)
      self:set_private("exclusive", value)
      self:emit_signal("property::exclusive", value)
      if self.visible then
        self:_redraw()
      end
    end
  })
  
  -- Override redraw for wibar-specific rendering
  function wibar:_redraw()
    if not self.visible then
      return
    end
    
    -- Destroy existing surface if any
    if self:get_private().surface_id then
      Some.destroy_layer_surface(self:get_private().surface_id)
      self:set_private("surface_id", nil)
    end
    
    base.logger.debug(string.format("Drawing wibar: %dx%d at (%d,%d), layer=%s, exclusive=%s", 
      self.width, self.height, self.x, self.y, self.layer, tostring(self.exclusive)))
    
    -- Calculate exclusive zone (height if exclusive, 0 if not)
    local exclusive_zone = self.exclusive and self.height or 0
    
    -- Create layer surface
    local layer_surface = Some.create_layer_surface(
      self.width, self.height, self.x, self.y, 
      self.layer, exclusive_zone, self.anchor
    )
    
    if layer_surface then
      base.logger.info("Wibar layer surface created successfully")
      self:set_private("surface_id", layer_surface)
      
      -- TODO: Add Cairo drawing here to render wibar content
      self:_draw_content()
    else
      base.logger.warn("Could not create layer surface for wibar")
    end
  end
  
  function wibar:_draw_content()
    -- This would be where we draw the actual wibar content using Cairo
    -- For now, we'll just log that we would draw here
    local bg_color = self:get_private().background_color
    local border_color = self:get_private().border_color
    local border_width = self:get_private().border_width
    
    base.logger.debug(string.format("Drawing wibar content with bg_color=[%.1f,%.1f,%.1f,%.1f], border_width=%d",
      bg_color[1], bg_color[2], bg_color[3], bg_color[4], border_width))
    
    -- In a full implementation, this would:
    -- 1. Get the Cairo context from the layer surface
    -- 2. Draw background with bg_color
    -- 3. Draw border with border_color and border_width
    -- 4. Draw any child widgets/text content
  end
  
  function wibar:hide()
    if self:get_private().surface_id then
      Some.destroy_layer_surface(self:get_private().surface_id)
      self:set_private("surface_id", nil)
    end
    
    -- Call parent hide
    widgets.create_widget_base().hide(self)
  end
  
  -- Add to active widgets registry
  table.insert(widgets.active_widgets, wibar)
  
  base.logger.info(string.format("Created wibar: %dx%d at (%d,%d), layer=%s, exclusive=%s", 
    wibar.width, wibar.height, wibar.x, wibar.y, wibar.layer, tostring(wibar.exclusive)))
  
  return wibar
end

-- Create a default top wibar
function widgets.create_top_wibar(config)
  config = config or {}
  config.anchor = "top"
  config.y = 0
  config.exclusive = config.exclusive ~= false  -- Default to exclusive
  return widgets.create_wibar(config)
end

-- Create a bottom wibar  
function widgets.create_bottom_wibar(config)
  config = config or {}
  config.anchor = "bottom"
  config.exclusive = config.exclusive ~= false  -- Default to exclusive
  return widgets.create_wibar(config)
end

-- Test wibar functionality
function widgets.test_wibar()
  base.logger.info("== Wibar Test Function Called ==")
  
  -- Create a test top wibar
  local wibar = widgets.create_top_wibar({
    width = 1920,
    height = 30,
    background_color = {0.15, 0.15, 0.15, 0.95},
    border_color = {0.4, 0.7, 1.0, 1.0},
    border_width = 2
  })
  
  wibar:show()
  
  base.logger.info("== Wibar Test Function Completed ==")
  return wibar
end

return widgets