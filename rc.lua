local awful = require("awful")

local modkey = "logo"

general_options = {
  -- Controls where new windows are inserted in the stack
  -- Valid values: "top" or "bottom"
  -- "top": New windows appear at the top/left of the stack
  -- "bottom": New windows appear at the bottom/right of the stack
  stack_insert_mode = "bottom",
}

awful.key({
  modifiers = { modkey },
  key = "p",
  description = "launch bemenu",
  group = "applications",
  on_press = function()
    Some.spawn("bemenu-run")
  end,
})

awful.key({
  modifiers = { modkey },
  key = "Return",
  description = "launch wezterm",
  group = "applications",
  on_press = function()
    Some.spawn("wezterm")
  end,
})

awful.key({
  modifiers = {},
  key = "XF86AudioRaiseVolume",
  description = "raise volume",
  group = "media",
  on_press = function()
    Some.spawn("pamixer -i 5")
  end,
})

awful.key({
  modifiers = {},
  key = "XF86AudioLowerVolume",
  description = "lower volume",
  group = "media",
  on_press = function()
    Some.spawn("pamixer -d 5")
  end,
})

awful.key({
  modifiers = {},
  key = "XF86AudioMute",
  description = "toggle mute",
  group = "media",
  on_press = function()
    Some.spawn("pamixer -t")
  end,
})

Some.hello_world()
