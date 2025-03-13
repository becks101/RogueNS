-- button.lua
--[[ 
    UI components for game interface
    Includes: Button, Selector, Tab, VolumeSlider, GaleryIcons
]]

-- UI Colors for consistent appearance
local UIColors = {
    default = {1, 0.7, 1},       -- Default color
    hover = {0.7, 0.7, 0.7},     -- Hover color
    selected = {0.3, 0.6, 1}     -- Selected state color
}

-- Base Button class
local Button = {}
Button.__index = Button

-- Creates a new button
function Button.new(x, y, width, height, label, onClick)
    local self = setmetatable({
        x = x,
        y = y,
        width = width,
        height = height,
        label = label,
        onClick = onClick,
        hover = false
    }, Button)
    return self
end

-- Updates button hover state
function Button:updateHover(mx, my)
    self.hover = mx and my and mx >= self.x and mx <= self.x + self.width
                and my >= self.y and my <= self.y + self.height
end

-- Draws the button
function Button:draw()
    love.graphics.setColor(self.hover and UIColors.hover or UIColors.default)
    love.graphics.rectangle("line", self.x, self.y, self.width, self.height)
    love.graphics.printf(self.label, self.x, self.y + self.height / 2 - 6, self.width, "center")
    love.graphics.setColor(1, 1, 1)
end

-- Handles mouse press events
function Button:mousepressed(x, y, button)
    if button == 1 and self.hover and self.onClick then
        self.onClick()
    end
end

-- Selector: Button that maintains a persistent selection state
local Selector = {}
Selector.__index = Selector
setmetatable(Selector, { __index = Button })

-- Creates a new selector
function Selector.new(x, y, width, height, label, onClick)
    local self = setmetatable(Button.new(x, y, width, height, label, onClick), Selector)
    self.selected = false
    return self
end

-- Handles mouse press events for selector (toggles selection)
function Selector:mousepressed(x, y, button)
    if button == 1 and self.hover then
        self.selected = not self.selected
        if self.onClick then self.onClick() end
    end
end

-- Draws the selector with selection state
function Selector:draw()
    love.graphics.setColor(self.selected and UIColors.selected or
                         (self.hover and UIColors.hover or UIColors.default))
    love.graphics.rectangle("line", self.x, self.y, self.width, self.height)
    love.graphics.printf(self.label, self.x, self.y + self.height / 2 - 6, self.width, "center")
    love.graphics.setColor(1, 1, 1)
end

-- Tab: Button that shows selection (but external logic controls it)
local Tab = {}
Tab.__index = Tab
setmetatable(Tab, { __index = Button })

-- Creates a new tab
function Tab.new(x, y, width, height, label, onClick)
    local self = setmetatable(Button.new(x, y, width, height, label, onClick), Tab)
    self.selected = false
    return self
end

-- Handles mouse press events for tabs
function Tab:mousepressed(x, y, button)
    if button == 1 and self.hover then
        self.selected = true
        if self.onClick then self.onClick() end
    end
end

-- Draws the tab with selection state
function Tab:draw()
    -- Color based on selection state
    local color = self.selected and UIColors.selected or 
                 (self.hover and UIColors.hover or UIColors.default)
    
    love.graphics.setColor(color)
    love.graphics.rectangle("line", self.x, self.y, self.width, self.height)
    love.graphics.printf(self.label, self.x, self.y + self.height/2 - 6, self.width, "center")
    love.graphics.setColor(1, 1, 1)
end

-- Volume Slider: Slidable control for volume adjustment
local VolumeSlider = {}
VolumeSlider.__index = VolumeSlider

-- Creates a new volume slider
function VolumeSlider.new(x, y, width, min, max, value, callback)
    local self = setmetatable({}, VolumeSlider)
    self.x = x
    self.y = y
    self.width = width
    self.min = min or 0
    self.max = max or 1
    self.value = value or min or 0
    self.callback = callback
    self.dragging = false
    return self
end

-- Updates the slider state
function VolumeSlider:update(dt)
    if self.dragging then
        local mx = love.mouse.getX()
        local newValue = (mx - self.x) / self.width * (self.max - self.min) + self.min
        self.value = math.max(self.min, math.min(self.max, newValue))
        if self.callback then self.callback(self.value) end
    end
end

-- Handles mouse press events for the slider
function VolumeSlider:mousepressed(x, y, button)
    if button == 1 and x >= self.x and x <= self.x + self.width
       and y >= self.y - 5 and y <= self.y + 5 then
        self.dragging = true
    end
end

-- Handles mouse release events for the slider
function VolumeSlider:mousereleased(x, y, button)
    if button == 1 then
        self.dragging = false
    end
end

-- Draws the slider
function VolumeSlider:draw()
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("fill", self.x, self.y, self.width, 5)
    
    local knobX = self.x + (self.value - self.min) / (self.max - self.min) * self.width
    love.graphics.setColor(0.8, 0.2, 0.2)
    love.graphics.rectangle("fill", knobX - 5, self.y - 5, 10, 15)
    
    love.graphics.setColor(1, 1, 1)
end

-- Gallery Icons: Interactive icons with hover and click effects
local GaleryIcons = {}
GaleryIcons.__index = GaleryIcons

-- Creates a new gallery icon
function GaleryIcons.new(x, y, imagePath, name, onClick)
    local self = setmetatable({}, GaleryIcons)
    self.x = x
    self.y = y
    self.imagePath = imagePath
    self.name = name
    self.onClick = onClick
    self.normalScale = 1
    self.hoverScale = 1.1
    self.currentScale = self.normalScale
    self.hover = false
    self.clickTimer = nil
    self.originalScale = nil
    
    -- Try to load the image with fallback
    local success, result = pcall(function()
        return love.graphics.newImage(imagePath)
    end)
    
    if success then
        self.image = result
    else
        print("Error loading image:", imagePath, result)
        -- Create fallback image
        self.image = love.graphics.newCanvas(64, 64)
        love.graphics.setCanvas(self.image)
        love.graphics.clear(0.5, 0.5, 0.5)
        love.graphics.setColor(0, 0, 0)
        love.graphics.rectangle("line", 0, 0, 64, 64)
        love.graphics.printf("Error", 0, 24, 64, "center")
        love.graphics.setCanvas()
    end
    
    return self
end

-- Updates the icon state
function GaleryIcons:update(dt)
    -- Update click animation timer if active
    if self.clickTimer and self.clickTimer > 0 then
        self.clickTimer = self.clickTimer - dt
        
        -- Restore original scale when timer expires
        if self.clickTimer <= 0 then
            self.currentScale = self.originalScale
            self.clickTimer = nil
            self.originalScale = nil
        end
    end
    
    -- Update hover state if needed
    if self.updateHoverInUpdate then
        local mx, my = love.mouse.getPosition()
        self:updateHover(mx, my)
    end
end

-- Updates hover state
function GaleryIcons:updateHover(mx, my)
    if not self.image then return end
    
    local width = self.image:getWidth() * self.currentScale
    local height = self.image:getHeight() * self.currentScale
    
    -- Check if mouse is within icon area
    if mx >= self.x and mx <= self.x + width and 
       my >= self.y and my <= self.y + height then
        self.hover = true
        self.currentScale = self.hoverScale
    else
        self.hover = false
        self.currentScale = self.normalScale
    end
end

-- Handles mouse press events for the icon
function GaleryIcons:mousepressed(x, y, button)
    if button == 1 and self.hover and self.onClick then
        -- Visual feedback for click
        local originalScale = self.currentScale
        self.currentScale = self.currentScale * 0.9
        
        -- Store original scale and create timer
        self.clickTimer = 0.1  -- 100ms
        self.originalScale = originalScale
        
        -- Call onClick callback
        self.onClick()
    end
end

-- Draws the icon
function GaleryIcons:draw()
    if not self.image then return end
    
    local width = self.image:getWidth() * self.currentScale
    local height = self.image:getHeight() * self.currentScale
    
    -- Draw shadow when hovering
    if self.hover then
        love.graphics.setColor(0, 0, 0, 0.5)
        local offset = 5
        love.graphics.draw(
            self.image, 
            self.x + offset, 
            self.y + offset, 
            0, 
            self.currentScale, 
            self.currentScale
        )
    end
    
    -- Draw main image
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(
        self.image, 
        self.x, 
        self.y, 
        0, 
        self.currentScale, 
        self.currentScale
    )
    
    -- Show name when hovering
    if self.hover then
        love.graphics.setColor(1, 1, 1)
        local font = love.graphics.getFont()
        local textWidth = font:getWidth(self.name)
        local textX = self.x + (width - textWidth) / 2
        love.graphics.print(
            self.name, 
            textX, 
            self.y + height + 5
        )
    end
end

-- Return all UI components
return {
    Button = Button,
    Selector = Selector,
    Tab = Tab,
    VolumeSlider = VolumeSlider,
    UIColors = UIColors,
    GaleryIcons = GaleryIcons
}