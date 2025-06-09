-- Foundation geometry utilities for SomeWM
-- Based on AwesomeWM's gears.geometry for rectangle and position calculations

local geometry = {}

-- Create a new rectangle
function geometry.rectangle(x, y, width, height)
  return {
    x = x or 0,
    y = y or 0,
    width = width or 0,
    height = height or 0
  }
end

-- Get the area of a rectangle
function geometry.area(rect)
  return rect.width * rect.height
end

-- Check if two rectangles intersect
function geometry.intersects(rect1, rect2)
  return not (rect1.x + rect1.width <= rect2.x or
              rect2.x + rect2.width <= rect1.x or
              rect1.y + rect1.height <= rect2.y or
              rect2.y + rect2.height <= rect1.y)
end

-- Get the intersection of two rectangles
function geometry.intersection(rect1, rect2)
  if not geometry.intersects(rect1, rect2) then
    return geometry.rectangle(0, 0, 0, 0)
  end
  
  local x = math.max(rect1.x, rect2.x)
  local y = math.max(rect1.y, rect2.y)
  local right = math.min(rect1.x + rect1.width, rect2.x + rect2.width)
  local bottom = math.min(rect1.y + rect1.height, rect2.y + rect2.height)
  
  return geometry.rectangle(x, y, right - x, bottom - y)
end

-- Get the union (bounding box) of two rectangles
function geometry.union(rect1, rect2)
  local x = math.min(rect1.x, rect2.x)
  local y = math.min(rect1.y, rect2.y)
  local right = math.max(rect1.x + rect1.width, rect2.x + rect2.width)
  local bottom = math.max(rect1.y + rect1.height, rect2.y + rect2.height)
  
  return geometry.rectangle(x, y, right - x, bottom - y)
end

-- Check if a point is inside a rectangle
function geometry.point_in_rect(point, rect)
  return point.x >= rect.x and 
         point.x < rect.x + rect.width and
         point.y >= rect.y and 
         point.y < rect.y + rect.height
end

-- Check if rect1 is completely inside rect2
function geometry.rect_in_rect(rect1, rect2)
  return rect1.x >= rect2.x and
         rect1.y >= rect2.y and
         rect1.x + rect1.width <= rect2.x + rect2.width and
         rect1.y + rect1.height <= rect2.y + rect2.height
end

-- Get the center point of a rectangle
function geometry.center(rect)
  return {
    x = rect.x + rect.width / 2,
    y = rect.y + rect.height / 2
  }
end

-- Get distance between two points
function geometry.distance(point1, point2)
  local dx = point1.x - point2.x
  local dy = point1.y - point2.y
  return math.sqrt(dx * dx + dy * dy)
end

-- Get distance between two rectangles (closest edges)
function geometry.rect_distance(rect1, rect2)
  local dx = math.max(0, math.max(rect1.x - (rect2.x + rect2.width), 
                                  rect2.x - (rect1.x + rect1.width)))
  local dy = math.max(0, math.max(rect1.y - (rect2.y + rect2.height), 
                                  rect2.y - (rect1.y + rect1.height)))
  return math.sqrt(dx * dx + dy * dy)
end

-- Scale a rectangle by a factor
function geometry.scale(rect, factor_x, factor_y)
  factor_y = factor_y or factor_x
  return geometry.rectangle(
    rect.x,
    rect.y,
    rect.width * factor_x,
    rect.height * factor_y
  )
end

-- Translate a rectangle by dx, dy
function geometry.translate(rect, dx, dy)
  return geometry.rectangle(
    rect.x + dx,
    rect.y + dy,
    rect.width,
    rect.height
  )
end

-- Fit a rectangle inside another rectangle, maintaining aspect ratio
function geometry.fit_into(rect, container, scaling)
  scaling = scaling or "fit" -- "fit", "fill", "stretch"
  
  if scaling == "stretch" then
    return geometry.rectangle(container.x, container.y, container.width, container.height)
  end
  
  local scale_x = container.width / rect.width
  local scale_y = container.height / rect.height
  local scale
  
  if scaling == "fit" then
    scale = math.min(scale_x, scale_y)
  else -- "fill"
    scale = math.max(scale_x, scale_y)
  end
  
  local new_width = rect.width * scale
  local new_height = rect.height * scale
  local new_x = container.x + (container.width - new_width) / 2
  local new_y = container.y + (container.height - new_height) / 2
  
  return geometry.rectangle(new_x, new_y, new_width, new_height)
end

-- Split a rectangle horizontally into equal parts
function geometry.split_horizontal(rect, count)
  local parts = {}
  local part_width = rect.width / count
  
  for i = 1, count do
    parts[i] = geometry.rectangle(
      rect.x + (i - 1) * part_width,
      rect.y,
      part_width,
      rect.height
    )
  end
  
  return parts
end

-- Split a rectangle vertically into equal parts
function geometry.split_vertical(rect, count)
  local parts = {}
  local part_height = rect.height / count
  
  for i = 1, count do
    parts[i] = geometry.rectangle(
      rect.x,
      rect.y + (i - 1) * part_height,
      rect.width,
      part_height
    )
  end
  
  return parts
end

-- Add margins to a rectangle (shrink it)
function geometry.add_margins(rect, margins)
  if type(margins) == "number" then
    margins = { top = margins, right = margins, bottom = margins, left = margins }
  end
  
  return geometry.rectangle(
    rect.x + (margins.left or 0),
    rect.y + (margins.top or 0),
    rect.width - (margins.left or 0) - (margins.right or 0),
    rect.height - (margins.top or 0) - (margins.bottom or 0)
  )
end

-- Remove margins from a rectangle (expand it)
function geometry.remove_margins(rect, margins)
  if type(margins) == "number" then
    margins = { top = margins, right = margins, bottom = margins, left = margins }
  end
  
  return geometry.rectangle(
    rect.x - (margins.left or 0),
    rect.y - (margins.top or 0),
    rect.width + (margins.left or 0) + (margins.right or 0),
    rect.height + (margins.top or 0) + (margins.bottom or 0)
  )
end

-- Convert rectangle to string for debugging
function geometry.tostring(rect)
  return string.format("geometry{x=%d, y=%d, width=%d, height=%d}", 
                       rect.x, rect.y, rect.width, rect.height)
end

-- Copy a rectangle
function geometry.copy(rect)
  return geometry.rectangle(rect.x, rect.y, rect.width, rect.height)
end

return geometry