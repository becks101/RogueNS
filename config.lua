-- config.lua
local Config = {}
local Save = require "save"

Config.settings = {
    fullscreen = false,
    volume = 1.0
}

function Config.setFullscreen(value)
    Config.settings.fullscreen = value
    love.window.setFullscreen(value)
    Save.saveConfig(Config.settings)
    love.resize(love.graphics.getWidth(), love.graphics.getHeight())  -- Forçar redimensionamento
end

function Config.setVolume(value)
    Config.settings.volume = math.max(0, math.min(1, value))
    Save.saveConfig(Config.settings)
end

function Config.load()
    local loadedSettings = Save.loadConfig()
    if loadedSettings then
        Config.settings = loadedSettings
        love.window.setFullscreen(Config.settings.fullscreen)
    end
end

return Config