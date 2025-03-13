-- stagescenes.lua
--[[
    StageScene module handles displaying animated backgrounds and effects
    for gameplay and gallery. Supports intro animations and looping animations.
]]

local ScreenUtils = require "screen_utils"

local StageScene = {}
StageScene.__index = StageScene

-- Creates a new stage scene
function StageScene.new(stageSceneModule)
    local self = setmetatable({}, StageScene)
    
    -- Try to load the module
    local success, moduleData = pcall(require, stageSceneModule)
    if success then
        self.data = moduleData
    else
        print("Error loading stage scene module:", stageSceneModule, moduleData)
        self.data = nil
    end
    
    -- Initialize state
    self.timer = 0
    self.currentFrame = 1
    self.currentSpritesheet = nil
    self.spritesheets = {}     -- Spritesheets for looping animation
    self.introSheet = nil      -- Intro animation spritesheet
    self.introQuads = {}       -- Quads for intro frames
    self.state = "intro"       -- States: "intro", "loop"
    self.imagesLoaded = false
    
    return self
end

-- Creates a default fallback image
local function createDefaultImage()
    local canvas = love.graphics.newCanvas(100, 100)
    love.graphics.setCanvas(canvas)
    love.graphics.clear(0.5, 0.5, 0.5, 1) -- Gray background
    love.graphics.setColor(1, 0, 0, 1)    -- Red text/border
    love.graphics.rectangle("line", 0, 0, 100, 100)
    love.graphics.printf("Missing Image", 0, 40, 100, "center")
    love.graphics.setCanvas()
    return canvas
end

-- Loads all resources and prepares the stage scene
function StageScene:load()
    -- Check if we have valid data
    if not self.data or not self.data.Efeitos or not self.data.Efeitos.efeito1 then
        print("Error: Missing or invalid data in stage scene")
        return false
    end

    local efeito = self.data.Efeitos.efeito1
    
    -- Load background with error handling
    local success, result = pcall(function()
        return love.graphics.newImage(efeito.background)
    end)
    
    if success then
        self.background = result
    else
        print("Error loading background:", efeito.background)
        self.background = createDefaultImage()
    end
    
    -- Load intro animation sheet
    success, result = pcall(function()
        return love.graphics.newImage(efeito.intro)
    end)
    
    if success then
        self.introSheet = result
        local introWidth, introHeight = self.introSheet:getDimensions()
        local introFrameWidth = introWidth / 31 -- Assuming 31 frames in intro
        
        -- Create quads for intro frames
        for i = 0, 30 do
            self.introQuads[i+1] = love.graphics.newQuad(
                i * introFrameWidth, 0,
                introFrameWidth, introHeight,
                introWidth, introHeight
            )
        end
    else
        print("Error loading intro sheet:", efeito.intro)
        self.introSheet = createDefaultImage()
        -- Create a single quad for default image
        self.introQuads[1] = love.graphics.newQuad(0, 0, 100, 100, 100, 100)
    end

    -- Load loop animations
    if efeito.loopSprite and type(efeito.loopSprite) == "table" then
        for _, spritesheetPath in ipairs(efeito.loopSprite) do
            success, result = pcall(function()
                return love.graphics.newImage(spritesheetPath)
            end)
            
            if success then
                local sheet = result
                local sheetWidth, sheetHeight = sheet:getDimensions()
                local frameWidth = sheetWidth / 31 -- Assuming 31 frames per sheet
                local quads = {}
                
                for i = 0, 30 do
                    quads[i+1] = love.graphics.newQuad(
                        i * frameWidth, 0,
                        frameWidth, sheetHeight,
                        sheetWidth, sheetHeight
                    )
                end
                
                table.insert(self.spritesheets, {
                    image = sheet,
                    quads = quads,
                    frameWidth = frameWidth,
                    frameHeight = sheetHeight
                })
            else
                print("Error loading spritesheet:", spritesheetPath)
                local defaultSheet = createDefaultImage()
                
                table.insert(self.spritesheets, {
                    image = defaultSheet,
                    quads = { love.graphics.newQuad(0, 0, 100, 100, 100, 100) },
                    frameWidth = 100,
                    frameHeight = 100
                })
            end
        end
    else
        print("Warning: No loop spritesheets defined or invalid format")
        local defaultSheet = createDefaultImage()
        
        table.insert(self.spritesheets, {
            image = defaultSheet,
            quads = { love.graphics.newQuad(0, 0, 100, 100, 100, 100) },
            frameWidth = 100,
            frameHeight = 100
        })
    end

    self.imagesLoaded = true
    self.state = "intro" -- Start with intro
    self.currentFrame = 1
    self.timer = 0
    
    return true
end

-- Selects a random spritesheet for loop animation
function StageScene:selectRandomSpritesheet()
    if not self.spritesheets or #self.spritesheets == 0 then 
        print("Warning: No spritesheets available")
        return 
    end
    
    local index = math.random(1, #self.spritesheets)
    self.currentSpritesheet = self.spritesheets[index]
    self.currentFrame = 1
    self.timer = 0
end

-- Updates the stage scene animation
function StageScene:update(dt)
    if not self.imagesLoaded then return end
    
    -- Check for required data
    if not self.data or not self.data.Efeitos or not self.data.Efeitos.efeito1 then return end
    
    local efeito = self.data.Efeitos.efeito1
    self.timer = self.timer + dt
    local animSpeed = efeito.animationSpeed or 0.1

    -- Intro animation state
    if self.state == "intro" then
        if self.timer >= animSpeed then
            self.currentFrame = self.currentFrame + 1
            self.timer = 0
            
            -- Transition to loop when intro finishes
            if self.currentFrame > #self.introQuads then
                self.state = "loop"
                self:selectRandomSpritesheet()
            end
        end
    
    -- Loop animation state
    elseif self.state == "loop" then
        if self.timer >= animSpeed then
            self.currentFrame = self.currentFrame + 1
            self.timer = 0
            
            -- Check for valid spritesheet
            if not self.currentSpritesheet then
                self:selectRandomSpritesheet()
            elseif not self.currentSpritesheet.quads then
                self:selectRandomSpritesheet()
            else
                -- Select next spritesheet when this one finishes
                local maxFrames = #self.currentSpritesheet.quads
                if self.currentFrame > maxFrames then
                    self:selectRandomSpritesheet()
                end
            end
        end
    end
end

-- Draws the stage scene
function StageScene:draw()
    if not self.imagesLoaded then return end
    
    -- Check for required data
    if not self.data or not self.data.Efeitos or not self.data.Efeitos.efeito1 then return end
    
    local efeito = self.data.Efeitos.efeito1
    
    -- Draw background
    if self.background then
        local bgWidth, bgHeight = self.background:getDimensions()

        -- Calculate background scale to cover screen
        local bgScale = math.max(
            ScreenUtils.width / bgWidth,
            ScreenUtils.height / bgHeight
        )
        local scaledBgWidth = bgWidth * bgScale
        local scaledBgHeight = bgHeight * bgScale
        local bgOffsetX = (ScreenUtils.width - scaledBgWidth) / 2
        local bgOffsetY = (ScreenUtils.height - scaledBgHeight) / 2

        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(
            self.background,
            bgOffsetX,
            bgOffsetY,
            0,
            bgScale,
            bgScale
        )

        -- Function for relative positioning to background
        local function getRelativePosition(percentX, percentY)
            return bgOffsetX + (scaledBgWidth * percentX),
                   bgOffsetY + (scaledBgHeight * percentY)
        end

        -- Calculate sprite scale proportional to background
        local baseSpriteScale = efeito.size or 1.0
        local spriteScale = baseSpriteScale * (scaledBgWidth / bgWidth)

        -- Get sprite position
        local spriteX, spriteY = getRelativePosition(efeito.x or 0.5, efeito.y or 0.5)

        -- Draw appropriate animation based on state
        love.graphics.setColor(1, 1, 1, 1)
        if self.state == "intro" and self.introSheet and self.introQuads and 
           self.currentFrame <= #self.introQuads then
            
            -- Safe centering by using frame width/height instead of quad dimensions
            local frameWidth = self.introSheet:getWidth() / 31 -- Assuming 31 frames
            local frameHeight = self.introSheet:getHeight()
            
            love.graphics.draw(
                self.introSheet,
                self.introQuads[self.currentFrame],
                spriteX,
                spriteY,
                0,
                spriteScale,
                spriteScale,
                frameWidth / 2, -- Use calculated dimensions instead of quad:getWidth()
                frameHeight / 2
            )
        elseif self.state == "loop" and self.currentSpritesheet and 
               self.currentSpritesheet.image and 
               self.currentSpritesheet.quads and 
               self.currentFrame <= #self.currentSpritesheet.quads then
            
            -- Safe centering using calculated frame dimensions
            local sheetWidth = self.currentSpritesheet.image:getWidth()
            local sheetHeight = self.currentSpritesheet.image:getHeight()
            local frameWidth = sheetWidth / 31 -- Assuming 31 frames
            
            love.graphics.draw(
                self.currentSpritesheet.image,
                self.currentSpritesheet.quads[self.currentFrame],
                spriteX,
                spriteY,
                0,
                spriteScale,
                spriteScale,
                frameWidth / 2, -- Use calculated dimensions instead of quad:getWidth()
                sheetHeight / 2
            )
        else
            -- Draw error placeholder if animation fails
            love.graphics.setColor(1, 0, 0, 0.5)
            love.graphics.rectangle("fill", spriteX-50, spriteY-50, 100, 100)
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.printf("Animation Error", spriteX-50, spriteY-10, 100, "center")
        end
    else
        -- No background, show error
        love.graphics.setColor(0.5, 0, 0, 1)
        love.graphics.rectangle("fill", 0, 0, ScreenUtils.width, ScreenUtils.height)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.printf(
            "Error loading stage scene resources", 
            0, ScreenUtils.height/2-20, ScreenUtils.width, "center"
        )
    end
    
    -- Reset color
    love.graphics.setColor(1, 1, 1, 1)
end

-- Handle window resize
function StageScene:resize(width, height)
    -- No explicit resource reloading needed
    -- Draw method uses ScreenUtils to handle dimensions dynamically
end

return StageScene