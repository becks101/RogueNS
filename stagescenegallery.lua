-- stagescenegallery.lua
local StageScene = require("stagescenes")
local ButtonTypes = require("button")
local GaleryIcons = ButtonTypes.GaleryIcons

local StageSceneGallery = {}
StageSceneGallery.__index = StageSceneGallery

function StageSceneGallery.new()
    local self = setmetatable({}, StageSceneGallery)
    -- Lista de módulos de stage scene (adicione quantos desejar)
    self.stageScenesList = {
        "stages/ss_mast01"
        -- Exemplo: "SS-OutroStage", "SS-Example", etc.
    }
    self.icons = {}
    self.currentStageScene = nil  -- Armazena a stage scene ativa, se houver
    self:createIcons()
    -- Botão de voltar para a galeria quando uma stage scene estiver ativa
    self.backButton = ButtonTypes.Button.new(10, 10, 100, 40, "Voltar", function()
        self.currentStageScene = nil
    end)
    return self
end

-- Cria os ícones para cada stage scene
function StageSceneGallery:createIcons()
    local startX = 50
    local startY = 50
    local spacingX = 100
    local spacingY = 100
    local cols = 4  -- Número de colunas
    
    for i, moduleName in ipairs(self.stageScenesList) do
        local stageData = require(moduleName)
        local col = ((i - 1) % cols)
        local row = math.floor((i - 1) / cols)
        local x = startX + col * spacingX
        local y = startY + row * spacingY
        
        local icon = GaleryIcons.new(x, y, stageData.IconeLarge, stageData.nome, function()
            self.currentStageScene = StageScene.new(moduleName)
            self.currentStageScene:load()
        end)
        table.insert(self.icons, icon)
    end
end

function StageSceneGallery:update(dt)
    local mx, my = love.mouse.getPosition()
    if self.currentStageScene then
        self.currentStageScene:update(dt)
        self.backButton:updateHover(mx, my)
        if self.backButton.update then self.backButton:update(dt) end
    else
        for _, icon in ipairs(self.icons) do
            icon:updateHover(mx, my)
        end
    end
end

function StageSceneGallery:draw()
    if self.currentStageScene then
        self.currentStageScene:draw()
        self.backButton:draw()
    else
        for _, icon in ipairs(self.icons) do
            icon:draw()
        end
    end
end

function StageSceneGallery:mousepressed(x, y, button)
    if self.currentStageScene then
        self.currentStageScene:mousepressed(x, y, button)
        self.backButton:mousepressed(x, y, button)
    else
        for _, icon in ipairs(self.icons) do
            icon:mousepressed(x, y, button)
        end
    end
end

function StageSceneGallery:mousereleased(x, y, button)
    if self.currentStageScene and self.currentStageScene.mousereleased then
        self.currentStageScene:mousereleased(x, y, button)
    end
end

return StageSceneGallery