# someWM - Lua-Scriptable Wayland Compositor

someWM is a powerful, customizable fork of dwl that integrates Lua scripting for advanced window management and configuration. It extends the base dwl compositor with complete programmatic control over windows, real-time event systems, and widget rendering capabilities.

## Key Features

- **Complete Client API** - Full programmatic control over window management from Lua
- **Real-time Event System** - React to window state changes with custom callbacks  
- **Advanced Window Automation** - Smart positioning, workspace assignment, focus tracking
- **Lua-based Configuration** - Runtime configuration via `rc.lua` instead of recompiling
- **Widget System** - Desktop widgets using LGI/Cairo with Wayland layer shell
- **Enhanced Keybindings** - Lua callbacks for complex key combinations

## Philosophy

Like dwm and dwl, someWM maintains:
- Easy to understand and extend architecture
- Minimal external dependencies
- Hackable codebase focused on power users

But adds:
- Runtime scriptability without recompilation
- Complete window management automation
- Modern widget and theming capabilities

## Getting Started

### Requirements

someWM builds against **wlroots 0.18.x** and requires:

### Building someWM
someWM has the following dependencies:

**Core dependencies:**
- libinput
- wayland
- wlroots 0.18.x (compiled with the libinput backend)
- xkbcommon
- wayland-protocols (compile-time only)
- pkg-config (compile-time only)

**Lua scripting dependencies:**
- lua5.4
- lua5.4-dev

**Widget system dependencies:**
- cairo
- glib2.0
- gobject-introspection
- lua-lgi (for Cairo bindings)

**Optional XWayland support:**
- libxcb
- libxcb-wm
- wlroots (compiled with X11 support)
- Xwayland (runtime only)

Install these (and their `-devel` versions if your distro has separate
development packages) and run `make`. 

To enable XWayland, you should uncomment its flags in `config.mk`.

## Configuration

someWM uses a hybrid configuration approach:

**Static Configuration (`config.h`):**
- Basic appearance settings (borders, colors, gaps)
- Core compositor behavior
- Requires recompilation to change

**Dynamic Configuration (`rc.lua`):**
- Keybindings and window management rules
- Widget definitions and theming
- Client automation scripts and event handlers
- Changes take effect immediately without recompilation

### Example rc.lua Features:
```lua
-- Smart window placement
client.on_create(function(c)
  if c.class == "firefox" then
    c:move_to_tag(2)
    c:focus()
  end
end)

-- Custom keybindings with Lua callbacks
awful.key({ "Mod4" }, "t", function()
  -- Open terminal in current workspace
  awful.spawn("foot")
end)

-- Widget creation
local clock = widget.textclock("%H:%M")
```

## Running someWM

someWM can be run on any of the backends supported by wlroots. This means you can
run it as a separate window inside either an X11 or Wayland session, as well as
directly from a VT console. Depending on your distro's setup, you may need to
add your user to the `video` and `input` groups before you can run someWM on a
VT. If you are using `elogind` or `systemd-logind` you need to install polkit;
otherwise you need to add yourself in the `seat` group and enable/start the
seatd daemon.

When someWM is run with no arguments, it will launch the server and begin handling
shortcuts and automation scripts configured in `rc.lua`. The compositor will
automatically load and execute your Lua configuration, enabling dynamic
keybindings, window rules, and widget creation.

If you would like to run a script or command automatically at startup, you can
specify the command using the `-s` option. This command will be executed as a
shell command using `/bin/sh -c`.  It serves a similar function to `.xinitrc`,
but differs in that the display server will not shut down when this process
terminates. Instead, someWM will send this process a SIGTERM at shutdown and wait
for it to terminate (if it hasn't already). This makes it ideal for execing into
a user service manager like [s6], [anopa], [runit], [dinit], or [`systemd
--user`].

Note: The `-s` command is run as a *child process* of someWM, which means that it
does not have the ability to affect the environment of someWM or of any processes
that it spawns. If you need to set environment variables that affect the entire
someWM session, these must be set prior to running someWM. For example, Wayland
requires a valid `XDG_RUNTIME_DIR`, which is usually set up by a session manager
such as `elogind` or `systemd-logind`.  If your system doesn't do this
automatically, you will need to configure it prior to launching `someWM`, e.g.:

    export XDG_RUNTIME_DIR=/tmp/xdg-runtime-$(id -u)
    mkdir -p $XDG_RUNTIME_DIR
    ./dwl

### Status information

Information about selected layouts, current window title, app-id, and
selected/occupied/urgent tags is written to the stdin of the `-s` command (see
the `printstatus()` function for details).  This information can be used to
populate an external status bar with a script that parses the
information. Failing to read this information will cause someWM to block, so if you
do want to run a startup command that does not consume the status information,
you can close standard input with the `<&-` shell redirection, for example:

    ./dwl -s 'foot --server <&-'

If your startup command is a shell script, you can achieve the same inside the
script with the line

    exec <&-

However, someWM also supports **native Lua widgets** that can display status
information directly without external bars. See `lua/widgets.lua` for examples.

## Lua API Overview

someWM provides a comprehensive Lua API for window management:

### Client Management
```lua
-- Access all client properties
local clients = client.get()
for _, c in ipairs(clients) do
  print(c.title, c.class, c.geometry)
end

-- Manipulate windows
client.focus(c)
c:move(100, 100)
c:resize(800, 600)
c:close()
```

### Event System
```lua
-- React to window events
client.on_create(function(c) end)
client.on_destroy(function(c) end)
client.on_focus(function(c) end)
client.on_title_change(function(c) end)
```

### Widget System
```lua
-- Create desktop widgets
local widget = require("widgets")
local clock = widget.textclock()
local systray = widget.systray()
```

## Architecture

someWM extends dwl with a 3-phase client management system:

1. **READ Phase** - Complete access to window properties
2. **WRITE Phase** - Full control over window behavior  
3. **REACT Phase** - Real-time event callbacks

This provides the foundation for advanced automation while maintaining the
simplicity and performance of the underlying dwl compositor.

## Background

someWM maintains dwl's philosophy of simplicity while adding powerful
scriptability. Core features include:

**Core dwl features (inherited):**
- Simple window borders, tags, keybindings, client rules, mouse move/resize
- Configurable multi-monitor layout support, including position and rotation
- Configurable HiDPI/multi-DPI support
- Idle-inhibit protocol which lets applications such as mpv disable idle monitoring
- Urgency hints via xdg-activate protocol
- Support screen lockers via ext-session-lock-v1 protocol
- Various Wayland protocols
- XWayland support as provided by wlroots (can be enabled in `config.mk`)
- Zero flickering - Wayland users naturally expect that "every frame is perfect"
- Layer shell popups (used by Waybar)
- Damage tracking provided by scenegraph API

**someWM extensions:**
- **Complete Lua Client API** - Read, write, and react to all window properties
- **Real-time Event System** - Callbacks for window lifecycle management
- **Native Widget System** - Cairo-based desktop widgets via LGI
- **Runtime Configuration** - No recompilation required for most changes
- **Advanced Automation** - Smart window placement, focus tracking, workspace management
- **Memory-Safe Lua Integration** - Proper callback cleanup and resource management

someWM adds significant functionality while maintaining the core simplicity and
performance characteristics of dwl. The Lua integration is designed to be
completely optional - users can ignore scripting entirely and use someWM as a
standard dwl compositor.

## Testing the Client API

someWM includes comprehensive test keybindings in `rc.lua`:

- `Super+c`: Test client data access (READ phase)
- `Super+Shift+c`: Test client manipulation (WRITE phase)  
- `Super+e`: Test event system (REACT phase)
- `Super+Shift+e`: Enable practical automation examples
- `Super+f`: Toggle fullscreen
- `Super+Shift+Space`: Toggle floating
- `Super+Shift+q`: Close focused client

These demonstrate the full capabilities of the client API system.

## Future Development

Features under consideration:
- Additional Wayland protocols made trivial by wlroots
- Text-input and input-method protocols for IME support
- Enhanced widget theming and styling options
- Lua module system for sharing configurations

Feature *non-goals* consistent with dwl:
- Client-side decoration (beyond telling clients not to use it)
- Heavy animations and visual effects  
- Bloated feature creep that compromises performance

## Credits

**someWM** started as a fork of **dwl** and extends it with Lua scripting capabilities
while maintaining the core design philosophy and performance characteristics.

### dwl Acknowledgements

dwl began by extending the TinyWL example provided (CC0) by the sway/wlroots
developers. This was made possible in many cases by looking at how sway
accomplished something, then trying to do the same in as suckless a way as
possible.

Many thanks to suckless.org and the dwm developers and community for the
inspiration, and to the various contributors to the dwl project, including:

- **Devin J. Pohly** for creating and nurturing the dwl project
- **Alexander Courtis** for the XWayland implementation
- **Guido Cella** for the layer-shell protocol implementation, patch maintenance,
  and for helping to keep the project running
- **Stivvo** for output management and fullscreen support, and patch maintenance

### someWM Development

someWM development focuses on extending dwl's capabilities while preserving its
core philosophy of simplicity and hackability. The Lua integration provides
power users with advanced automation capabilities without compromising the
compositor's performance or stability.


[`systemd --user`]: https://wiki.archlinux.org/title/Systemd/User
[anopa]: https://jjacky.com/anopa/
[dinit]: https://davmac.org/projects/dinit/
[runit]: http://smarden.org/runit/faq.html#userservices
[s6]: https://skarnet.org/software/s6/
[wlroots]: https://gitlab.freedesktop.org/wlroots/wlroots/
[Wayland]: https://wayland.freedesktop.org/
