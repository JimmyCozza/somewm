local logger = {}

-- Configure the log file
local LOG_FILE = "logs/somewm.log"
local LOG_LEVEL = "debug" -- debug, info, warn, error

-- Log levels
local LEVELS = {
  debug = 1,
  info = 2,
  warn = 3,
  error = 4
}

-- Current log level
local current_level = LEVELS[LOG_LEVEL] or LEVELS.info

-- Open log file once
local log_file

-- Initialize the logger
function logger.init()
  -- Ensure the logs directory exists
  local dir_stat = os.execute("mkdir -p logs")
  if dir_stat ~= 0 and dir_stat ~= true then
    print("Failed to create logs directory")
    return false
  end
  
  -- Open the log file for appending
  local file, err = io.open(LOG_FILE, "a")
  if not file then
    print("Failed to open log file: " .. (err or "unknown error"))
    return false
  end
  
  log_file = file
  
  -- Add a separator for new log session
  logger.info("===== SomeWM Log Session Started =====")
  return true
end

-- Internal logging function
local function log(level, message)
  if not log_file then
    if not logger.init() then
      return
    end
  end
  
  if LEVELS[level] >= current_level then
    local timestamp = os.date("%Y-%m-%d %H:%M:%S")
    local log_message = string.format("[%s] [%s] %s\n", timestamp, level:upper(), message)
    
    -- Write to file
    log_file:write(log_message)
    log_file:flush()
    
    -- Also print to console for immediate feedback
    print(log_message)
  end
end

-- Public logging methods
function logger.debug(message)
  log("debug", message)
end

function logger.info(message)
  log("info", message)
end

function logger.warn(message)
  log("warn", message)
end

function logger.error(message)
  log("error", message)
end

-- Set log level
function logger.set_level(level)
  if LEVELS[level] then
    current_level = LEVELS[level]
    logger.info("Log level set to: " .. level)
  else
    logger.error("Invalid log level: " .. level)
  end
end

-- Close the log file when exiting
function logger.close()
  if log_file then
    logger.info("===== SomeWM Log Session Ended =====")
    log_file:close()
    log_file = nil
  end
end

return logger
