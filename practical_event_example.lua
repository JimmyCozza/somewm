-- Practical Example: Advanced Window Management with Events
local somewm = require("somewm")
local logger = somewm.foundation.logger
local client = somewm.core.client

logger.info("Setting up practical event-based window management...")

-- Example 1: Auto-float certain applications
client.on_map(function(c, data)
  local appid = c.appid
  local title = c.title
  
  -- Auto-float dialog windows, calculator, etc.
  if appid and (appid:match("calculator") or appid:match("dialog") or 
                appid:match("popup") or appid:match("menu")) then
    c.floating = true
    logger.info("Auto-floated application: " .. appid)
  end
  
  -- Auto-float windows with certain titles
  if title and (title:match("Preferences") or title:match("Settings") or
                title:match("Configure") or title:match("Properties")) then
    c.floating = true
    logger.info("Auto-floated window by title: " .. title)
  end
end)

-- Example 2: Smart positioning for new floating windows
client.on_floating(function(c, data)
  if c.floating then
    -- Center floating windows on screen
    local geometry = c.geometry
    local screen_width = 1920  -- Could get from monitor API later
    local screen_height = 1080
    
    local new_x = (screen_width - geometry.width) / 2
    local new_y = (screen_height - geometry.height) / 2
    
    c.geometry = {x = new_x, y = new_y, width = geometry.width, height = geometry.height}
    logger.info("Centered floating window: " .. (c.title or "Untitled"))
  end
end)

-- Example 3: Log focus changes for productivity tracking
local focus_log = {}

client.on_focus(function(c, data)
  local appid = c.appid or "unknown"
  local title = c.title or "Untitled"
  local timestamp = os.time()
  
  table.insert(focus_log, {
    timestamp = timestamp,
    appid = appid,
    title = title,
    event = "focus"
  })
  
  logger.info("Focus tracking: " .. appid .. " - " .. title)
end)

-- Example 4: Automatic workspace assignment based on application
client.on_map(function(c, data)
  local appid = c.appid
  
  if appid then
    -- Web browsers go to tag 2
    if appid:match("firefox") or appid:match("chromium") or appid:match("browser") then
      c.tags = 2
      logger.info("Auto-assigned " .. appid .. " to workspace 2")
    
    -- Development tools go to tag 3
    elseif appid:match("code") or appid:match("vim") or appid:match("emacs") or 
           appid:match("editor") or appid:match("terminal") then
      c.tags = 3
      logger.info("Auto-assigned " .. appid .. " to workspace 3")
    
    -- Media applications go to tag 4
    elseif appid:match("media") or appid:match("video") or appid:match("audio") or
           appid:match("vlc") or appid:match("player") then
      c.tags = 4
      logger.info("Auto-assigned " .. appid .. " to workspace 4")
    end
  end
end)

-- Example 5: Title change monitoring for specific applications
client.on_title_change(function(c, data)
  local appid = c.appid
  local title = c.title
  
  -- Monitor web browser tabs
  if appid and appid:match("firefox") and title then
    logger.info("Browser tab changed: " .. title)
  end
  
  -- Monitor terminal working directory changes
  if appid and appid:match("terminal") and title then
    if title:match("/") then  -- Likely a path
      logger.info("Terminal directory: " .. title)
    end
  end
end)

-- Example 6: Prevent accidental fullscreen for certain apps
client.on_fullscreen(function(c, data)
  local appid = c.appid
  
  -- Don't allow fullscreen for calculator or small utility apps
  if appid and (appid:match("calculator") or appid:match("clock") or 
                appid:match("timer")) and c.fullscreen then
    c.fullscreen = false
    logger.info("Prevented fullscreen for utility app: " .. appid)
  end
end)

-- Utility function to print focus log
function print_focus_log()
  logger.info("=== Focus Log ===")
  for i = math.max(1, #focus_log - 10), #focus_log do
    local entry = focus_log[i]
    logger.info(os.date("%H:%M:%S", entry.timestamp) .. " - " .. 
                entry.appid .. " - " .. entry.title)
  end
  logger.info("=================")
end

logger.info("Practical event-based window management is now active!")
logger.info("Features enabled:")
logger.info("  - Auto-floating for dialogs and utilities")
logger.info("  - Smart centering of floating windows")
logger.info("  - Focus tracking for productivity")
logger.info("  - Automatic workspace assignment by app type")
logger.info("  - Browser tab monitoring")
logger.info("  - Fullscreen prevention for utility apps")
logger.info("")
logger.info("Try opening different applications to see the automation in action!")