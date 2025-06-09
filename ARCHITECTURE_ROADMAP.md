# SomeWM 3-Layer Architecture Roadmap

## Overview

This document outlines the plan to restructure SomeWM into a clean 3-layer architecture that separates core compositor functionality, library APIs, and user configuration.

## Current State Analysis

### Architecture Progress
- ✅ **Clean 3-layer separation**: foundation/core/ui with proper abstractions
- ✅ **No direct `Some.*` calls** in UI layer - all abstracted through proper APIs
- ✅ **Foundation object system** with signals and property access
- ✅ **Lazy loading** prevents circular dependencies
- ✅ **Backward compatibility** maintained for existing awful.key usage
- ✅ **Clean user configuration**: `rc.lua` now uses unified 3-layer API
- ✅ **Backward compatibility**: Legacy code works during migration
- ✅ **Example configurations**: Multiple patterns for different use cases
- ❌ Legacy files still exist alongside new architecture (for compatibility)

### Current File Structure
```
lua/
├── foundation/       -- ✅ Base utilities and object system
│   ├── init.lua
│   ├── object.lua    -- Signal/property system
│   ├── geometry.lua  -- Position/rectangle utilities
│   ├── signal.lua    -- Global event system
│   └── logger.lua    -- Centralized logging
├── core/            -- ✅ Window manager functionality
│   ├── init.lua
│   ├── client.lua    -- High-level client API
│   ├── monitor.lua   -- Display management
│   ├── tag.lua       -- Workspace management
│   └── rules.lua     -- Declarative window rules
├── ui/              -- ✅ User interface and automation
│   ├── init.lua
│   ├── widgets.lua   -- Widget creation using foundation.object
│   ├── keybindings.lua -- Input handling with signals
│   └── automation.lua -- Smart window behaviors
├── awful/           -- ✅ Backward compatibility layer
│   ├── init.lua
│   └── key.lua       -- Forwards to ui.keybindings
├── somewm.lua       -- ✅ Unified entry point
├── compat.lua       -- ✅ Backward compatibility layer
├── client.lua       -- ❌ LEGACY - use core.client
├── monitor.lua      -- ❌ LEGACY - use core.monitor  
├── tag.lua          -- ❌ LEGACY - use core.tag
└── widgets.lua      -- ❌ LEGACY - use ui.widgets

rc.lua               -- ✅ Clean user config using 3-layer API
examples/            -- ✅ Example configurations
├── rc-minimal.lua   -- Basic setup
├── rc-advanced.lua  -- Full features  
├── rc-migration.lua -- Migration guide
└── README.md        -- Documentation
```

## Target Architecture

### Layer 1: C Core (`dwl.c`, `luaa.c`)
**Responsibility**: Raw Wayland compositor, memory management, core protocols

**Principles**:
- Minimal, stable API focused on core primitives
- Direct wlroots/Wayland protocol implementation
- Memory-safe wrapper functions with `lua_*` prefix
- No high-level convenience functions
- Type-safe void* pointer abstraction

**Functions to Keep**:
- Essential client manipulation (`lua_client_focus`, `lua_client_close`)
- Core data access (`lua_client_get_title`, `lua_client_get_geometry`)
- Event system registration (`lua_event_connect`)
- Process spawning (`lua_spawn`)
- Basic tag operations

### Layer 2: SomeWM Lua Library 
**Responsibility**: Complete compositor control API, all abstractions

Based on AwesomeWM's proven architecture, SomeWM will use a 3-sublayer approach:

#### **Foundation Layer (`lua/foundation/`)**
Core utilities and base systems (inspired by AwesomeWM's `gears/`)
```
lua/foundation/
├── init.lua          -- Export all foundation modules
├── object.lua        -- Base object system with signals/properties
├── geometry.lua      -- Rectangle/position utilities  
├── signal.lua        -- Event system core
├── timer.lua         -- Event scheduling system
└── logger.lua        -- Centralized logging
```

#### **Core Layer (`lua/core/`)**  
Window manager functionality (inspired by AwesomeWM's `awful/`)
```
lua/core/
├── init.lua          -- Export all core modules
├── client.lua        -- High-level client API
├── monitor.lua       -- Display management
├── tag.lua           -- Workspace management
└── rules.lua         -- Declarative window rules
```

#### **UI/Automation Layer (`lua/ui/`)**
User interface and automation (inspired by AwesomeWM's `wibox/` and `ruled/`)
```
lua/ui/
├── init.lua          -- Export all UI modules
├── widgets.lua       -- Widget creation and management
├── automation.lua    -- Smart window behaviors
└── keybindings.lua   -- Input handling
```

**API Design Principles** (based on AwesomeWM patterns):
- **Init.lua pattern**: Every module exports submodules via consistent init.lua
- **Property access**: Automatic getter/setter with `obj.property` syntax  
- **Signal-based events**: Observer pattern for all lifecycle events
- **Lazy loading**: Metatables prevent circular dependencies
- **Reference counting**: Proper C object lifetime management
- **Naming conventions**: `verb_noun` for functions, direct access for properties
- **Rule-based config**: Declarative window automation like `ruled.client`

### Layer 3: User Configuration (`rc.lua` ecosystem)
**Responsibility**: User-specific configuration, imports somewm library

**Structure** (following AwesomeWM patterns):
```lua
-- Import the 3-layer library
local foundation = require("foundation")
local core = require("core") 
local ui = require("ui")

-- Or import the unified interface
local somewm = require("somewm") -- exports foundation + core + ui

-- Pure user configuration  
local config = {
  terminal = "wezterm",
  modkey = "Mod4",
}

-- Declarative window rules (like ruled.client)
core.rules.add {
  rule = { class = "Firefox" },
  properties = { tag = "web", floating = false }
}

-- Property-based client handling
core.client.connect_signal("request::activate", function(c)
  c.urgent = false  -- Direct property access
end)

-- Keybindings using foundation timer + core spawn
ui.keybindings.add(config.modkey, "Return", function()
  core.spawn(config.terminal)
end)
```

## Migration Plan

### Phase 1: Foundation ✅ COMPLETED
- [x] Analyze current architecture
- [x] Design 3-layer separation
- [x] Create roadmap document

### Phase 2: Foundation Layer (inspired by gears/) ✅ COMPLETED
- [x] Create `lua/foundation/` directory structure
- [x] Implement `lua/foundation/object.lua` - base object system with signals
- [x] Implement `lua/foundation/geometry.lua` - rectangle/position utilities
- [x] Implement `lua/foundation/signal.lua` - event system core
- [x] Migrate `lua/logger.lua` → `lua/foundation/logger.lua`
- [x] Create `lua/foundation/init.lua` exporting all modules

### Phase 3: Core Layer Migration (inspired by awful/) ✅ COMPLETED
- [x] Create `lua/core/` directory structure
- [x] Migrate `lua/client.lua` → `lua/core/client.lua`
  - [x] Use foundation.object as base class
  - [x] Implement property access pattern
  - [x] Abstract away direct `Some.*` calls
- [x] Migrate `lua/monitor.lua` → `lua/core/monitor.lua`
- [x] Migrate `lua/tag.lua` → `lua/core/tag.lua`
- [x] Implement `lua/core/rules.lua` - declarative window rules
- [x] Create `lua/core/init.lua` exporting all modules

### Phase 4: UI/Automation Layer (inspired by wibox/ruled/) ✅ COMPLETED
- [x] Create `lua/ui/` directory structure
- [x] Migrate `lua/widgets.lua` → `lua/ui/widgets.lua`
  - [x] Use foundation.object for widget base classes
  - [x] Abstract Cairo/LGI integration
  - [x] Implement property access pattern
  - [x] Remove direct `Some.*` calls
- [x] Implement `lua/ui/keybindings.lua` with foundation.signal
  - [x] Property-based keybinding objects
  - [x] Signal system integration
  - [x] Group management and help system
- [x] Implement `lua/ui/automation.lua` for smart behaviors
  - [x] Rule-based automation system
  - [x] Smart focus, placement, and tag persistence
  - [x] Declarative window rules
- [x] Update `lua/awful/` integration
  - [x] Forward awful.key to ui.keybindings
  - [x] Maintain backward compatibility
- [x] Create `lua/ui/init.lua` exporting all modules
  - [x] Lazy loading with metatables
  - [x] Convenience functions
  - [x] Auto-initialization

### Phase 5: Configuration Cleanup ✅ COMPLETED
- [x] Create unified `lua/somewm.lua` entry point
  - [x] Unified interface exporting foundation/core/ui
  - [x] Convenience functions for common operations
  - [x] Configuration helpers and initialization
  - [x] Backward compatibility layer integration
- [x] Refactor `rc.lua` to use new 3-layer API
  - [x] Replace all direct `Some.*` calls with proper abstractions
  - [x] Use property access patterns for clients
  - [x] Implement declarative window rules
  - [x] Use new keybinding and widget systems
- [x] Remove direct `Some.*` calls from user config
  - [x] All `Some.spawn()` → `somewm.spawn()`
  - [x] All `Some.quit()` → `somewm.quit()`
  - [x] Client manipulation via property access
  - [x] Widget creation via unified API
- [x] Implement backward compatibility shims
  - [x] Legacy `require("client")` compatibility
  - [x] Legacy `require("widgets")` compatibility
  - [x] Legacy `require("logger")` compatibility
  - [x] Legacy `Some.*` function wrapping
  - [x] Migration testing utilities
- [x] Create example configurations using new API
  - [x] `examples/rc-minimal.lua` - Basic setup
  - [x] `examples/rc-advanced.lua` - Full features
  - [x] `examples/rc-migration.lua` - Migration guide
  - [x] `examples/README.md` - Documentation

### Phase 6: Memory Management & C Integration
- [ ] Implement reference counting for C object lifetime management
  - [ ] Add reference tracking for client objects
  - [ ] Automatic cleanup when Lua objects are garbage collected
  - [ ] Prevent crashes from accessing destroyed C objects
  - [ ] Memory leak detection and prevention
  - [ ] Safe client pointer validation

### Phase 7: Enhanced Module System
- [ ] Advanced lazy loading with metatables
  - [ ] Sophisticated circular dependency prevention
  - [ ] Performance optimization through selective loading
  - [ ] Module dependency graph analysis
  - [ ] Hot-reloading support for development
  - [ ] Module versioning and compatibility checking

### Phase 8: Advanced Property System
- [ ] Comprehensive property access system
  - [ ] Property validation and type checking
  - [ ] Computed properties with dependencies
  - [ ] Property change batching and transactions
  - [ ] Property observers and reactive updates
  - [ ] Schema-based property definitions

### Phase 9: Timer & Event System
- [ ] Timer system in foundation layer
  - [ ] Event scheduling and delayed execution
  - [ ] Recurring tasks and intervals
  - [ ] Debouncing and throttling utilities
  - [ ] Animation framework foundation
  - [ ] Performance monitoring and profiling timers

### Phase 10: Advanced Automation
- [ ] Enhanced rule-based client automation
  - [ ] Complex condition matching with logical operators
  - [ ] Rule priorities and conflict resolution
  - [ ] Runtime rule modification and hot-reloading
  - [ ] Machine learning-based window placement
  - [ ] User behavior analytics and adaptive rules

### Phase 11: Testing & Documentation
- [ ] Update all test files to use library APIs
- [ ] Create comprehensive API documentation
- [ ] Add usage examples for each module
- [ ] Performance testing and optimization
- [ ] Migration guide from current API

## Implementation Guidelines

### API Design Standards (based on AwesomeWM best practices)

#### **Module Organization**
- Every module has `init.lua` that exports submodules
- Use lazy loading with metatables: `setmetatable({}, {__index = function() return require("module") end})`
- Consistent 3-layer import: `foundation` → `core` → `ui`

#### **Naming Conventions**
- Functions: `verb_noun` format (e.g., `client.focus_byidx`, `tag.swap_with`)
- Properties: Direct access (e.g., `client.name`, `client.urgent`)  
- Signals: `event_name` format (e.g., `"property::name"`, `"request::activate"`)

#### **Object System** 
- Base class: `foundation.object` with signals and property access
- Property pattern: `obj.property = value` auto-calls setters
- Signal pattern: `obj:connect_signal(name, callback)` for events
- Reference counting: Automatic C object lifetime management

### Error Handling
- All library functions should handle C API failures gracefully
- Provide meaningful error messages to users
- Use Lua's `error()` for unrecoverable failures
- Return `nil, error_message` for recoverable failures

### Performance Considerations
- Cache expensive C API calls where appropriate
- Minimize Lua ↔ C boundary crossings
- Use efficient data structures
- Profile critical paths

### Backward Compatibility
- Maintain compatibility shims during migration
- Deprecation warnings for old APIs
- Clear migration documentation
- Version the library API

## Success Metrics

### Architecture Quality
- [ ] Zero direct `Some.*` calls in user configuration
- [ ] Clear separation of concerns across layers
- [ ] Consistent API patterns across all modules
- [ ] Comprehensive test coverage

### Developer Experience
- [ ] Intuitive API that matches user mental models
- [ ] Rich documentation with examples
- [ ] Easy migration path from current setup
- [ ] Performance equal or better than current

### Maintainability
- [ ] Modular codebase with clear boundaries
- [ ] Easy to add new compositor features
- [ ] Stable C API that rarely changes
- [ ] Library API that can evolve independently

## Future Considerations

### Extensibility
- Plugin system for third-party extensions
- IPC interface for external tools
- Configuration validation and schema
- Hot-reloading of configuration

### Distribution
- Package the library separately from core compositor
- Versioned releases with semantic versioning
- Package manager integration (LuaRocks)
- Multiple configuration template options

## Progress Tracking

**Current Status**: Phase 5 Complete ✅

**Next Milestone**: Complete Phase 6 (Memory Management & C Integration)

**Completed Timeline**: 
- Phase 2 (Foundation): ✅ 3 days
- Phase 3 (Core): ✅ 4 days  
- Phase 4 (UI): ✅ 2 days
- Phase 5 (Config): ✅ 1 day
- Phase 6 (Memory Management): 2-3 days remaining
- Phase 7 (Enhanced Modules): 2-3 days remaining  
- Phase 8 (Property System): 3-4 days remaining
- Phase 9 (Timer System): 2-3 days remaining
- Phase 10 (Advanced Automation): 3-4 days remaining
- Phase 11 (Testing & Docs): 3-4 days remaining

**Progress**: 10/31 days completed (32% done)
**Estimated Total**: 4-5 weeks for complete advanced architecture

## AwesomeWM Architecture Insights Applied

### Key Learnings Integrated:
- ✅ **3-sublayer architecture**: foundation/core/ui instead of flat structure
- ✅ **Signal-based events**: Observer pattern for all lifecycle management
- ✅ **Property access abstraction**: `obj.property` syntax with automatic getters/setters
- ✅ **Init.lua pattern**: Consistent module exports across all layers
- ✅ **Reference counting**: Proper C object lifetime management 
- ✅ **Lazy loading**: Metatables prevent circular dependency issues
- ✅ **Rule-based config**: Declarative automation like `ruled.client`

### Architecture Stability:
AwesomeWM's architecture has proven stable for 10+ years in production, providing confidence that this approach will scale well for SomeWM's needs.

---

*Last Updated: 2025-06-09*
*Document Version: 1.3 - Roadmap Restructured*