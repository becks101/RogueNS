local Config = require "config"
local Menu = require "menu"

function love.load()
    -- Carrega as configurações salvas (ex.: fullscreen, volume, etc.)
    Config.load()
    menu = Menu.new()
end

function love.update(dt)
    menu:update(dt)
end

function love.draw()
    menu:draw()
end

function love.mousepressed(x, y, button, istouch, presses)
    menu:mousepressed(x, y, button)
end

function love.mousereleased(x, y, button)
    menu:mousereleased(x, y, button)
end
