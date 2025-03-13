-- config.lua
--[[
    Manages game configurations and settings.
    Handles fullscreen toggling, volume settings, and other game options.
]]

local Save = require "save"
local ScreenUtils = require "screen_utils"

local Config = {}

-- Default settings
Config.settings = {
    fullscreen = false,
    volume = 1.0,
    lastWindowedWidth = 1024,
    lastWindowedHeight = 768
}

-- Toggles fullscreen mode
function Config.setFullscreen(value)
    -- Save current window dimensions before going fullscreen
    if Config.settings.fullscreen and not value then
        -- Getting out of fullscreen - use saved dimensions
        -- We don't do anything special here as LÖVE handles restoring from fullscreen
    elseif not Config.settings.fullscreen and value then
        -- Going to fullscreen - save current dimensions
        Config.settings.lastWindowedWidth, Config.settings.lastWindowedHeight = love.window.getMode()
    end
    
    -- Update setting
    Config.settings.fullscreen = value
    
    -- Apply fullscreen setting
    if value then
        -- Get desktop dimensions for proper fullscreen
        local desktopWidth, desktopHeight = love.window.getDesktopDimensions()
        love.window.setFullscreen(true, "desktop")
    else
        -- Restore windowed mode with previous dimensions
        love.window.setFullscreen(false)
        love.window.setMode(
            Config.settings.lastWindowedWidth, 
            Config.settings.lastWindowedHeight, 
            {
                resizable = true,
                vsync = true,
                minwidth = 640,
                minheight = 480
            }
        )
    end
    
    -- Save config
    Save.saveConfig(Config.settings)
    
    -- Update screen utilities with new dimensions
    local width, height = love.graphics.getDimensions()
    ScreenUtils.updateDimensions(width, height)
    
    -- Call resize handler directly to update UI
    love.resize(width, height)
end

-- Sets volume level
function Config.setVolume(value)
    Config.settings.volume = math.max(0, math.min(1, value))
    Save.saveConfig(Config.settings)
end

-- Loads saved configuration
function Config.load()
    local loadedSettings = Save.loadConfig()
    if loadedSettings then
        -- Apply loaded settings with defaults for missing values
        Config.settings = {
            fullscreen = loadedSettings.fullscreen or Config.settings.fullscreen,
            volume = loadedSettings.volume or Config.settings.volume,
            lastWindowedWidth = loadedSettings.lastWindowedWidth or Config.settings.lastWindowedWidth,
            lastWindowedHeight = loadedSettings.lastWindowedHeight or Config.settings.lastWindowedHeight
        }
        
        -- Apply fullscreen setting immediately
        if Config.settings.fullscreen then
            love.window.setFullscreen(true, "desktop")
        else
            -- Apply window dimensions from saved config
            love.window.setMode(
                Config.settings.lastWindowedWidth,
                Config.settings.lastWindowedHeight,
                {
                    resizable = true,
                    vsync = true,
                    minwidth = 640,
                    minheight = 480,
                    fullscreen = false
                }
            )
        end
    end
end

-- Returns current screen mode info
function Config.getScreenInfo()
    local width, height, flags = love.window.getMode()
    return {
        width = width,
        height = height,
        fullscreen = flags.fullscreen,
        fullscreenType = flags.fullscreentype,
        vsync = flags.vsync,
        display = flags.display
    }
end

-- Center window on screen
function Config.centerWindow()
    if not Config.settings.fullscreen then
        local desktopWidth, desktopHeight = love.window.getDesktopDimensions()
        local windowWidth, windowHeight = love.window.getMode()
        
        love.window.setPosition(
            (desktopWidth - windowWidth) / 2,
            (desktopHeight - windowHeight) / 2
        )
    end
end

return Config