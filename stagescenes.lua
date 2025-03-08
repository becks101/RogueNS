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
    local efeito = self.data.Efeitos.efeito1
    
    -- Carregar fundo
    self.background = love.graphics.newImage(efeito.background)
    
    -- Carregar intro (animação inicial)
    self.introSheet = love.graphics.newImage(efeito.intro)
    local introWidth, introHeight = self.introSheet:getDimensions()
    local introFrameWidth = introWidth / 31 -- Supondo 31 frames na intro
    for i = 0, 30 do
        self.introQuads[i+1] = love.graphics.newQuad(
            i * introFrameWidth, 0,
            introFrameWidth, introHeight,
            introWidth, introHeight
        )
    end

    -- Carregar spritesheets do loop
    for _, spritesheetPath in ipairs(efeito.loopSprite) do
        local sheet = love.graphics.newImage(spritesheetPath)
        local sheetWidth, sheetHeight = sheet:getDimensions()
        local frameWidth = sheetWidth / 31 -- 31 frames por spritesheet
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
    end

    self.imagesLoaded = true
    self.state = "intro" -- Começa com a intro
    self.currentFrame = 1
end

function StageScene:selectRandomSpritesheet()
    if #self.spritesheets == 0 then return end
    self.currentSpritesheet = self.spritesheets[math.random(1, #self.spritesheets)]
    self.currentFrame = 1
    self.timer = 0
end

function StageScene:update(dt)
    if not self.imagesLoaded then return end
    
    local efeito = self.data.Efeitos.efeito1
    self.timer = self.timer + dt

    -- Lógica da intro
    if self.state == "intro" then
        if self.timer >= efeito.animationSpeed then
            self.currentFrame = self.currentFrame + 1
            self.timer = 0
            -- Terminou a intro? Inicia o loop
            if self.currentFrame > 31 then
                self.state = "loop"
                self:selectRandomSpritesheet()
            end
        end
    
    -- Lógica do loop
    elseif self.state == "loop" then
        if self.timer >= efeito.animationSpeed then
            self.currentFrame = self.currentFrame + 1
            self.timer = 0
            -- Troca de spritesheet ao terminar
            if self.currentFrame > 31 then
                self:selectRandomSpritesheet()
            end
        end
    end
end

function StageScene:draw()
    if not self.imagesLoaded then return end
    
    local efeito = self.data.Efeitos.efeito1
    local screenWidth, screenHeight = love.graphics.getDimensions()
    local bgWidth, bgHeight = self.background:getDimensions()

    -- 1. Calcula escala do background mantendo aspect ratio
    local bgScale = math.max(
        screenWidth / bgWidth,
        screenHeight / bgHeight
    )
    local scaledBgWidth = bgWidth * bgScale
    local scaledBgHeight = bgHeight * bgScale
    local bgOffsetX = (screenWidth - scaledBgWidth) / 2
    local bgOffsetY = (screenHeight - scaledBgHeight) / 2

    -- Desenha background
    love.graphics.draw(
        self.background,
        bgOffsetX,
        bgOffsetY,
        0,
        bgScale,
        bgScale
    )

    -- 2. Função para posicionamento relativo ao background
    local function getRelativePosition(percentX, percentY)
        return bgOffsetX + (scaledBgWidth * percentX),
               bgOffsetY + (scaledBgHeight * percentY)
    end

    -- 3. Calcula escala dos sprites proporcional ao background
    local baseSpriteScale = efeito.size or 1.0
    local spriteScale = baseSpriteScale * (scaledBgWidth / bgWidth)

    -- 4. Obtém posição do sprite
    local spriteX, spriteY = getRelativePosition(efeito.x, efeito.y)

    -- Desenha animação
    if self.state == "intro" then
        love.graphics.draw(
            self.introSheet,
            self.introQuads[self.currentFrame],
            spriteX,
            spriteY,
            0,
            spriteScale,
            spriteScale
        )
    else
        if self.currentSpritesheet then
            love.graphics.draw(
                self.currentSpritesheet.image,
                self.currentSpritesheet.quads[self.currentFrame],
                spriteX,
                spriteY,
                0,
                spriteScale,
                spriteScale
            )
        end
    end
end

return StageScene