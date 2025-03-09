-- stagescenes.lua
local StageScene = {}
StageScene.__index = StageScene

function StageScene.new(stageSceneModule)
    local self = setmetatable({}, StageScene)
    self.data = require(stageSceneModule)
    self.timer = 0
    self.currentFrame = 1
    self.currentSpritesheet = nil
    self.spritesheets = {}         -- Spritesheets para o loop
    self.introSheet = nil          -- Spritesheet da intro
    self.introQuads = {}           -- Quads da intro
    self.state = "intro"           -- Estados: "intro", "loop"
    self.imagesLoaded = false
    return self
end

function StageScene:load()
    -- Check if data is properly loaded
    if not self.data or not self.data.Efeitos or not self.data.Efeitos.efeito1 then
        print("Error: Missing or invalid data in stage scene")
        return false
    end

    local efeito = self.data.Efeitos.efeito1
    
    -- Create a default image as fallback (small colored rectangle)
    local defaultImage = function()
        local canvas = love.graphics.newCanvas(100, 100)
        love.graphics.setCanvas(canvas)
        love.graphics.clear(0.5, 0.5, 0.5, 1) -- Gray background
        love.graphics.setColor(1, 0, 0, 1)    -- Red text
        love.graphics.rectangle("line", 0, 0, 100, 100)
        love.graphics.printf("Missing Image", 0, 40, 100, "center")
        love.graphics.setCanvas()
        return canvas
    end
    
    -- Load background with error handling
    local success, result = pcall(function()
        return love.graphics.newImage(efeito.background)
    end)
    
    if success then
        self.background = result
    else
        print("Error loading background: " .. efeito.background)
        self.background = defaultImage()
    end
    
    -- Load intro (animation initial) with error handling
    success, result = pcall(function()
        return love.graphics.newImage(efeito.intro)
    end)
    
    if success then
        self.introSheet = result
        local introWidth, introHeight = self.introSheet:getDimensions()
        local introFrameWidth = introWidth / 31 -- Assuming 31 frames in intro
        
        -- Create quads for the intro
        for i = 0, 30 do
            self.introQuads[i+1] = love.graphics.newQuad(
                i * introFrameWidth, 0,
                introFrameWidth, introHeight,
                introWidth, introHeight
            )
        end
    else
        print("Error loading intro sheet: " .. efeito.intro)
        self.introSheet = defaultImage()
        -- Create a single quad for the default image
        self.introQuads[1] = love.graphics.newQuad(0, 0, 100, 100, 100, 100)
    end

    -- Load loop spritesheets with error handling
    if efeito.loopSprite and type(efeito.loopSprite) == "table" then
        for _, spritesheetPath in ipairs(efeito.loopSprite) do
            success, result = pcall(function()
                return love.graphics.newImage(spritesheetPath)
            end)
            
            if success then
                local sheet = result
                local sheetWidth, sheetHeight = sheet:getDimensions()
                local frameWidth = sheetWidth / 31 -- 31 frames per spritesheet
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
                    quads = quads
                })
            else
                print("Error loading spritesheet: " .. spritesheetPath)
                local defaultSheet = defaultImage()
                
                table.insert(self.spritesheets, {
                    image = defaultSheet,
                    quads = { love.graphics.newQuad(0, 0, 100, 100, 100, 100) }
                })
            end
        end
    else
        print("Error: No loop spritesheets defined or invalid format")
        local defaultSheet = defaultImage()
        
        table.insert(self.spritesheets, {
            image = defaultSheet,
            quads = { love.graphics.newQuad(0, 0, 100, 100, 100, 100) }
        })
    end

    self.imagesLoaded = true
    self.state = "intro" -- Start with intro
    self.currentFrame = 1
    
    -- If we got here, loading was at least partially successful
    return true
end

-- Fix the selectRandomSpritesheet method to be more robust
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

-- Make the update method more robust
function StageScene:update(dt)
    if not self.imagesLoaded then return end
    
    -- Check if we have the necessary data
    if not self.data or not self.data.Efeitos or not self.data.Efeitos.efeito1 then return end
    
    local efeito = self.data.Efeitos.efeito1
    self.timer = self.timer + dt

    -- Intro logic
    if self.state == "intro" then
        if self.timer >= (efeito.animationSpeed or 0.1) then
            self.currentFrame = self.currentFrame + 1
            self.timer = 0
            
            -- Finished intro? Start the loop
            local maxFrames = #self.introQuads
            if self.currentFrame > maxFrames then
                self.state = "loop"
                self:selectRandomSpritesheet()
            end
        end
    
    -- Loop logic
    elseif self.state == "loop" then
        if self.timer >= (efeito.animationSpeed or 0.1) then
            self.currentFrame = self.currentFrame + 1
            self.timer = 0
            
            -- Change spritesheet when finished
            if not self.currentSpritesheet then
                self:selectRandomSpritesheet()
            elseif not self.currentSpritesheet.quads then
                self:selectRandomSpritesheet()
            else
                local maxFrames = #self.currentSpritesheet.quads
                if self.currentFrame > maxFrames then
                    self:selectRandomSpritesheet()
                end
            end
        end
    end
end
-- Make the draw method more robust
function StageScene:draw()
    if not self.imagesLoaded then return end
    
    -- Check if we have the necessary data
    if not self.data or not self.data.Efeitos or not self.data.Efeitos.efeito1 then return end
    
    local efeito = self.data.Efeitos.efeito1
    local screenWidth, screenHeight = love.graphics.getDimensions()
    
    -- Draw background
    if self.background then
        local bgWidth, bgHeight = self.background:getDimensions()

        -- Calculate background scale maintaining aspect ratio
        local bgScale = math.max(
            screenWidth / bgWidth,
            screenHeight / bgHeight
        )
        local scaledBgWidth = bgWidth * bgScale
        local scaledBgHeight = bgHeight * bgScale
        local bgOffsetX = (screenWidth - scaledBgWidth) / 2
        local bgOffsetY = (screenHeight - scaledBgHeight) / 2

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

        -- Draw animation
        if self.state == "intro" and self.introSheet and self.introQuads and self.currentFrame <= #self.introQuads then
            love.graphics.draw(
                self.introSheet,
                self.introQuads[self.currentFrame],
                spriteX,
                spriteY,
                0,
                spriteScale,
                spriteScale
            )
        elseif self.state == "loop" and self.currentSpritesheet and 
               self.currentSpritesheet.image and 
               self.currentSpritesheet.quads and 
               self.currentFrame <= #self.currentSpritesheet.quads then
            
            love.graphics.draw(
                self.currentSpritesheet.image,
                self.currentSpritesheet.quads[self.currentFrame],
                spriteX,
                spriteY,
                0,
                spriteScale,
                spriteScale
            )
        else
            -- Draw a placeholder if animation can't be shown
            love.graphics.setColor(1, 0, 0, 0.5)
            love.graphics.rectangle("fill", spriteX-50, spriteY-50, 100, 100)
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.printf("Animation Error", spriteX-50, spriteY-10, 100, "center")
        end
    else
        -- No background, show error
        love.graphics.setColor(0.5, 0, 0, 1)
        love.graphics.rectangle("fill", 0, 0, screenWidth, screenHeight)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.printf("Error loading stage scene resources", 0, screenHeight/2-20, screenWidth, "center")
    end
    
    -- Reset color
    love.graphics.setColor(1, 1, 1, 1)
end

return StageScene