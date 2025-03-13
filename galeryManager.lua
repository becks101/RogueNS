-- galeryManager.lua
--[[
    Gallery manager module that handles displaying and interacting with
    different types of unlocked content:
    - Stage scenes
    - Cutscenes
    - Items
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
    
    self.icons = {}
    self.currentScene = nil -- Currently active scene (stage scene or cutscene)
    self.sceneType = nil    -- Type of current scene ("stage" or "cutscene")
    
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
        end
    )
    
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
end

-- Handle window resize
function GaleryManager:resize(w, h)
    -- Update back button position
    local backBtnWidth, backBtnHeight = ScreenUtils.getUIElementSize(100, 40)
    self.backButton.x = ScreenUtils.scaleValue(20)
    self.backButton.y = ScreenUtils.scaleValue(20)
    self.backButton.width = backBtnWidth
    self.backButton.height = backBtnHeight
    
    -- Refresh icons with new screen dimensions
    self:refreshIcons()
    
    -- Notify currentScene about resize if it supports it
    if self.currentScene and self.currentScene.resize then
        self.currentScene:resize(w, h)
    end
end

return GaleryManager