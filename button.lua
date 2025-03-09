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
    default = {1, 0.7, 1},
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
    -- Altera a cor baseado no estado de seleção
    local color = self.selected and UIColors.selected or 
                 (self.hover and UIColors.hover or UIColors.default)
    
    love.graphics.setColor(color)
    love.graphics.rectangle("line", self.x, self.y, self.width, self.height)
    love.graphics.printf(self.label, self.x, self.y + self.height/2 - 6, self.width, "center")
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
    
    -- Tenta carregar a imagem e usa uma imagem padrão se falhar
    local success, result = pcall(function()
        return love.graphics.newImage(imagePath)
    end)
    
    if success then
        self.image = result
    else
        print("Erro ao carregar imagem:", imagePath, result)
        -- Tenta criar uma imagem em branco como fallback
        self.image = love.graphics.newCanvas(64, 64)
        love.graphics.setCanvas(self.image)
        love.graphics.clear(0.5, 0.5, 0.5)
        love.graphics.setColor(0, 0, 0)
        love.graphics.rectangle("line", 0, 0, 64, 64)
        love.graphics.printf("Erro", 0, 24, 64, "center")
        love.graphics.setCanvas()
    end
    
    return self
end
function GaleryIcons:update(dt)
    -- If there's an active click timer, update it
    if self.clickTimer and self.clickTimer > 0 then
        self.clickTimer = self.clickTimer - dt
        
        -- When timer expires, restore original scale
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

function GaleryIcons:updateHover(mx, my)
    local width = self.image:getWidth() * self.currentScale
    local height = self.image:getHeight() * self.currentScale
    
    -- Calcula o centro da imagem para posicionamento
    local centerX = self.x + width / 2
    local centerY = self.y + height / 2
    
    -- Verifica se o mouse está dentro da área da imagem
    if mx >= self.x and mx <= self.x + width and 
       my >= self.y and my <= self.y + height then
        self.hover = true
        self.currentScale = self.hoverScale
    else
        self.hover = false
        self.currentScale = self.normalScale
    end
end

function GaleryIcons:mousepressed(x, y, button)
    if button == 1 and self.hover and self.onClick then
        -- Add feedback visual temporarily
        local originalScale = self.currentScale
        self.currentScale = self.currentScale * 0.9
        
        -- Create a simple timer instead of using setTimeout which doesn't exist in LÖVE
        self.clickTimer = 0.1  -- 100ms
        self.originalScale = originalScale  -- Store the original scale
        
        -- Call the callback immediately
        self.onClick()
    end
end

function GaleryIcons:draw()
    if not self.image then return end
    
    -- Calcula o centro da imagem para posicionamento
    local width = self.image:getWidth() * self.currentScale
    local height = self.image:getHeight() * self.currentScale
    
    -- Se estiver com o mouse sobre, desenha uma sombra com pequeno offset
    if self.hover then
        love.graphics.setColor(0, 0, 0, 0.5)  -- sombra semi-transparente
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
    
    -- Desenha a imagem principal
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(
        self.image, 
        self.x, 
        self.y, 
        0, 
        self.currentScale, 
        self.currentScale
    )
    
    -- Se o mouse estiver sobre, exibe o nome abaixo do ícone
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

return {
    Button = Button,
    Selector = Selector,
    Tab = Tab,
    VolumeSlider = VolumeSlider,
    UIColors = UIColors,
    GaleryIcons = GaleryIcons
}