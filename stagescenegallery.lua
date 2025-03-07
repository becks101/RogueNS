-- stagescenegallery.lua
local StageScene = require("stagescenes")
local ButtonTypes = require("button")
local GaleryIcons = ButtonTypes.GaleryIcons

local StageSceneGallery = {}
StageSceneGallery.__index = StageSceneGallery

function StageSceneGallery.new()
    local self = setmetatable({}, StageSceneGallery)
    self.currentTab = "stage"
    self.stageScenesList = {"stages/ss_mast01"}
    self.icons = {}
    self.currentScene = nil  -- Nova propriedade para armazenar a cena ativa
    self.backButton = ButtonTypes.Button.new(20, 20, 100, 40, "Voltar", function()
        self.currentScene = nil
    end)
    self:refreshIcons()
    return self
end

function StageSceneGallery:refreshIcons()
    self.icons = {} -- Resetar ícones
    
    if self.currentTab == "stage" then
        local screenWidth, screenHeight = love.graphics.getDimensions()
        local startX = 50
        local startY = 150
        local spacingX = 120
        local spacingY = 120
        local cols = math.max(1, math.floor((screenWidth - 100) / spacingX))
        
        for i, moduleName in ipairs(self.stageScenesList) do
            local col = (i - 1) % cols
            local row = math.floor((i - 1) / cols)
            local x = startX + col * spacingX
            local y = startY + row * spacingY
            
            local success, sceneData = pcall(require, moduleName)
            if success then
                local icon = GaleryIcons.new(
                    x, y,
                    sceneData.IconeLarge,
                    sceneData.nome,
                    function()
                        -- Cria nova instância ao invés de reusar
                        self.currentScene = StageScene.new(moduleName)
                        self.currentScene:load()
                    end
                )
                table.insert(self.icons, icon)
            else
                print("Erro ao carregar cena:", moduleName, sceneData)
            end
        end
    end
end

function StageSceneGallery:update(dt)
    if self.currentScene then
        self.currentScene:update(dt)
        self.backButton:updateHover(love.mouse.getPosition())
    end
end

function StageSceneGallery:draw()
    if self.currentScene then
        self.currentScene:draw()
        self.backButton:draw()
    end
end

function StageSceneGallery:mousepressed(x, y, button)
    if self.currentScene then
        -- Apenas o botão "Voltar" está ativo durante a visualização da cena
        self.backButton:mousepressed(x, y, button)
    else
        -- Processa cliques nos ícones da galeria
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