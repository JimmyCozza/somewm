# SomeWM Configuration Examples

This directory contains example configurations demonstrating the new 3-layer architecture.

## Files

### `rc-minimal.lua`
**Purpose**: Minimal configuration with essential features only  
**Good for**: New users, simple setups, understanding the basics  
**Features**:
- Basic keybindings (terminal, close, quit)
- Simple window rules
- Minimal setup with `somewm.init()`

**Usage**:
```bash
cp examples/rc-minimal.lua rc.lua
```

### `rc-advanced.lua`
**Purpose**: Full-featured configuration showcasing all capabilities  
**Good for**: Power users, complex setups, feature exploration  
**Features**:
- Comprehensive keybindings
- Advanced window automation
- Custom client event handling
- Widget system usage
- Smart behaviors enabled
- Debugging utilities

**Usage**:
```bash
cp examples/rc-advanced.lua rc.lua
```

### `rc-migration.lua`
**Purpose**: Migration guide and compatibility testing  
**Good for**: Users transitioning from old API to new architecture  
**Features**:
- Legacy API compatibility layer
- Side-by-side old vs new examples
- Migration testing utilities
- Gradual transition approach
- Compatibility cleanup helpers

**Usage**:
```bash
cp examples/rc-migration.lua rc.lua
# Use this to test migration from old API
```

## Architecture Overview

All examples use the new 3-layer architecture:

```lua
local somewm = require("somewm")

-- Unified entry point providing:
-- somewm.foundation - Base utilities, logging, signals
-- somewm.core       - Window management, clients, tags
-- somewm.ui         - Widgets, keybindings, automation
```

## Key Patterns

### Initialization
```lua
somewm.init({
  stack_insert_mode = "bottom",
  smart_behaviors = true
})
```

### Keybindings
```lua
somewm.key({
  modifiers = { "logo" },
  key = "Return",
  description = "launch terminal",
  group = "applications",
  on_press = function()
    somewm.spawn("wezterm")
  end,
})
```

### Window Rules
```lua
somewm.add_window_rule(
  { class = "firefox" },           -- conditions
  { set_tag = "web" },            -- actions
  "Firefox to web workspace"      -- description
)
```

### Property Access
```lua
local focused = somewm.get_focused_client()
if focused then
  focused.fullscreen = true       -- Property setter
  local title = focused.title     -- Property getter
end
```

### Notifications
```lua
somewm.notify("Hello World!", 3)  -- text, timeout
```

### Event Handling
```lua
somewm.core.client.connect_signal("manage", function(client)
  print("New client:", client.title)
end)
```

## Migration from Old API

If you have existing configuration using the old API:

1. **Start with migration example**: `cp examples/rc-migration.lua rc.lua`
2. **Enable compatibility**: The migration config enables legacy support automatically
3. **Test gradually**: Replace old patterns one by one with new API
4. **Use migration helpers**: Test compatibility and show migration tips
5. **Clean up**: Disable legacy support when migration is complete

### Old → New API Mapping

| Old Pattern | New Pattern |
|-------------|-------------|
| `require("client").get_focused()` | `somewm.get_focused_client()` |
| `require("widgets").create_notification()` | `somewm.notify()` |
| `awful.key({...})` | `somewm.key({...})` |
| `Some.spawn("cmd")` | `somewm.spawn("cmd")` |
| `Some.quit()` | `somewm.quit()` |
| `client.get_title(c)` | `c.title` |
| `client.toggle_fullscreen(c)` | `c.fullscreen = not c.fullscreen` |

## Benefits of New Architecture

1. **Cleaner API**: Property access instead of function calls
2. **Better Error Handling**: Proper error messages and logging
3. **Signal System**: React to events with callbacks
4. **Automation**: Declarative window rules
5. **Modularity**: Clear separation of concerns
6. **Extensibility**: Easy to add new features
7. **Performance**: Lazy loading and efficient patterns

## Customization Tips

1. **Start simple**: Use minimal config as base
2. **Add gradually**: Enable features as needed
3. **Use groups**: Organize keybindings by functionality
4. **Test automation**: Rules can handle complex window management
5. **Debug effectively**: Use `somewm.debug.*` functions
6. **Monitor logs**: `somewm.foundation.logger` provides insights

## Troubleshooting

- **Keybindings not working**: Check modifiers and key names
- **Rules not applying**: Verify class/title matching patterns
- **Notifications not showing**: Check widget system and LGI
- **Legacy code fails**: Enable compatibility layer in config
- **Performance issues**: Use lazy loading and minimal logging

For more help, use `somewm.debug.show_help()` in your configuration.