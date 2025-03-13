-- wayland_surface.lua
-- Handles creation and management of Wayland surfaces for widgets
local logger = require("logger")
local lgi = require("lgi")
local cairo = lgi.cairo

local wayland_surface = {}

-- Function to create a basic surface
function wayland_surface.create_widget_surface(width, height, x, y, text)
    logger.info(string.format("Creating wayland surface: %dx%d at %d,%d", width, height, x, y))
    
    -- Check if notify-send is available
    local notify_available = os.execute("which notify-send > /dev/null 2>&1")

    if notify_available then
        -- Create a simple notification command to use the system's notification
        -- This is a temporary solution until we can properly integrate with Wayland
        local escaped_text = text:gsub("'", "\\'") -- Escape single quotes
        local cmd = string.format("notify-send 'SomeWM' '%s'", escaped_text)
        
        -- Execute the command
        logger.debug("Executing system notification command: " .. cmd)
        local result = os.execute(cmd)
        
        if result then
            logger.info("System notification displayed successfully")
            return true
        else
            logger.error("Failed to execute notify-send command")
        end
    else
        -- Try an alternative method
        logger.warn("notify-send not available, trying alternative approach")
        
        -- Try zenity if available
        local zenity_available = os.execute("which zenity > /dev/null 2>&1")
        if zenity_available then
            local escaped_text = text:gsub('"', '\\"') -- Escape double quotes
            local cmd = string.format('zenity --info --title="SomeWM Widget" --text="%s" --timeout=5', escaped_text)
            logger.debug("Executing zenity command: " .. cmd)
            local result = os.execute(cmd .. " &")
            
            if result then
                logger.info("Zenity notification displayed successfully")
                return true
            else
                logger.error("Failed to execute zenity command")
            end
        else
            -- Try xmessage as a last resort
            local xmessage_available = os.execute("which xmessage > /dev/null 2>&1")
            if xmessage_available then
                local escaped_text = text:gsub('"', '\\"') -- Escape double quotes
                local cmd = string.format('xmessage -center "%s" -timeout 5', escaped_text)
                logger.debug("Executing xmessage command: " .. cmd)
                local result = os.execute(cmd .. " &")
                
                if result then
                    logger.info("xmessage notification displayed successfully")
                    return true
                else
                    logger.error("Failed to execute xmessage command")
                end
            else
                logger.error("No notification methods available (notify-send, zenity, or xmessage)")
                logger.error("Please install libnotify-bin, zenity, or x11-utils package")
            end
        end
    end
    
    -- As a last resort, try the display_message function
    return wayland_surface.display_message(text)
end

-- Function for a last-resort notification via dmenu or similar
function wayland_surface.display_message(text)
    logger.info("Attempting to display message: " .. text)
    
    -- Try dmenu if available
    local dmenu_available = os.execute("which dmenu > /dev/null 2>&1")
    if dmenu_available then
        local cmd = string.format("echo '%s' | dmenu -p 'SomeWM:'", text:gsub("'", "'\\''"))
        logger.debug("Executing dmenu command: " .. cmd)
        local result = os.execute(cmd .. " &")
        
        if result then
            logger.info("dmenu message displayed successfully")
            return true
        else
            logger.error("Failed to execute dmenu command")
        end
    else
        -- Try wmenu if available (Wayland version of dmenu)
        local wmenu_available = os.execute("which wmenu > /dev/null 2>&1")
        if wmenu_available then
            local cmd = string.format("echo '%s' | wmenu -p 'SomeWM:'", text:gsub("'", "'\\''"))
            logger.debug("Executing wmenu command: " .. cmd)
            local result = os.execute(cmd .. " &")
            
            if result then
                logger.info("wmenu message displayed successfully")
                return true
            else
                logger.error("Failed to execute wmenu command")
            end
        else
            -- Try rofi as a last resort
            local rofi_available = os.execute("which rofi > /dev/null 2>&1")
            if rofi_available then
                local cmd = string.format("echo '%s' | rofi -dmenu -p 'SomeWM:'", text:gsub("'", "'\\''"))
                logger.debug("Executing rofi command: " .. cmd)
                local result = os.execute(cmd .. " &")
                
                if result then
                    logger.info("rofi message displayed successfully")
                    return true
                else
                    logger.error("Failed to execute rofi command")
                end
            else
                logger.error("No message display methods available (dmenu, wmenu, or rofi)")
                logger.error("Please install at least one of these packages")
            end
        end
    end
    
    return false
end

-- Function to destroy a surface
function wayland_surface.destroy_widget_surface(surface_id)
    logger.info("Destroying wayland surface: " .. tostring(surface_id))
    -- In a real implementation, we would destroy the Wayland surface
    return true
end

return wayland_surface