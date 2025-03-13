-- cutscenes.lua
--[[
    Module for managing and displaying cutscenes with dialogues,
    choices, and animated sprites. Handles narrative elements and
    transitions between game sections.
]]

local ScreenUtils = require "screen_utils"

local Cutscenes = {}
Cutscenes.__index = Cutscenes

-- Constants for UI layout - these will be scaled at runtime
local DIALOG_HEIGHT_PERCENT = 0.25 -- 25% of screen height
local TEXT_PADDING_BASE = 20
local CHOICE_PADDING_BASE = 10
local PORTRAIT_SIZE_BASE = 120

-- Sanitizes text to avoid UTF-8 errors
local function sanitizeText(text)
    if not text then return "" end
    
    -- Remove invalid UTF-8 characters
    local sanitized = ""
    for i = 1, #text do
        local c = text:sub(i, i)
        if c:byte() < 0x80 or (c:byte() >= 0xC0 and c:byte() < 0xF8) then
            sanitized = sanitized .. c
        end
    end
    
    return sanitized
end

-- Creates a new cutscene instance
function Cutscenes.new(cutsceneFile)
    local self = setmetatable({}, Cutscenes)
    
    -- Cutscene state
    self.isActive = false
    self.currentStep = 1
    self.dialogText = ""
    self.displayedText = ""
    self.textSpeed = 30 -- characters per second
    self.textTimer = 0
    self.textComplete = false
    self.cutsceneFile = cutsceneFile
    self.background = nil
    self.sprites = {}
    self.portraits = {}
    self.choices = {}
    self.waitingForChoice = false
    self.onComplete = nil
    self.levelToLoad = nil
    self.selectedLevel = nil
    
    -- Transition effects
    self.fadeAlpha = 1
    self.fadeState = "in" -- "in", "hold", "out"
    self.fadeSpeed = 1
    
    -- Calculate scaled dimensions
    self:updateScaledDimensions()
    
    return self
end

-- Update scaled dimensions when screen size changes
function Cutscenes:updateScaledDimensions()
    -- Scale UI elements based on screen size
    self.dialogHeight = ScreenUtils.height * DIALOG_HEIGHT_PERCENT
    self.textPadding = ScreenUtils.scaleValue(TEXT_PADDING_BASE)
    self.choicePadding = ScreenUtils.scaleValue(CHOICE_PADDING_BASE)
    self.portraitSize = ScreenUtils.scaleValue(PORTRAIT_SIZE_BASE)
end

-- Loads cutscene data from file
function Cutscenes:load()
    -- Try to load cutscene data
    local success, cutsceneData = pcall(require, self.cutsceneFile)
    
    if not success then
        print("Error loading cutscene:", self.cutsceneFile, cutsceneData)
        return false
    end
    
    self.data = cutsceneData
    self.isActive = true
    self.currentStep = 1
    self.levelToLoad = nil
    self.selectedLevel = nil
    
    -- Load background if defined
    if cutsceneData.background then
        local success, result = pcall(function()
            return love.graphics.newImage(cutsceneData.background)
        end)
        
        if success then
            self.background = result
        else
            print("Error loading background:", cutsceneData.background)
        end
    end
    
    -- Load character portraits
    if cutsceneData.characters then
        for name, data in pairs(cutsceneData.characters) do
            if data.portrait then
                local success, result = pcall(function()
                    return love.graphics.newImage(data.portrait)
                end)
                
                if success then
                    self.portraits[name] = result
                else
                    print("Error loading portrait:", data.portrait)
                end
            end
        end
    end
    
    -- Process first step
    self:processCurrentStep()
    
    return true
end

-- Process the current step of the cutscene
function Cutscenes:processCurrentStep()
    -- Check if we're at the end
    if not self.data or not self.data.steps or self.currentStep > #self.data.steps then
        self:complete()
        return
    end
    
    local step = self.data.steps[self.currentStep]
    
    -- Sanitize text to avoid UTF-8 errors
    self.dialogText = sanitizeText(step.text or "")
    self.displayedText = ""
    self.textComplete = false
    self.textTimer = 0
    
    -- Update background if specified
    if step.background then
        local success, result = pcall(function()
            return love.graphics.newImage(step.background)
        end)
        
        if success then
            self.background = result
        else
            print("Error loading step background:", step.background)
        end
    end
    
    -- Load sprites for this step
    if step.sprites then
        self.sprites = {}
        for i, spriteData in ipairs(step.sprites) do
            local success, spriteImage = pcall(function()
                return love.graphics.newImage(spriteData.image)
            end)
            
            if success then
                local sprite = {
                    image = spriteImage,
                    x = spriteData.x or 0.5,
                    y = spriteData.y or 0.5,
                    scale = spriteData.scale or 1,
                    flip = spriteData.flip or false,
                    -- Animation parameters
                    animated = spriteData.animated or false,
                    framesH = spriteData.framesH or 1,
                    framesV = spriteData.framesV or 1,
                    frameDelay = spriteData.frameDelay or 0.2,
                    currentFrame = 1,
                    frameTimer = 0
                }
                
                -- Set up animation if needed
                if sprite.animated then
                    -- Calculate frame dimensions
                    sprite.frameWidth = sprite.image:getWidth() / sprite.framesH
                    sprite.frameHeight = sprite.image:getHeight() / sprite.framesV
                    sprite.totalFrames = sprite.framesH * sprite.framesV
                    
                    -- Create quads for each animation frame
                    sprite.quads = {}
                    for v = 0, sprite.framesV - 1 do
                        for h = 0, sprite.framesH - 1 do
                            local quad = love.graphics.newQuad(
                                h * sprite.frameWidth,
                                v * sprite.frameHeight,
                                sprite.frameWidth,
                                sprite.frameHeight,
                                sprite.image:getDimensions()
                            )
                            table.insert(sprite.quads, quad)
                        end
                    end
                end
                
                table.insert(self.sprites, sprite)
            else
                print("Error loading sprite:", spriteData.image)
            end
        end
    end
    
    -- Set up choices if any
    if step.choices then
        -- Sanitize choice text
        for i, choice in ipairs(step.choices) do
            if choice.text then
                choice.text = sanitizeText(choice.text)
            end
        end
        self.choices = step.choices
        self.waitingForChoice = true
    else
        self.choices = {}
        self.waitingForChoice = false
    end
    
    -- Set speaking character
    self.speaker = step.speaker
    
    -- Check for level loading action
    if step.action and step.action == "startLevel" and step.levelPath then
        self.levelToLoad = step.levelPath
    end
end

-- Updates cutscene state
function Cutscenes:update(dt)
    if not self.isActive then return end
    
    -- Update fade transition
    if self.fadeState == "in" then
        self.fadeAlpha = math.max(0, self.fadeAlpha - self.fadeSpeed * dt)
        if self.fadeAlpha <= 0 then
            self.fadeState = "hold"
        end
    elseif self.fadeState == "out" then
        self.fadeAlpha = math.min(1, self.fadeAlpha + self.fadeSpeed * dt)
        if self.fadeAlpha >= 1 then
            self:complete()
        end
    end
    
    -- Update sprite animations
    for _, sprite in ipairs(self.sprites) do
        if sprite.animated then
            sprite.frameTimer = sprite.frameTimer + dt
            if sprite.frameTimer >= sprite.frameDelay then
                sprite.frameTimer = sprite.frameTimer - sprite.frameDelay
                sprite.currentFrame = sprite.currentFrame + 1
                if sprite.currentFrame > sprite.totalFrames then
                    sprite.currentFrame = 1
                end
            end
        end
    end
    
    -- Update text animation
    if not self.textComplete and not self.waitingForChoice then
        self.textTimer = self.textTimer + dt
        
        local charactersToDraw = math.floor(self.textTimer * self.textSpeed)
        if charactersToDraw > #self.dialogText then
            charactersToDraw = #self.dialogText
            self.textComplete = true
        end
        
        self.displayedText = string.sub(self.dialogText, 1, charactersToDraw)
    end
end

-- Draws the cutscene
function Cutscenes:draw()
    if not self.isActive then return end
    
    -- Draw background with scaling to fit screen
    if self.background then
        love.graphics.setColor(1, 1, 1)
        local bgScaleX = ScreenUtils.width / self.background:getWidth()
        local bgScaleY = ScreenUtils.height / self.background:getHeight()
        love.graphics.draw(self.background, 0, 0, 0, bgScaleX, bgScaleY)
    end
    
    -- Draw sprites
    for _, sprite in ipairs(self.sprites) do
        love.graphics.setColor(1, 1, 1)
        local posX = sprite.x * ScreenUtils.width
        local posY = sprite.y * ScreenUtils.height
        
        -- Scale sprite proportionally to screen size
        local scaleFactor = ScreenUtils.scale * sprite.scale
        local scaleX = scaleFactor
        if sprite.flip then scaleX = -scaleX end
        
        if sprite.animated and sprite.quads then
            -- Draw current frame for animated sprites
            local currentQuad = sprite.quads[sprite.currentFrame]
            love.graphics.draw(
                sprite.image, 
                currentQuad,
                posX, 
                posY, 
                0, 
                scaleX, 
                scaleFactor,
                sprite.frameWidth / 2,
                sprite.frameHeight / 2
            )
        else
            -- Draw non-animated sprites
            love.graphics.draw(
                sprite.image, 
                posX, 
                posY, 
                0, 
                scaleX, 
                scaleFactor,
                sprite.image:getWidth() / 2,
                sprite.image:getHeight() / 2
            )
        end
    end
    
    -- Draw dialog box
    love.graphics.setColor(0, 0, 0, 0.8)
    love.graphics.rectangle(
        "fill", 
        0, 
        ScreenUtils.height - self.dialogHeight, 
        ScreenUtils.width, 
        self.dialogHeight
    )
    
    -- Draw character portrait if available
    if self.speaker and self.portraits[self.speaker] then
        love.graphics.setColor(1, 1, 1)
        
        -- Calculate portrait scaling to maintain aspect ratio
        local portrait = self.portraits[self.speaker]
        local portraitScaleX = self.portraitSize / portrait:getWidth()
        local portraitScaleY = self.portraitSize / portrait:getHeight()
        
        love.graphics.draw(
            portrait, 
            self.textPadding, 
            ScreenUtils.height - self.dialogHeight + self.textPadding, 
            0,
            portraitScaleX,
            portraitScaleY
        )
    end
    
    -- Draw character name
    if self.speaker and self.data.characters and self.data.characters[self.speaker] then
        love.graphics.setColor(1, 1, 1)
        local fontSize = ScreenUtils.scaleFontSize(14)
        local font = love.graphics.newFont(fontSize)
        love.graphics.setFont(font)
        
        love.graphics.print(
            self.data.characters[self.speaker].name or self.speaker, 
            self.textPadding * 2 + self.portraitSize, 
            ScreenUtils.height - self.dialogHeight + self.textPadding
        )
    end
    
    -- Draw dialog text
    love.graphics.setColor(1, 1, 1)
    local textX = self.textPadding
    if self.speaker and self.portraits[self.speaker] then
        textX = self.textPadding * 2 + self.portraitSize
    end
    
    -- Safely draw text with error handling
    local fontSize = ScreenUtils.scaleFontSize(14)
    local font = love.graphics.newFont(fontSize)
    love.graphics.setFont(font)
    
    local success = pcall(function()
        love.graphics.printf(
            self.displayedText, 
            textX, 
            ScreenUtils.height - self.dialogHeight + self.textPadding * 3,
            ScreenUtils.width - textX - self.textPadding, 
            "left"
        )
    end)

    -- Fallback on error
    if not success then
        -- Create ASCII-only version of text
        local safeText = ""
        for i = 1, #self.displayedText do
            local c = self.displayedText:sub(i, i)
            if c:byte() < 128 then -- ASCII only
                safeText = safeText .. c
            else
                safeText = safeText .. "?"
            end
        end
        
        love.graphics.printf(
            safeText,
            textX, 
            ScreenUtils.height - self.dialogHeight + self.textPadding * 3,
            ScreenUtils.width - textX - self.textPadding, 
            "left"
        )
    end
    
    -- Draw "Continue" or choices
    if self.textComplete then
        if self.waitingForChoice and #self.choices > 0 then
            -- Draw choice options
            local choiceY = ScreenUtils.height - self.dialogHeight / 2
            
            -- Use font that scales with screen size
            local choiceFontSize = ScreenUtils.scaleFontSize(14)
            local choiceFont = love.graphics.newFont(choiceFontSize)
            love.graphics.setFont(choiceFont)
            
            for i, choice in ipairs(self.choices) do
                love.graphics.setColor(0.3, 0.3, 0.3, 0.8)
                
                -- Get choice width safely
                local choiceWidth
                local success, result = pcall(function()
                    return choiceFont:getWidth(choice.text) + self.choicePadding * 2
                end)
                
                if success then
                    choiceWidth = result
                else
                    choiceWidth = ScreenUtils.scaleValue(200) -- Default fallback
                end
                
                local choiceHeight = choiceFont:getHeight() + self.choicePadding
                local choiceX = ScreenUtils.width / 2 - choiceWidth / 2
                
                -- Calculate Y position based on number of choices
                local spacing = ScreenUtils.scaleValue(10)
                local offsetY = (-#self.choices / 2 + (i - 1)) * (choiceHeight + spacing)
                local currentChoiceY = choiceY + offsetY
                
                -- Draw choice background
                love.graphics.rectangle(
                    "fill", 
                    choiceX, 
                    currentChoiceY, 
                    choiceWidth, 
                    choiceHeight,
                    4, -- Rounded corners
                    4
                )
                
                -- Draw choice text
                love.graphics.setColor(1, 1, 1)
                pcall(function()
                    love.graphics.print(
                        choice.text, 
                        choiceX + self.choicePadding, 
                        currentChoiceY + self.choicePadding / 2
                    )
                end)
            end
        else
            -- Draw "Continue" indicator
            love.graphics.setColor(1, 1, 1)
            local fontSize = ScreenUtils.scaleFontSize(14)
            local font = love.graphics.newFont(fontSize)
            love.graphics.setFont(font)
            
            local continueText = "Pressione [ESPAÇO] para continuar"
            local textWidth = font:getWidth(continueText)
            
            love.graphics.print(
                continueText, 
                ScreenUtils.width - textWidth - self.textPadding, 
                ScreenUtils.height - self.textPadding * 2
            )
        end
    end
    
    -- Draw fade effect
    if self.fadeAlpha > 0 then
        love.graphics.setColor(0, 0, 0, self.fadeAlpha)
        love.graphics.rectangle("fill", 0, 0, ScreenUtils.width, ScreenUtils.height)
    end
    
    -- Reset color
    love.graphics.setColor(1, 1, 1)
end

-- Handle mouse click events
function Cutscenes:mousepressed(x, y, button)
    if not self.isActive or button ~= 1 then return end
    
    -- Handle choices when waiting for selection
    if self.waitingForChoice and self.textComplete then
        local choiceY = ScreenUtils.height - self.dialogHeight / 2
        
        -- Use scaled font for calculations
        local choiceFontSize = ScreenUtils.scaleFontSize(14)
        local choiceFont = love.graphics.newFont(choiceFontSize)
        
        for i, choice in ipairs(self.choices) do
            -- Calculate choice dimensions
            local choiceWidth
            local success, result = pcall(function()
                return choiceFont:getWidth(choice.text) + self.choicePadding * 2
            end)
            
            if success then
                choiceWidth = result
            else
                choiceWidth = ScreenUtils.scaleValue(200) -- Default fallback
            end
            
            local choiceHeight = choiceFont:getHeight() + self.choicePadding
            local choiceX = ScreenUtils.width / 2 - choiceWidth / 2
            
            -- Calculate Y position
            local spacing = ScreenUtils.scaleValue(10)
            local offsetY = (-#self.choices / 2 + (i - 1)) * (choiceHeight + spacing)
            local currentChoiceY = choiceY + offsetY
            
            -- Check if click is inside this choice
            if x >= choiceX and x <= choiceX + choiceWidth and
               y >= currentChoiceY and y <= currentChoiceY + choiceHeight then
                
                -- Handle special action
                if choice.action and choice.action == "startLevel" and choice.levelPath then
                    self.levelToLoad = choice.levelPath
                end
                
                -- Go to next step if specified
                if choice.nextStep then
                    self.currentStep = choice.nextStep
                    self.waitingForChoice = false
                    self:processCurrentStep()
                    return
                end
            end
        end
    else
        -- Complete text display if not complete
        if not self.textComplete then
            self.displayedText = self.dialogText
            self.textComplete = true
        else
            -- Execute level loading action if set
            if self.levelToLoad then
                self.selectedLevel = self.levelToLoad
                -- Store level to load and finish cutscene
                self:complete()
                return
            end
            
            -- Advance to next step if not waiting for choice
            if not self.waitingForChoice then
                self.currentStep = self.currentStep + 1
                self:processCurrentStep()
            end
        end
    end
end

-- Handle keyboard events
function Cutscenes:keypressed(key)
    if not self.isActive then return end
    
    if key == "space" or key == "return" then
        -- Similar behavior to mousepressed
        if not self.textComplete then
            self.displayedText = self.dialogText
            self.textComplete = true
        else
            -- Execute level loading action if set
            if self.levelToLoad then
                self.selectedLevel = self.levelToLoad
                -- Store level to load and finish cutscene
                self:complete()
                return
            end
            
            -- Only advance if not waiting for choice
            if not self.waitingForChoice then
                self.currentStep = self.currentStep + 1
                self:processCurrentStep()
            end
        end
    end
    
    -- Skip entire cutscene with Escape
    if key == "escape" then
        self.fadeState = "out"
    end
end

-- Complete the cutscene
function Cutscenes:complete()
    self.isActive = false
    if self.onComplete then
        self.onComplete()
    end
end

-- Handle window resize
function Cutscenes:resize(width, height)
    -- Update scaled dimensions when window size changes
    self:updateScaledDimensions()
end

return Cutscenes