-- galeryManager.lua (anteriormente stagescenegallery.lua)
local StageScene = require("stagescenes")
local Cutscenes = require("cutscenes")
local ButtonTypes = require("button")
local GaleryIcons = ButtonTypes.GaleryIcons

local GaleryManager = {}
GaleryManager.__index = GaleryManager

function GaleryManager.new()
    local self = setmetatable({}, GaleryManager)
    self.currentTab = "stage" -- Padrão: abas de stage
    
    -- Listas de itens por categoria
    self.stageScenesList = {"stages/ss_mast01"}
    self.cutscenesList = {"cutscenes/intro", "cutscenes/chapter1"}
    self.itemsList = {"items/item1", "items/item2"}
    
    self.icons = {}
    self.currentScene = nil -- Armazena a cena ativa (stage scene ou cutscene)
    self.sceneType = nil -- Tipo da cena atual ("stage" ou "cutscene")
    
    -- Botão de voltar para retornar da visualização
    self.backButton = ButtonTypes.Button.new(20, 20, 100, 40, "Voltar", function()
        self.currentScene = nil
        self.sceneType = nil
    end)
    
    self:refreshIcons()
    return self
end

function GaleryManager:refreshIcons()
    self.icons = {} -- Resetar ícones
    
    local screenWidth, screenHeight = love.graphics.getDimensions()
    local startX = 50
    local startY = 150
    local spacingX = 120
    local spacingY = 120
    local cols = math.max(1, math.floor((screenWidth - 100) / spacingX))
    
    -- Lista de itens atual com base na aba selecionada
    local currentList = {}
    if self.currentTab == "stage" then
        currentList = self.stageScenesList
    elseif self.currentTab == "cutscenes" then
        currentList = self.cutscenesList
    elseif self.currentTab == "items" then
        currentList = self.itemsList
    end
    
    -- Criação de ícones para a lista atual
    for i, moduleName in ipairs(currentList) do
        local col = (i - 1) % cols
        local row = math.floor((i - 1) / cols)
        local x = startX + col * spacingX
        local y = startY + row * spacingY
        
        -- Tenta carregar o módulo para obter os dados
        local success, itemData = pcall(require, moduleName)
        if success then
            local icon = GaleryIcons.new(
                x, y,
                itemData.IconeLarge,
                itemData.nome,
                function()
                    -- Callback diferente com base no tipo de conteúdo
                    if self.currentTab == "stage" then
                        self.currentScene = StageScene.new(moduleName)
                        self.sceneType = "stage"
                        self.currentScene:load()
                    elseif self.currentTab == "cutscenes" then
                        self.currentScene = Cutscenes.new(moduleName)
                        self.sceneType = "cutscene"
                        self.currentScene:load()
                    elseif self.currentTab == "items" then
                        -- Para itens, poderia mostrar apenas uma imagem e texto
                        -- ou implementar um visualizador de item no futuro
                        print("Visualizador de item não implementado ainda")
                    end
                end
            )
            table.insert(self.icons, icon)
        else
            print("Erro ao carregar item:", moduleName, itemData)
        end
    end
end

function GaleryManager:update(dt)
    if self.currentScene then
        self.currentScene:update(dt)
        self.backButton:updateHover(love.mouse.getPosition())
    end
end

function GaleryManager:draw()
    if self.currentScene then
        self.currentScene:draw()
        self.backButton:draw()
    end
end

function GaleryManager:mousepressed(x, y, button)
    if self.currentScene then
        -- Apenas o botão "Voltar" está ativo durante a visualização da cena
        self.backButton:mousepressed(x, y, button)
        
        -- Também passa o evento para a cena atual se ela precisar
        if self.sceneType == "cutscene" then
            -- As cutscenes precisam receber eventos de mouse para processar escolhas
            self.currentScene:mousepressed(x, y, button)
        end
    else
        -- Processa cliques nos ícones da galeria
        for _, icon in ipairs(self.icons) do
            icon:mousepressed(x, y, button)
        end
    end
end

function GaleryManager:mousereleased(x, y, button)
    if self.currentScene then
        if self.currentScene.mousereleased then
            self.currentScene:mousereleased(x, y, button)
        end
    end
end

function GaleryManager:keypressed(key)
    if self.currentScene and self.sceneType == "cutscene" then
        -- As cutscenes precisam de eventos de teclado para avançar
        self.currentScene:keypressed(key)
    end
end

return GaleryManager