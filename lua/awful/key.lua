-- Compatibility layer for awful.key
-- Forwards to ui.keybindings with backward compatibility

local ui = require("ui")

local key = {}

-- Compatibility function that forwards to ui.keybindings
return setmetatable(key, {
  __call = function(_, args)
    -- Convert awful.key format to ui.keybindings format
    return ui.keybindings.add({
      modifiers = args.modifiers,
      key = args.key,
      on_press = args.on_press,
      on_release = args.on_release,
      description = args.description,
      group = args.group
    })
  end,
})
