-- button.lua
local Button = {}
Button.__index = Button

function Button.new(x, y, width, height, label, callback)
    local self = setmetatable({}, Button)
    self.x, self.y = x, y
    self.width, self.height = width, height
    self.label = label
    self.callback = callback
    self.hover = false
    return self
end

function Button:updateHover(mx, my)
    self.hover = mx >= self.x and mx <= self.x + self.width and my >= self.y and my <= self.y + self.height
end

function Button:mousepressed(x, y, button)
    if self.hover and button == 1 and self.callback then
        self.callback()
    end
end

function Button:draw()
    love.graphics.setColor(self.hover and {0.7, 0.7, 0.7} or {1, 1, 1})
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
    love.graphics.setColor(0, 0, 0)
    love.graphics.print(self.label, self.x + 10, self.y + 10)
end

-- Cores da UI
local UIColors = {
    default = {1, 1, 1},
    hover = {0.7, 0.7, 0.7},
    selected = {0.3, 0.6, 1}
}
-- Classe base: Botão
local Button = {}
Button.__index = Button

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

function Button:updateHover(mx, my)
    self.hover = mx >= self.x and mx <= self.x + self.width
                and my >= self.y and my <= self.y + self.height
end

function Button:draw()
    love.graphics.setColor(self.hover and UIColors.hover or UIColors.default)
    love.graphics.rectangle("line", self.x, self.y, self.width, self.height)
    love.graphics.printf(self.label, self.x, self.y + self.height / 2 - 6, self.width, "center")
    love.graphics.setColor(1, 1, 1)
end

function Button:mousepressed(x, y, button)
    if button == 1 and self.hover and self.onClick then
        self.onClick()
    end
end

-- Classe Seletor: mantém seleção de forma persistente
local Selector = {}
Selector.__index = Selector
setmetatable(Selector, { __index = Button })

function Selector.new(x, y, width, height, label, onClick)
    local self = setmetatable(Button.new(x, y, width, height, label, onClick), Selector)
    self.selected = false
    return self
end

function Selector:mousepressed(x, y, button)
    if button == 1 and self.hover then
        self.selected = not self.selected
        if self.onClick then self.onClick() end
    end
end

function Selector:draw()
    love.graphics.setColor(self.selected and UIColors.selected or (self.hover and UIColors.hover or UIColors.default))
    love.graphics.rectangle("line", self.x, self.y, self.width, self.height)
    love.graphics.printf(self.label, self.x, self.y + self.height / 2 - 6, self.width, "center")
    love.graphics.setColor(1, 1, 1)
end

-- Classe Aba: muda de cor quando selecionada (mas o reset fica a cargo da lógica externa)
local Tab = {}
Tab.__index = Tab
setmetatable(Tab, { __index = Button })

function Tab.new(x, y, width, height, label, onClick)
    local self = setmetatable(Button.new(x, y, width, height, label, onClick), Tab)
    self.selected = false
    return self
end

function Tab:mousepressed(x, y, button)
    if button == 1 and self.hover then
        self.selected = true
        if self.onClick then self.onClick() end
    end
end

function Tab:draw()
    love.graphics.setColor(self.selected and UIColors.selected or (self.hover and UIColors.hover or UIColors.default))
    love.graphics.rectangle("line", self.x, self.y, self.width, self.height)
    love.graphics.printf(self.label, self.x, self.y + self.height / 2 - 6, self.width, "center")
    love.graphics.setColor(1, 1, 1)
end

-- Classe Volume Slider: barra de volume deslizante
local VolumeSlider = {}
VolumeSlider.__index = VolumeSlider

function VolumeSlider.new(x, y, width, min, max, value, callback)
    local self = setmetatable({}, VolumeSlider)
    self.x = x
    self.y = y
    self.width = width
    self.min = min
    self.max = max
    self.value = value
    self.callback = callback
    self.dragging = false
    return self
end

function VolumeSlider:update(dt)
    if self.dragging then
        local mx = love.mouse.getX()
        local newValue = (mx - self.x) / self.width * (self.max - self.min) + self.min
        self.value = math.max(self.min, math.min(self.max, newValue))
        if self.callback then self.callback(self.value) end
    end
end

function VolumeSlider:mousepressed(x, y, button)
    if button == 1 and x >= self.x and x <= self.x + self.width
       and y >= self.y - 5 and y <= self.y + 5 then
        self.dragging = true
    end
end

function VolumeSlider:mousereleased(x, y, button)
    if button == 1 then
        self.dragging = false
    end
end

function VolumeSlider:draw()
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("fill", self.x, self.y, self.width, 5)
    local knobX = self.x + (self.value - self.min) / (self.max - self.min) * self.width
    love.graphics.setColor(0.8, 0.2, 0.2)
    love.graphics.rectangle("fill", knobX - 5, self.y - 5, 10, 15)
    love.graphics.setColor(1, 1, 1)
end

local GaleryIcons = {}
GaleryIcons.__index = GaleryIcons

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
    self.image = love.graphics.newImage(imagePath)
    return self
end

function GaleryIcons:updateHover(mx, my)
    local width = self.image:getWidth() * self.currentScale
    local height = self.image:getHeight() * self.currentScale
    if mx >= self.x and mx <= self.x + width and my >= self.y and my <= self.y + height then
        self.hover = true
        self.currentScale = self.hoverScale
    else
        self.hover = false
        self.currentScale = self.normalScale
    end
end

function GaleryIcons:mousepressed(x, y, button)
    if button == 1 and self.hover and self.onClick then
        self.onClick()
    end
end

function GaleryIcons:draw()
    -- Se estiver com o mouse sobre, desenha uma sombra com pequeno offset
    if self.hover then
        love.graphics.setColor(0, 0, 0, 0.5)  -- sombra semi-transparente
        local offset = 5
        love.graphics.draw(self.image, self.x + offset, self.y + offset, 0, self.currentScale, self.currentScale)
    end
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(self.image, self.x, self.y, 0, self.currentScale, self.currentScale)
    
    -- Se o mouse estiver sobre, exibe o nome abaixo do ícone
    if self.hover then
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(self.name, self.x, self.y + self.image:getHeight() * self.currentScale + 2)
    end
end

return {
    Button = Button,
    Selector = Selector,
    Tab = Tab,
    VolumeSlider = VolumeSlider,
    UIColors = UIColors,
    GaleryIcons = GaleryIcons
}