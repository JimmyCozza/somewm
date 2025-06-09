-- Base layer for SomeWM
-- Provides core utilities and base systems for higher-level modules
-- Based on AwesomeWM's gears/ architecture pattern

-- Base layer modules
local base = {
  -- Base object system with signals and property management
  object = require("base.object"),
  
  -- Geometry utilities for rectangle and position calculations  
  geometry = require("base.geometry"),
  
  -- Global signal system for cross-module communication
  signal = require("base.signal"),
  
  -- Centralized logging system
  logger = require("base.logger"),
}

-- Initialize base systems
function base.init()
  -- Initialize logger first
  base.logger.init()
  base.logger.info("Base layer initialized")
  
  -- Emit global signal that base is ready
  base.signal.emit("base::ready")
  
  return true
end

-- Clean shutdown of base systems
function base.shutdown()
  base.logger.info("Base layer shutting down")
  
  -- Clear all global signals
  base.signal.clear_all()
  
  -- Close logger
  base.logger.close()
  
  -- Emit shutdown signal
  base.signal.emit("base::shutdown")
end

-- Base version information
base._VERSION = "1.0.0"
base._DESCRIPTION = "SomeWM Base Layer - Core utilities and base systems"
base._LICENSE = "MIT"

-- Utility function to create base objects with consistent setup
function base.create_object()
  local obj = base.object.new()
  
  -- Add common base properties
  obj:add_property("_base_version", {
    getter = function() return base._VERSION end
  })
  
  return obj
end

-- Export base layer
return base