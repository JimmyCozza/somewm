-- Test script for the new client API
local logger = require("logger")
local client = require("client")

logger.info("Testing client API...")

-- Test getting all clients
local clients = client.get_all()
logger.info("Number of clients: " .. #clients)

-- Test getting focused client
local focused = client.get_focused()
if focused then
  logger.info("Focused client: " .. client.info(focused))
else
  logger.info("No focused client")
end

-- Test iterating through all clients
for i, c in ipairs(clients) do
  logger.info("Client " .. i .. ": " .. client.info(c))
end

-- Test convenience functions
local titles = client.get_all_titles()
logger.info("All client titles: " .. table.concat(titles, ", "))

-- Test finding clients
local found_client = client.find_by_title("wezterm")
if found_client then
  logger.info("Found wezterm: " .. client.info(found_client))
else
  logger.info("wezterm not found")
end