-- menu.lua
local ButtonTypes = require "button"
local ScreenUtils = require "screen_utils"
local Menu = {}
Menu.__index = Menu

function Menu.new()
    local self = setmetatable({}, Menu)
    self.currentMenu = "main"
    self.buttons = {}
    self.galleryPlayer = nil  -- Gallery viewer
    self:loadMainMenu()
    return self
end

function Menu:loadMainMenu()
    self.currentMenu = "main"
    self.galleryPlayer = nil
    
    -- Fixed button sizes - will be scaled by screen utils
    local baseButtonWidth = 200
    local baseButtonHeight = 50
    local buttonSpacing = 70 -- Vertical space between buttons
    
    -- Calculate scaled sizes
    local buttonWidth, buttonHeight = ScreenUtils.getUIElementSize(baseButtonWidth, baseButtonHeight)
    
    -- Calculate starting position (20% from top)
    local startY = ScreenUtils.height * 0.2
    
    -- Menu options - positioned using screen utilities
    self.buttons = {
        ButtonTypes.Button.new(
            ScreenUtils.centerElement(buttonWidth, buttonHeight),
            startY, 
            buttonWidth, 
            buttonHeight, 
            "Novo Jogo", 
            function() 
                -- Load intro cutscene instead of starting game directly
                self.cutscenePlayer = require("cutscenes").new("cutscenes/intro")
                
                -- Set completion callback
                self.cutscenePlayer.onComplete = function()
                    -- If no level was selected, return to menu
                    if not self.cutscenePlayer.selectedLevel then
                        self:loadMainMenu()
                    end
                end
                
                -- Start cutscene
                if self.cutscenePlayer:load() then
                    self.currentMenu = "cutscene"
                else
                    print("Failed to load intro cutscene")
                end
            end
        ),
        ButtonTypes.Button.new(
            ScreenUtils.centerElement(buttonWidth, buttonHeight),
            startY + buttonSpacing, 
            buttonWidth, 
            buttonHeight, 
            "Galeria", 
            function() self:loadGalleryMenu() end
        ),
        ButtonTypes.Button.new(
            ScreenUtils.centerElement(buttonWidth, buttonHeight),
            startY + buttonSpacing * 2, 
            buttonWidth, 
            buttonHeight, 
            "Configurações", 
            function() self:loadSettingsMenu() end
        ),
        ButtonTypes.Button.new(
            ScreenUtils.centerElement(buttonWidth, buttonHeight),
            startY + buttonSpacing * 3, 
            buttonWidth, 
            buttonHeight, 
            "Sair", 
            function() love.event.quit() end
        )
    }
end

function Menu:loadGalleryMenu()
    self.currentMenu = "gallery"
    -- Use GaleryManager instead of StageSceneGallery
    self.galleryPlayer = require("galeryManager").new()
    self.buttons = {} -- Clear previous buttons
    self.tabs = {}    -- Clear previous tabs
    
    -- Tab dimensions
    local tabWidth = ScreenUtils.scaleValue(150)
    local tabHeight = ScreenUtils.scaleValue(40)
    local tabSpacing = ScreenUtils.scaleValue(20)
    local totalTabsWidth = (tabWidth * 3) + (tabSpacing * 2)
    
    -- Calculate tab starting position
    local startX = (ScreenUtils.width - totalTabsWidth) / 2
    local tabY = ScreenUtils.scaleValue(100)
    
    -- Create container for tabs
    self.tabs = {}
    
    -- Function to deselect all tabs
    local function deselectAllTabs()
        for _, tab in ipairs(self.tabs) do
            tab.selected = false
        end
    end

    -- Create tabs
    local tabsData = {
        {label = "Itens", tabName = "items"},
        {label = "Cenas de Fase", tabName = "stage"}, 
        {label = "Cutscenes", tabName = "cutscenes"}
    }

    for i, data in ipairs(tabsData) do
        local tabIndex = i -- Capture current index
        local tab = ButtonTypes.Tab.new(
            startX + ((tabWidth + tabSpacing) * (i-1)),
            tabY,
            tabWidth,
            tabHeight,
            data.label,
            function()
                deselectAllTabs()
                self.tabs[tabIndex].selected = true -- Access by table
                self.galleryPlayer.currentTab = data.tabName
                self.galleryPlayer:refreshIcons()
            end
        )
        table.insert(self.tabs, tab)
        table.insert(self.buttons, tab)
    end

    -- Select default tab initially
    self.tabs[2].selected = true  -- "Cenas de Fase"
    self.galleryPlayer.currentTab = "stage"
    
    -- Add back button
    local backButtonWidth, backButtonHeight = ScreenUtils.getUIElementSize(200, 50)
    table.insert(self.buttons, ButtonTypes.Button.new(
        ScreenUtils.centerElement(backButtonWidth, backButtonHeight, 0, ScreenUtils.height * 0.4),
        ScreenUtils.height - backButtonHeight - ScreenUtils.scaleValue(50), 
        backButtonWidth, 
        backButtonHeight, 
        "Voltar", 
        function() self:loadMainMenu() end
    ))
    
    self.galleryPlayer:refreshIcons()
end

function Menu:loadSettingsMenu()
    local Config = require "config"
    self.currentMenu = "settings"
    self.galleryPlayer = nil
    
    -- Calculate element sizes
    local elementWidth, elementHeight = ScreenUtils.getUIElementSize(200, 50)
    local toggleWidth, toggleHeight = ScreenUtils.getUIElementSize(90, 40)
    local verticalSpacing = ScreenUtils.scaleValue(80)
    
    -- Fullscreen group
    local fullscreenGroupWidth = toggleWidth * 2 + ScreenUtils.scaleValue(20)
    local fullscreenX = (ScreenUtils.width - fullscreenGroupWidth) / 2
    local groupY = verticalSpacing
    
    fullscreenOn = ButtonTypes.Selector.new(
        fullscreenX, 
        groupY, 
        toggleWidth, 
        toggleHeight, 
        "On", 
        function()
            Config.setFullscreen(true)
            fullscreenOn.selected = true
            fullscreenOff.selected = false
        end
    )
    
    fullscreenOff = ButtonTypes.Selector.new(
        fullscreenX + toggleWidth + ScreenUtils.scaleValue(20), 
        groupY, 
        toggleWidth, 
        toggleHeight, 
        "Off", 
        function()
            Config.setFullscreen(false)
            fullscreenOn.selected = false
            fullscreenOff.selected = true
        end
    )

    -- Volume slider
    local sliderWidth = ScreenUtils.scaleValue(200)
    local sliderX = (ScreenUtils.width - sliderWidth) / 2
    local volumeSlider = ButtonTypes.VolumeSlider.new(
        sliderX,
        groupY + verticalSpacing,
        sliderWidth,
        0, 1, 
        Config.settings.volume, 
        function(v) Config.setVolume(v) end
    )

    -- Back button
    local backButtonY = ScreenUtils.height - elementHeight - ScreenUtils.scaleValue(50)
    self.buttons = {
        fullscreenOn,
        fullscreenOff,
        volumeSlider,
        ButtonTypes.Button.new(
            (ScreenUtils.width - elementWidth) / 2, 
            backButtonY, 
            elementWidth, 
            elementHeight, 
            "Voltar", 
            function() self:loadMainMenu() end
        )
    }

    -- Set initial state
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
    
    if self.currentMenu == "cutscene" and self.cutscenePlayer then
        -- Update cutscene
        self.cutscenePlayer:update(dt)
        
        -- Check if cutscene has ended and selected a level
        if not self.cutscenePlayer.isActive then
            if self.cutscenePlayer.selectedLevel then
                -- Cutscene ended and selected a level, load it
                if not self.gameInstance then
                    self.gameInstance = require("game").new()
                end
                
                -- Configure circle position
                self.gameInstance:setCirclePosition(0.8, 0.8)
                
                -- Load selected level
                local levelPath = self.cutscenePlayer.selectedLevel
                
                -- Ensure path doesn't have duplicated extension
                if levelPath:sub(-4) ~= ".lua" then
                    levelPath = levelPath -- Keep as is
                end
                
                if self.gameInstance:loadLevel(levelPath) then
                    self.currentMenu = "gameplay"
                else
                    print("Failed to load level: " .. tostring(levelPath))
                    self:loadMainMenu()
                end
            else
                -- Cutscene ended without selecting a level, return to main menu
                self:loadMainMenu()
            end
            
            -- Clear cutscene reference
            self.cutscenePlayer = nil
        end

    elseif self.currentMenu == "gameplay" and self.gameInstance then
        -- Existing gameplay update code
        local result = self.gameInstance:update(dt)
        
        -- If level ends or user exits, return to menu
        if result == "menu" or result == "fase_concluida" then
            self:loadMainMenu()
        end
    elseif self.currentMenu == "gallery" and self.galleryPlayer then
        -- Update gallery
        self.galleryPlayer:update(dt)
        
        -- Update gallery buttons when not viewing content
        if not self.galleryPlayer.currentScene then
            for _, button in ipairs(self.buttons) do
                if button.updateHover then button:updateHover(mx, my) end
                if button.update then button:update(dt) end
            end
        end
    else
        -- Update buttons for other menus
        for _, button in ipairs(self.buttons) do
            if button.updateHover then button:updateHover(mx, my) end
            if button.update then button:update(dt) end
        end
    end
end

function Menu:draw()
    if self.currentMenu == "cutscene" then
        if not self.cutscenePlayer then
            -- Cutscene was removed, return to main menu
            self:loadMainMenu()
            -- Draw main menu meanwhile
            for _, button in ipairs(self.buttons) do
                if button.draw then button:draw() end
            end
            return
        elseif not self.cutscenePlayer.isActive then
            -- Cutscene finished but we haven't updated menu yet
            -- This case should be handled by update() before we get here
            return
        else
            -- Cutscene is active, draw it
            self.cutscenePlayer:draw()
        end
    elseif self.currentMenu == "gameplay" and self.gameInstance then
        -- Draw the game when in gameplay state
        self.gameInstance:draw()
    elseif self.currentMenu == "gallery" and self.galleryPlayer then
        -- Draw background for gallery
        love.graphics.setColor(0.1, 0.1, 0.1, 1)
        love.graphics.rectangle("fill", 0, 0, ScreenUtils.width, ScreenUtils.height)
        
        -- Draw gallery title
        love.graphics.setColor(1, 1, 1, 1)
        local font = love.graphics.getFont()
        local title = "Galeria de Conteúdo"
        local titleWidth = font:getWidth(title)
        love.graphics.print(title, (ScreenUtils.width - titleWidth) / 2, ScreenUtils.scaleValue(20))
        
        -- Viewing mode or gallery mode
        if self.galleryPlayer.currentScene then
            -- Content viewing mode
            self.galleryPlayer:draw()
        else
            -- Gallery browsing mode
            -- Draw tab buttons and back button
            for _, button in ipairs(self.buttons) do
                button:draw()
            end
            
            -- Draw gallery icons
            for _, icon in ipairs(self.galleryPlayer.icons) do
                icon:draw()
            end
            
            -- Show message if no content available
            if #self.galleryPlayer.icons == 0 then
                love.graphics.setColor(0.7, 0.7, 0.7, 1)
                local msg = "Nenhum conteúdo disponível nesta categoria"
                local msgWidth = font:getWidth(msg)
                love.graphics.print(
                    msg, 
                    (ScreenUtils.width - msgWidth) / 2, 
                    ScreenUtils.height / 2
                )
            end
        end
    else
        -- Draw other menus
        if self.currentMenu == "settings" then
            love.graphics.setColor(1, 1, 1)
            
            -- Calculate title positions
            local titles = {
                {text = "Fullscreen", y = ScreenUtils.scaleValue(50)},
                {text = "Volume", y = ScreenUtils.scaleValue(130)}
            }
            
            -- Draw setting titles
            for _, title in ipairs(titles) do
                local font = love.graphics.getFont()
                local textWidth = font:getWidth(title.text)
                love.graphics.print(title.text, (ScreenUtils.width - textWidth)/2, title.y)
            end
        end
        
        -- Draw current menu buttons
        for _, button in ipairs(self.buttons) do
            if button.draw then button:draw() end
        end
    end
end

function Menu:mousepressed(x, y, button)
    if self.currentMenu == "cutscene" and self.cutscenePlayer then
        -- Pass event to cutscene
        self.cutscenePlayer:mousepressed(x, y, button)
    elseif self.currentMenu == "gameplay" and self.gameInstance then
        -- Pass mouse events to game
        self.gameInstance:mousepressed(x, y, button)
    elseif self.currentMenu == "gallery" and self.galleryPlayer then
        -- Pass event to gallery manager
        self.galleryPlayer:mousepressed(x, y, button)
        
        -- Process menu buttons if not viewing content
        if not self.galleryPlayer.currentScene then
            for _, btn in ipairs(self.buttons) do
                if btn.mousepressed then
                    btn:mousepressed(x, y, button)
                end
            end
        end
    else
        -- Other menus
        for _, btn in ipairs(self.buttons) do
            if btn.mousepressed then
                btn:mousepressed(x, y, button)
            end
        end
    end
end

function Menu:mousereleased(x, y, button)
    if self.galleryPlayer and self.galleryPlayer.mousereleased then
        self.galleryPlayer:mousereleased(x, y, button)
    else
        for _, btn in ipairs(self.buttons) do
            if btn.mousereleased then 
                btn:mousereleased(x, y, button) 
            end
        end
    end
end

function Menu:keypressed(key)
    if self.currentMenu == "cutscene" and self.cutscenePlayer then
        -- Pass event to cutscene
        self.cutscenePlayer:keypressed(key)
    elseif self.currentMenu == "gameplay" and self.gameInstance then
        -- Pass keyboard events to game
        self.gameInstance:keypressed(key)
    elseif self.currentMenu == "gallery" and self.galleryPlayer and self.galleryPlayer.keypressed then
        -- Pass keyboard events to gallery
        self.galleryPlayer:keypressed(key)
    end
end

-- Handle window resize
function Menu:resize(w, h)
    -- Recreate current menu with new dimensions
    if self.currentMenu == "main" then
        self:loadMainMenu()
    elseif self.currentMenu == "gallery" then
        self:loadGalleryMenu()
    elseif self.currentMenu == "settings" then
        self:loadSettingsMenu()
    end
    
    -- Notify game instance if it exists
    if self.gameInstance and self.gameInstance.resize then
        self.gameInstance:resize(w, h)
    end
    
    -- Notify gallery if it exists
    if self.galleryPlayer and self.galleryPlayer.resize then
        self.galleryPlayer:resize(w, h)
    end
end

return Menu