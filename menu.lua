-- menu.lua
local ButtonTypes = require "button"
local Menu = {}
Menu.__index = Menu

function Menu.new()
    local self = setmetatable({}, Menu)
    self.currentMenu = "main"
    self.buttons = {}
    self.galleryPlayer = nil  -- Para a galeria de stage scenes
    self:loadMainMenu()
    return self
end

function Menu:loadMainMenu()
    self.currentMenu = "main"
    self.galleryPlayer = nil
    self.buttons = {
        ButtonTypes.Button.new(100, 100, 200, 50, "Novo Jogo", function() print("Iniciando novo jogo!") end),
        ButtonTypes.Button.new(100, 200, 200, 50, "Galeria", function() self:loadGalleryMenu() end),
        ButtonTypes.Button.new(100, 300, 200, 50, "Configurações", function() self:loadSettingsMenu() end),
        ButtonTypes.Button.new(100, 400, 200, 50, "Sair", function() love.event.quit() end)
    }
end

function Menu:loadGalleryMenu()
    self.currentMenu = "gallery"
    self.galleryPlayer = nil
    self.buttons = {
        ButtonTypes.Tab.new(50, 100, 150, 50, "Itens", function() print("Aba: Itens") end),
        ButtonTypes.Tab.new(250, 100, 150, 50, "Cenas de Fase", function() 
            -- Carrega a galeria de stage scenes
            self.galleryPlayer = require("stagescenegallery").new()
        end),
        ButtonTypes.Tab.new(450, 100, 150, 50, "Cutscenes", function() print("Aba: Cutscenes") end),
        ButtonTypes.Button.new(100, 400, 200, 50, "Voltar", function() self:loadMainMenu() end)
    }
end

function Menu:loadSettingsMenu()
    local Config = require "config"
    self.currentMenu = "settings"
    self.galleryPlayer = nil
    local fullscreenOn, fullscreenOff  -- pré-declaração
    
    fullscreenOn = ButtonTypes.Selector.new(100, 70, 90, 40, "On", function()
        Config.setFullscreen(true)
        fullscreenOn.selected = true
        fullscreenOff.selected = false
    end)
    
    fullscreenOff = ButtonTypes.Selector.new(200, 70, 90, 40, "Off", function()
        Config.setFullscreen(false)
        fullscreenOn.selected = false
        fullscreenOff.selected = true
    end)
    
    if Config.settings.fullscreen then
        fullscreenOn.selected = true
        fullscreenOff.selected = false
    else
        fullscreenOn.selected = false
        fullscreenOff.selected = true
    end
    
    local volumeSlider = ButtonTypes.VolumeSlider.new(100, 150, 200, 0, 1, Config.settings.volume, function(v)
        Config.setVolume(v)
    end)
    
    self.buttons = {
        fullscreenOn,
        fullscreenOff,
        volumeSlider,
        ButtonTypes.Button.new(100, 250, 200, 50, "Voltar", function() self:loadMainMenu() end)
    }
end

function Menu:update(dt)
    local mx, my = love.mouse.getPosition()
    if self.galleryPlayer then
        self.galleryPlayer:update(dt)
    else
        for _, button in ipairs(self.buttons) do
            if button.updateHover then button:updateHover(mx, my) end
            if button.update then button:update(dt) end
        end
    end
end

function Menu:draw()
    if self.galleryPlayer then
        self.galleryPlayer:draw()
    else
        if self.currentMenu == "settings" then
            love.graphics.setColor(1, 1, 1)
            love.graphics.print("Fullscreen", 100, 40)
            love.graphics.print("Volume", 100, 130)
        end
        for _, button in ipairs(self.buttons) do
            if button.draw then button:draw() end
        end
    end
end

function Menu:mousepressed(x, y, button)
    if self.galleryPlayer then
        self.galleryPlayer:mousepressed(x, y, button)
    else
        for _, btn in ipairs(self.buttons) do
            if btn.mousepressed then btn:mousepressed(x, y, button) end
        end
    end
end

function Menu:mousereleased(x, y, button)
    if self.galleryPlayer then
        self.galleryPlayer:mousereleased(x, y, button)
    else
        for _, btn in ipairs(self.buttons) do
            if btn.mousereleased then btn:mousereleased(x, y, button) end
        end
    end
end

return Menu