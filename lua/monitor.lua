-- Monitor API module for SomeWM
-- Provides a high-level interface to monitor management functions

local monitor = {}

-- Get all monitors
function monitor.get_all()
  return Some.monitor_get_all()
end

-- Get focused monitor
function monitor.get_focused()
  return Some.monitor_get_focused()
end

-- Monitor property getters
function monitor.get_name(m)
  return Some.monitor_get_name(m)
end

function monitor.get_geometry(m)
  return Some.monitor_get_geometry(m)
end

function monitor.get_workarea(m)
  return Some.monitor_get_workarea(m)
end

function monitor.get_layout_symbol(m)
  return Some.monitor_get_layout_symbol(m)
end

function monitor.get_master_factor(m)
  return Some.monitor_get_master_factor(m)
end

function monitor.get_master_count(m)
  return Some.monitor_get_master_count(m)
end

function monitor.get_tags(m)
  return Some.monitor_get_tags(m)
end

function monitor.is_enabled(m)
  return Some.monitor_get_enabled(m)
end

-- Monitor manipulation functions
function monitor.focus(m)
  Some.monitor_focus(m)
end

function monitor.set_tags(m, tags)
  Some.monitor_set_tags(m, tags)
end

function monitor.set_master_factor(m, factor)
  Some.monitor_set_master_factor(m, factor)
end

function monitor.set_master_count(m, count)
  Some.monitor_set_master_count(m, count)
end

-- Convenience functions
function monitor.find_by_name(name)
  local monitors = monitor.get_all()
  for _, m in ipairs(monitors) do
    if monitor.get_name(m) == name then
      return m
    end
  end
  return nil
end

function monitor.get_primary()
  -- Return first monitor or focused monitor as primary
  local focused = monitor.get_focused()
  if focused then
    return focused
  end
  
  local monitors = monitor.get_all()
  if #monitors > 0 then
    return monitors[1]
  end
  
  return nil
end

-- Helper function to get monitor info as a table
function monitor.info(m)
  if not m then return nil end
  
  return {
    name = monitor.get_name(m),
    geometry = monitor.get_geometry(m),
    workarea = monitor.get_workarea(m),
    layout_symbol = monitor.get_layout_symbol(m),
    master_factor = monitor.get_master_factor(m),
    master_count = monitor.get_master_count(m),
    tags = monitor.get_tags(m),
    enabled = monitor.is_enabled(m)
  }
end

-- Helper function to get info for all monitors
function monitor.get_all_info()
  local monitors = monitor.get_all()
  local info_list = {}
  
  for i, m in ipairs(monitors) do
    info_list[i] = monitor.info(m)
  end
  
  return info_list
end

return monitor