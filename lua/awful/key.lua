local key = {}

local function get_keysym(key)
  -- TODO: Move to library in C instead of registing the function directly
  return get_keysym_native(key)
end

local function get_modifier(mod)
  local mod_map = {
    Mod4 = 0x40,
    ["logo"] = 0x40,
    Shift = 0x01,
    Control = 0x04,
  }
  print("looking up mod: " .. mod)
  return mod_map[mod]
end

return setmetatable(key, {
  __call = function(_, args)
    print("registering key binding", args.key)
    if not args.modifiers or not args.key then
      error("key binding requires modifiers and key")
    end

    local mods = 0
    for _, mod in ipairs(args.modifiers) do
      local flag = get_modifier(mod)
      if flag then
        mods = mods | flag
      end
    end

    local keysym = get_keysym(args.key)
    if not keysym then
      error("unknown key: " .. args.key)
    end

    -- TODO: Move to library in C instead of registing the function directly
    register_key_binding(mods, keysym, args.on_press, args.on_release)

    return {
      modifiers = args.modifiers,
      key = args.key,
      description = args.description,
      group = args.group,
    }
  end,
})
