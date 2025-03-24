-- galeryManager.lua
--[[
    Gallery manager module that handles displaying and interacting with
    different types of unlocked content:
    - Stage scenes
    - Cutscenes
    - Items
    - Levels
]]

local StageScene = require("stagescenes")
local Cutscenes = require("cutscenes")
local ButtonTypes = require("button")
local ScreenUtils = require("screen_utils")
local GaleryIcons = ButtonTypes.GaleryIcons

local GaleryManager = {}
GaleryManager.__index = GaleryManager

-- Creates a new gallery manager instance
function GaleryManager.new()
    local self = setmetatable({}, GaleryManager)
    
    -- Initialize with default tab
    self.currentTab = "stage"
    
    -- Content lists by category
    self.stageScenesList = {"stages/ss_mast01"}
    self.cutscenesList = {"cutscenes/intro", "cutscenes/chapter1"}
    self.itemsList = {"items/item1", "items/item2"}
    self.levelsList = {"levels/tutorial", "levels/exemploDeFase01"}
    
    self.icons = {}
    self.currentScene = nil -- Currently active scene (stage scene or cutscene)
    self.sceneType = nil    -- Type of current scene ("stage", "cutscene", or "level")
    self.currentLevel = nil -- Current level when viewing a level
    
    -- Back button for returning from content view
    local backBtnWidth, backBtnHeight = ScreenUtils.getUIElementSize(100, 40)
    self.backButton = ButtonTypes.Button.new(
        ScreenUtils.scaleValue(20), 
        ScreenUtils.scaleValue(20), 
        backBtnWidth, 
        backBtnHeight, 
        "Voltar", 
        function()
            self.currentScene = nil
            self.sceneType = nil
            self.currentLevel = nil
        end
    )
    
    -- Play button for levels
    local playBtnWidth, playBtnHeight = ScreenUtils.getUIElementSize(120, 40)
    self.playButton = ButtonTypes.Button.new(
        ScreenUtils.width - ScreenUtils.scaleValue(140), 
        ScreenUtils.scaleValue(20), 
        playBtnWidth, 
        playBtnHeight, 
        "Jogar Fase", 
        function()
            if self.currentLevel and self.sceneType == "level" then
                -- Obter o objeto Menu pai (assumindo que está acessível globalmente ou via upvalue)
                local menu = _G.currentMenu
                
                if menu and menu.startLevelFromGallery then
                    -- Prepara o caminho do nível (nível atual)
                    local levelPath
                    for _, path in ipairs(self.levelsList) do
                        local success, level = pcall(require, path)
                        if success and level == self.currentLevel then
                            levelPath = path
                            break
                        end
                    end
                    
                    if levelPath then
                        menu:startLevelFromGallery(levelPath)
                    else
                        print("Não foi possível determinar o caminho do nível")
                    end
                else
                    print("Menu não disponível ou método startLevelFromGallery não implementado")
                end
            end
        end
    )
    
    -- Carregar a lista de fases disponíveis
    self:loadAvailableLevels()
    
    -- Populate initial icons
    self:refreshIcons()
    
    return self
end

-- Refreshes icons based on current tab selection
function GaleryManager:refreshIcons()
    self.icons = {} -- Reset icons
    
    -- Calculate icon dimensions and spacing
    local iconSize = ScreenUtils.scaleValue(80)
    local spacingX = ScreenUtils.scaleValue(120)
    local spacingY = ScreenUtils.scaleValue(120)
    local startY = ScreenUtils.scaleValue(150)
    
    -- Get number of columns based on screen width
    local cols = ScreenUtils.getGridColumns(iconSize, spacingX, 2, 6)
    
    -- Calculate starting X to center the grid
    local gridWidth = cols * spacingX
    local startX = (ScreenUtils.width - gridWidth) / 2 + spacingX/2
    
    -- Get current content list based on active tab
    local currentList = {}
    if self.currentTab == "stage" then
        currentList = self.stageScenesList
    elseif self.currentTab == "cutscenes" then
        currentList = self.cutscenesList
    elseif self.currentTab == "items" then
        currentList = self.itemsList
    elseif self.currentTab == "levels" then
        currentList = self.levelsList
    end
    
    -- Create icons for current list items
    for i, moduleName in ipairs(currentList) do
        local col = (i - 1) % cols
        local row = math.floor((i - 1) / cols)
        
        -- Calculate grid position
        local x, y = ScreenUtils.gridPosition(col, row, iconSize, iconSize, spacingX, startX, startY)
        
        -- Try to load module data
        local success, itemData = pcall(require, moduleName)
        if success then
            -- Ensure icon path exists or use default
            local iconPath = itemData.IconeLarge or "assets/icons/default.png"
            
            -- Verify icon file exists
            local fileInfo = love.filesystem.getInfo(iconPath)
            if not fileInfo then
                print("Warning: Icon not found: " .. iconPath)
                iconPath = "assets/icons/default.png" -- Use default icon
            end
            
            -- Create icon with appropriate callback
            local icon = GaleryIcons.new(
                x, y,
                iconPath,
                itemData.nome or "Unnamed item",
                function()
                    -- Different behavior based on content type
                    if self.currentTab == "stage" then
                        self:loadStageScene(moduleName)
                    elseif self.currentTab == "cutscenes" then
                        self:loadCutscene(moduleName)
                    elseif self.currentTab == "items" then
                        print("Item viewer not implemented yet")
                    elseif self.currentTab == "levels" then
                        self:loadLevel(moduleName)
                    end
                end
            )
            
            -- Apply scaling based on screen size
            icon.normalScale = ScreenUtils.scale * 0.8
            icon.hoverScale = icon.normalScale * 1.1
            icon.currentScale = icon.normalScale
            
            table.insert(self.icons, icon)
        else
            print("Error loading item:", moduleName, itemData)
        end
    end
end

-- Loads a stage scene
function GaleryManager:loadStageScene(moduleName)
    self.currentScene = StageScene.new(moduleName)
    self.sceneType = "stage"
    
    if not self.currentScene:load() then
        print("Error loading stage scene:", moduleName)
        self.currentScene = nil
        self.sceneType = nil
        return false
    end
    
    return true
end

-- Loads a cutscene
function GaleryManager:loadCutscene(moduleName)
    self.currentScene = Cutscenes.new(moduleName)
    self.sceneType = "cutscene"
    
    if not self.currentScene:load() then
        print("Error loading cutscene:", moduleName)
        self.currentScene = nil
        self.sceneType = nil
        return false
    end
    
    return true
end

-- Loads a level preview
function GaleryManager:loadLevel(moduleName)
    -- Remove file extension if present
    local moduleName = moduleName
    if moduleName:sub(-4) == ".lua" then
        moduleName = moduleName:sub(1, -5)
    end
    
    -- Try to load level module
    local success, level = pcall(require, moduleName)
    if not success then
        print("Error loading level:", moduleName, level)
        return false
    end
    
    -- Store the level data
    self.currentLevel = level
    
    -- Load the level's stage scene animation if available
    if level.animation then
        -- Load stage scene for visualization
        self.currentScene = StageScene.new(level.animation)
        if not self.currentScene:load() then
            print("Error loading level stage scene:", level.animation)
            self.currentScene = nil
            self.currentLevel = nil
            return false
        end
    else
        -- No animation defined, create a placeholder scene
        self.currentScene = {
            update = function(_, dt) end,
            draw = function(_)
                -- Draw placeholder background
                love.graphics.setColor(0.2, 0.2, 0.3)
                love.graphics.rectangle("fill", 0, 0, ScreenUtils.width, ScreenUtils.height)
                
                -- Draw text placeholder
                love.graphics.setColor(1, 1, 1)
                local font = love.graphics.getFont()
                love.graphics.printf(
                    "Visualização não disponível para esta fase", 
                    0, ScreenUtils.height/2 - 20, 
                    ScreenUtils.width, "center"
                )
            end
        }
    end
    
    self.sceneType = "level"
    return true
end

-- Updates gallery state
function GaleryManager:update(dt)
    -- Get mouse position for hover calculations
    local mx, my = love.mouse.getPosition()
    
    if self.currentScene then
        -- Update active scene if any
        if self.currentScene.update then
            self.currentScene:update(dt)
        end
        
        -- Update back button hover state
        self.backButton:updateHover(mx, my)
        
        -- Update play button if viewing a level
        if self.sceneType == "level" then
            self.playButton:updateHover(mx, my)
        end
    else
        -- Update icons when not viewing a scene
        for _, icon in ipairs(self.icons) do
            if icon.updateHover then
                icon:updateHover(mx, my)
            end
            
            -- Update animation timers if implemented
            if icon.update then
                icon:update(dt)
            end
        end
    end
end

-- Draws the gallery
function GaleryManager:draw()
    if self.currentScene then
        -- Draw active scene
        if self.currentScene.draw then
            self.currentScene:draw()
        end
        
        -- Always draw back button over scene
        self.backButton:draw()
        
        -- Draw play button and level info if viewing a level
        if self.sceneType == "level" and self.currentLevel then
            -- Draw play button
            self.playButton:draw()
            
            -- Draw level info panel
            love.graphics.setColor(0, 0, 0, 0.7)
            local infoWidth = ScreenUtils.scaleValue(300)
            local infoHeight = ScreenUtils.scaleValue(200)
            local infoX = ScreenUtils.width/2 - infoWidth/2
            local infoY = ScreenUtils.height - infoHeight - ScreenUtils.scaleValue(20)
            
            -- Draw info box
            love.graphics.rectangle("fill", infoX, infoY, infoWidth, infoHeight, 10, 10)
            
            -- Draw level info text
            love.graphics.setColor(1, 1, 1)
            local fontSize = ScreenUtils.scaleFontSize(14)
            local font = love.graphics.newFont(fontSize)
            love.graphics.setFont(font)
            
            local textY = infoY + ScreenUtils.scaleValue(20)
            local padding = ScreenUtils.scaleValue(15)
            
            -- Level name
            love.graphics.print("Nome: " .. (self.currentLevel.nome or "Sem nome"), 
                infoX + padding, textY)
            textY = textY + fontSize * 1.5
            
            -- BPM
            if self.currentLevel.bpm then
                love.graphics.print("BPM: " .. self.currentLevel.bpm, 
                    infoX + padding, textY)
                textY = textY + fontSize * 1.5
            end
            
            -- Duration
            if self.currentLevel.duracao then
                love.graphics.print("Duração: " .. self.currentLevel.duracao .. " segundos", 
                    infoX + padding, textY)
                textY = textY + fontSize * 1.5
            end
            
            -- Difficulty
            if self.currentLevel.dificuldade then
                love.graphics.print("Dificuldade: " .. self.currentLevel.dificuldade, 
                    infoX + padding, textY)
                textY = textY + fontSize * 1.5
            end
            
            -- Number of achievements
            if self.currentLevel.achievements then
                love.graphics.print("Conquistas: " .. #self.currentLevel.achievements, 
                    infoX + padding, textY)
            end
        end
    else
        -- Draw gallery icons
        for _, icon in ipairs(self.icons) do
            icon:draw()
        end
    end
end

-- Handles mouse press events
function GaleryManager:mousepressed(x, y, button)
    if self.currentScene then
        -- Only back button is active during scene viewing
        self.backButton:mousepressed(x, y, button)
        
        -- Play button is active only when viewing a level
        if self.sceneType == "level" then
            self.playButton:mousepressed(x, y, button)
        end
        
        -- Pass event to cutscene if needed
        if self.sceneType == "cutscene" and self.currentScene.mousepressed then
            self.currentScene:mousepressed(x, y, button)
        end
    else
        -- Process gallery icon clicks
        for _, icon in ipairs(self.icons) do
            if icon.mousepressed then
                icon:mousepressed(x, y, button)
            end
        end
    end
end

-- Handles mouse release events
function GaleryManager:mousereleased(x, y, button)
    if self.currentScene and self.currentScene.mousereleased then
        self.currentScene:mousereleased(x, y, button)
    end
end

-- Handles keyboard events
function GaleryManager:keypressed(key)
    if self.currentScene and self.sceneType == "cutscene" then
        -- Cutscenes need keyboard events to advance
        if self.currentScene.keypressed then
            self.currentScene:keypressed(key)
        end
    end
    
    -- Sair da visualização com ESC
    if key == "escape" and self.currentScene then
        self.currentScene = nil
        self.sceneType = nil
        self.currentLevel = nil
    end
end

-- Load available levels
function GaleryManager:loadAvailableLevels()
    -- Create the levels directory if it doesn't exist
    love.filesystem.createDirectory("levels")
    
    -- Get list of available levels
    local levelsDir = "levels"
    local items = love.filesystem.getDirectoryItems(levelsDir)
    
    self.levelsList = {}
    
    for _, item in ipairs(items) do
        if item:sub(-4) == ".lua" then
            table.insert(self.levelsList, levelsDir .. "/" .. item:sub(1, -5))
        end
    end
    
    -- Fall back to default levels if none found
    if #self.levelsList == 0 then
        self.levelsList = {"levels/tutorial", "levels/exemploDeFase01"}
    end
end

-- Handle window resize
function GaleryManager:resize(w, h)
    -- Update back button position
    local backBtnWidth, backBtnHeight = ScreenUtils.getUIElementSize(100, 40)
    self.backButton.x = ScreenUtils.scaleValue(20)
    self.backButton.y = ScreenUtils.scaleValue(20)
    self.backButton.width = backBtnWidth
    self.backButton.height = backBtnHeight
    
    -- Update play button position
    local playBtnWidth, playBtnHeight = ScreenUtils.getUIElementSize(120, 40)
    self.playButton.x = ScreenUtils.width - ScreenUtils.scaleValue(140)
    self.playButton.y = ScreenUtils.scaleValue(20)
    self.playButton.width = playBtnWidth
    self.playButton.height = playBtnHeight
    
    -- Refresh icons with new screen dimensions
    self:refreshIcons()
    
    -- Notify currentScene about resize if it supports it
    if self.currentScene and self.currentScene.resize then
        self.currentScene:resize(w, h)
    end
end

return GaleryManager