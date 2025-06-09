-- SomeWM Minimal Configuration Example
-- Demonstrates the new 3-layer architecture with minimal setup

local somewm = require("somewm")

-- Initialize with minimal configuration
somewm.init({
  stack_insert_mode = "bottom"
})

-- Basic configuration
local config = {
  terminal = "wezterm",
  modkey = "logo"
}

-- Essential keybindings
somewm.key({
  modifiers = { config.modkey },
  key = "Return",
  description = "launch terminal",
  group = "applications",
  on_press = function()
    somewm.spawn(config.terminal)
  end,
})

somewm.key({
  modifiers = { config.modkey, "Shift" },
  key = "q",
  description = "close focused client",
  group = "clients",
  on_press = function()
    local focused = somewm.get_focused_client()
    if focused then
      focused:close()
    end
  end,
})

somewm.key({
  modifiers = { config.modkey, "Shift" },
  key = "Q",
  description = "quit SomeWM",
  group = "power",
  on_press = function()
    somewm.quit()
  end,
})

-- Basic window rules
somewm.add_window_rule(
  { class = "firefox" },
  { set_floating = false },
  "Firefox tiled"
)

-- Initialize compositor
Some.hello_world()

somewm.foundation.logger.info("Minimal SomeWM configuration loaded")