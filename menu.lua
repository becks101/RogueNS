-- menu.lua
local ButtonTypes = require "button"
local Menu = {}
Menu.__index = Menu

function Menu.new()
    local self = setmetatable({}, Menu)
    self.currentMenu = "main"
    self.buttons = {}
    self.galleryPlayer = nil  -- Para a galeria (agora mais genérica)
    self:loadMainMenu()
    return self
end

function Menu:loadMainMenu()
    self.currentMenu = "main"
    self.galleryPlayer = nil
    local screenWidth, screenHeight = love.graphics.getDimensions()
    
    -- Posicionamento responsivo
    local buttonWidth = 200
    local buttonHeight = 50
    local startY = screenHeight * 0.2  -- 20% da altura
    
    self.buttons = {
        ButtonTypes.Button.new((screenWidth - buttonWidth)/2, startY, buttonWidth, buttonHeight, "Novo Jogo", function() print("Iniciando novo jogo!") end),
        ButtonTypes.Button.new((screenWidth - buttonWidth)/2, startY + 100, buttonWidth, buttonHeight, "Galeria", function() self:loadGalleryMenu() end),
        ButtonTypes.Button.new((screenWidth - buttonWidth)/2, startY + 200, buttonWidth, buttonHeight, "Configurações", function() self:loadSettingsMenu() end),
        ButtonTypes.Button.new((screenWidth - buttonWidth)/2, startY + 300, buttonWidth, buttonHeight, "Sair", function() love.event.quit() end)
    }
end

function Menu:loadGalleryMenu()
    self.currentMenu = "gallery"
    -- Usa o novo GaleryManager em vez de stagescenegallery
    self.galleryPlayer = require("galeryManager").new()
    self.buttons = {} -- Limpa os botões anteriores
    self.tabs = {}    -- Limpa as abas anteriores
    
    local screenWidth = love.graphics.getDimensions()
    local tabWidth = 150
    local tabSpacing = 20
    local totalTabsWidth = (tabWidth * 3) + (tabSpacing * 2)
    local startX = (screenWidth - totalTabsWidth)/2

    -- Cria container para as abas
    self.tabs = {}
    
    -- Função para desselecionar todas as abas
    local function deselectAllTabs()
        for _, tab in ipairs(self.tabs) do
            tab.selected = false
        end
    end

    -- Cria as abas
    local tabsData = {
        {label = "Itens", tabName = "items"},
        {label = "Cenas de Fase", tabName = "stage"}, 
        {label = "Cutscenes", tabName = "cutscenes"}
    }

    for i, data in ipairs(tabsData) do
        local tabIndex = i -- Captura o índice atual
        local tab = ButtonTypes.Tab.new(
            startX + ((tabWidth + tabSpacing) * (i-1)),
            100,
            tabWidth,
            50,
            data.label,
            function()
                deselectAllTabs()
                self.tabs[tabIndex].selected = true -- Acessa pela tabela
                self.galleryPlayer.currentTab = data.tabName
                self.galleryPlayer:refreshIcons()
            end
        )
        table.insert(self.tabs, tab)
        table.insert(self.buttons, tab)
    end

    -- Seleciona a aba padrão inicialmente
    self.tabs[2].selected = true  -- "Cenas de Fase"
    self.galleryPlayer.currentTab = "stage"
    
    -- Adiciona botão voltar
    table.insert(self.buttons, ButtonTypes.Button.new(
        (screenWidth - 200)/2, 
        love.graphics.getHeight() - 100, 
        200, 50, 
        "Voltar", 
        function() self:loadMainMenu() end
    ))
    
    self.galleryPlayer:refreshIcons()
end

function Menu:loadSettingsMenu()
    local Config = require "config"
    self.currentMenu = "settings"
    self.galleryPlayer = nil
    local screenWidth, screenHeight = love.graphics.getDimensions()
    
    -- Elementos centralizados
    local elementWidth = 200
    local startX = (screenWidth - elementWidth) / 2
    local verticalSpacing = 80
    
    -- Grupo Fullscreen
    local fullscreenGroupWidth = 190
    local fullscreenX = (screenWidth - fullscreenGroupWidth) / 2
    
    fullscreenOn = ButtonTypes.Selector.new(
        fullscreenX, 
        verticalSpacing, 
        90, 40, "On", function()
            Config.setFullscreen(true)
            fullscreenOn.selected = true
            fullscreenOff.selected = false
        end
    )
    
    fullscreenOff = ButtonTypes.Selector.new(
        fullscreenX + 100, 
        verticalSpacing, 
        90, 40, "Off", function()
            Config.setFullscreen(false)
            fullscreenOn.selected = false
            fullscreenOff.selected = false
        end
    )

    -- Slider de Volume
    local sliderWidth = 200
    local sliderX = (screenWidth - sliderWidth) / 2
    local volumeSlider = ButtonTypes.VolumeSlider.new(
        sliderX,
        verticalSpacing + 80,
        sliderWidth,
        0, 1, 
        Config.settings.volume, 
        function(v) Config.setVolume(v) end
    )

    -- Botão Voltar
    local backButtonY = screenHeight - 100
    self.buttons = {
        fullscreenOn,
        fullscreenOff,
        volumeSlider,
        ButtonTypes.Button.new(
            (screenWidth - elementWidth)/2, 
            backButtonY, 
            elementWidth, 50, 
            "Voltar", 
            function() self:loadMainMenu() end
        )
    }

    -- Estado inicial
    if Config.settings.fullscreen then
        fullscreenOn.selected = true
        fullscreenOff.selected = false
    else
        fullscreenOn.selected = false
        fullscreenOff.selected = true
    end
end


function Menu:update(dt)
    local mx, my = love.mouse.getPosition()
    
    if self.currentMenu == "gallery" and self.galleryPlayer then
        if self.galleryPlayer.currentScene then
            -- Modo visualização de cena: atualiza apenas a cena e botão voltar
            self.galleryPlayer:update(dt)
        else
            -- Modo galeria normal: atualiza ícones e botões das abas
            for _, icon in ipairs(self.galleryPlayer.icons) do
                icon:updateHover(mx, my)
            end
            for _, button in ipairs(self.buttons) do
                if button.updateHover then button:updateHover(mx, my) end
                if button.update then button:update(dt) end
            end
        end
    else
        -- Atualiza outros menus
        for _, button in ipairs(self.buttons) do
            if button.updateHover then button:updateHover(mx, my) end
            if button.update then button:update(dt) end
        end
    end
end

function Menu:draw()
    if self.currentMenu == "gallery" and self.galleryPlayer then
        if self.galleryPlayer.currentScene then
            -- Modo visualização da cena
            self.galleryPlayer:draw()
        else
            -- Modo galeria normal
            for _, icon in ipairs(self.galleryPlayer.icons) do
                icon:draw()
            end
            for _, button in ipairs(self.buttons) do
                button:draw()
            end
        end
    else
        -- Desenha outros menus
        if self.currentMenu == "settings" then
            love.graphics.setColor(1, 1, 1)
            local screenWidth = love.graphics.getDimensions()
            
            local titles = {
                {text = "Fullscreen", y = 50},
                {text = "Volume", y = 130}
            }
            
            for _, title in ipairs(titles) do
                local font = love.graphics.getFont()
                local textWidth = font:getWidth(title.text)
                love.graphics.print(title.text, (screenWidth - textWidth)/2, title.y)
            end
        end
        
        -- Desenha botões do menu atual
        for _, button in ipairs(self.buttons) do
            if button.draw then button:draw() end
        end
    end
end


function Menu:mousepressed(x, y, button)
    if self.currentMenu == "gallery" and self.galleryPlayer then
        if self.galleryPlayer.currentScene then
            -- Modo visualização de cena: passa o evento para o galeryManager
            if self.galleryPlayer.mousepressed then
                self.galleryPlayer:mousepressed(x, y, button)
            end
        else
            -- Modo galeria: processa ícones e botões das abas
            for _, icon in ipairs(self.galleryPlayer.icons) do
                icon:mousepressed(x, y, button)
            end
            for _, btn in ipairs(self.buttons) do
                if btn.mousepressed then
                    btn:mousepressed(x, y, button)
                end
            end
        end
    else
        -- Outros menus
        for _, btn in ipairs(self.buttons) do
            if btn.mousepressed then
                btn:mousepressed(x, y, button)
            end
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

function Menu:keypressed(key)
    -- Adicionar suporte para eventos de teclado, necessário para cutscenes
    if self.currentMenu == "gallery" and self.galleryPlayer and self.galleryPlayer.keypressed then
        self.galleryPlayer:keypressed(key)
    end
end

return Menu