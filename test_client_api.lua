-- Test script for the client API using new 3-layer architecture
local somewm = require("somewm")

somewm.base.logger.info("Testing client API...")

-- Test getting all clients
local clients = somewm.get_clients()
somewm.base.logger.info("Number of clients: " .. #clients)

-- Test getting focused client
local focused = somewm.get_focused_client()
if focused then
  somewm.base.logger.info("Focused client: " .. (focused.title or "Untitled") .. " (" .. (focused.class or "Unknown") .. ")")
else
  somewm.base.logger.info("No focused client")
end

-- Test iterating through all clients
for i, c in ipairs(clients) do
  local info = string.format("%s (%s) [%dx%d at %d,%d]", 
    c.title or "Untitled", 
    c.class or "Unknown",
    c.width or 0, c.height or 0, 
    c.x or 0, c.y or 0)
  somewm.base.logger.info("Client " .. i .. ": " .. info)
end

-- Test property access
if focused then
  somewm.base.logger.info("Focused client properties:")
  somewm.base.logger.info("  Title: " .. (focused.title or "None"))
  somewm.base.logger.info("  Class: " .. (focused.class or "None"))
  somewm.base.logger.info("  Floating: " .. tostring(focused.floating))
  somewm.base.logger.info("  Fullscreen: " .. tostring(focused.fullscreen))
  somewm.base.logger.info("  Geometry: " .. (focused.width or 0) .. "x" .. (focused.height or 0) .. " at " .. (focused.x or 0) .. "," .. (focused.y or 0))
end

-- Test finding clients by class
local found_terminals = {}
for _, c in ipairs(clients) do
  if c.class and c.class:lower():match("term") then
    table.insert(found_terminals, c.title or "Untitled")
  end
end

if #found_terminals > 0 then
  somewm.base.logger.info("Found terminals: " .. table.concat(found_terminals, ", "))
else
  somewm.base.logger.info("No terminals found")
end

somewm.base.logger.info("Client API test completed")