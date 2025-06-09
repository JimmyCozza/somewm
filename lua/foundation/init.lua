-- Foundation layer for SomeWM
-- Provides core utilities and base systems for higher-level modules
-- Based on AwesomeWM's gears/ architecture pattern

-- Foundation layer modules
local foundation = {
  -- Base object system with signals and property management
  object = require("foundation.object"),
  
  -- Geometry utilities for rectangle and position calculations  
  geometry = require("foundation.geometry"),
  
  -- Global signal system for cross-module communication
  signal = require("foundation.signal"),
  
  -- Centralized logging system
  logger = require("foundation.logger"),
}

-- Initialize foundation systems
function foundation.init()
  -- Initialize logger first
  foundation.logger.init()
  foundation.logger.info("Foundation layer initialized")
  
  -- Emit global signal that foundation is ready
  foundation.signal.emit("foundation::ready")
  
  return true
end

-- Clean shutdown of foundation systems
function foundation.shutdown()
  foundation.logger.info("Foundation layer shutting down")
  
  -- Clear all global signals
  foundation.signal.clear_all()
  
  -- Close logger
  foundation.logger.close()
  
  -- Emit shutdown signal
  foundation.signal.emit("foundation::shutdown")
end

-- Foundation version information
foundation._VERSION = "1.0.0"
foundation._DESCRIPTION = "SomeWM Foundation Layer - Core utilities and base systems"
foundation._LICENSE = "MIT"

-- Utility function to create foundation objects with consistent setup
function foundation.create_object()
  local obj = foundation.object.new()
  
  -- Add common foundation properties
  obj:add_property("_foundation_version", {
    getter = function() return foundation._VERSION end
  })
  
  return obj
end

-- Export foundation layer
return foundation