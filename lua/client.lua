-- Client API module for SomeWM
-- Provides a high-level interface to the client management functions

local client = {}

-- Get all clients
function client.get_all()
  return Some.client_get_all()
end

-- Get focused client
function client.get_focused()
  return Some.client_get_focused()
end

-- Client property getters
function client.get_title(c)
  return Some.client_get_title(c)
end

function client.get_appid(c)
  return Some.client_get_appid(c)
end

function client.get_geometry(c)
  return Some.client_get_geometry(c)
end

function client.get_tags(c)
  return Some.client_get_tags(c)
end

function client.is_floating(c)
  return Some.client_get_floating(c)
end

function client.is_fullscreen(c)
  return Some.client_get_fullscreen(c)
end

function client.get_pid(c)
  return Some.client_get_pid(c)
end

-- Client manipulation functions
function client.focus(c)
  Some.client_focus(c)
end

function client.close(c)
  Some.client_close(c)
end

function client.kill(c)
  Some.client_kill(c)
end

function client.set_floating(c, floating)
  Some.client_set_floating(c, floating)
end

function client.set_fullscreen(c, fullscreen)
  Some.client_set_fullscreen(c, fullscreen)
end

function client.set_geometry(c, x, y, w, h)
  Some.client_set_geometry(c, x, y, w, h)
end

function client.set_tags(c, tags)
  Some.client_set_tags(c, tags)
end

-- Convenience manipulation functions
function client.toggle_floating(c)
  client.set_floating(c, not client.is_floating(c))
end

function client.toggle_fullscreen(c)
  client.set_fullscreen(c, not client.is_fullscreen(c))
end

function client.move(c, x, y)
  local geom = client.get_geometry(c)
  client.set_geometry(c, x, y, geom.width, geom.height)
end

function client.resize(c, w, h)
  local geom = client.get_geometry(c)
  client.set_geometry(c, geom.x, geom.y, w, h)
end

function client.move_relative(c, dx, dy)
  local geom = client.get_geometry(c)
  client.set_geometry(c, geom.x + dx, geom.y + dy, geom.width, geom.height)
end

function client.resize_relative(c, dw, dh)
  local geom = client.get_geometry(c)
  client.set_geometry(c, geom.x, geom.y, geom.width + dw, geom.height + dh)
end

-- Convenience functions
function client.get_all_titles()
  local clients = client.get_all()
  local titles = {}
  for i, c in ipairs(clients) do
    titles[i] = client.get_title(c) or "Untitled"
  end
  return titles
end

function client.find_by_title(title)
  local clients = client.get_all()
  for _, c in ipairs(clients) do
    if client.get_title(c) == title then
      return c
    end
  end
  return nil
end

function client.find_by_appid(appid)
  local clients = client.get_all()
  for _, c in ipairs(clients) do
    if client.get_appid(c) == appid then
      return c
    end
  end
  return nil
end

-- Pretty print client info
function client.info(c)
  if not c then return "No client" end
  
  local title = client.get_title(c) or "Untitled"
  local appid = client.get_appid(c) or "unknown"
  local geometry = client.get_geometry(c)
  local tags = client.get_tags(c)
  local floating = client.is_floating(c)
  local fullscreen = client.is_fullscreen(c)
  
  local pid = client.get_pid(c)
  
  return string.format(
    "%s (%s) [PID:%s] - %dx%d+%d+%d, tags:%d, floating:%s, fullscreen:%s",
    title, appid, pid or "unknown",
    geometry.width, geometry.height, geometry.x, geometry.y,
    tags, tostring(floating), tostring(fullscreen)
  )
end

-- Event handling functions
function client.connect_signal(signal_name, callback)
  Some.client_connect_signal(signal_name, callback)
end

function client.disconnect_signal(signal_name, callback_ref)
  Some.client_disconnect_signal(signal_name, callback_ref)
end

-- Convenience event connection functions
function client.on_map(callback)
  client.connect_signal("map", callback)
end

function client.on_unmap(callback)
  client.connect_signal("unmap", callback)
end

function client.on_focus(callback)
  client.connect_signal("focus", callback)
end

function client.on_unfocus(callback)
  client.connect_signal("unfocus", callback)
end

function client.on_title_change(callback)
  client.connect_signal("title_change", callback)
end

function client.on_fullscreen(callback)
  client.connect_signal("fullscreen", callback)
end

function client.on_floating(callback)
  client.connect_signal("floating", callback)
end

return client