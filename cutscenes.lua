-- cutscenes.lua
-- Módulo para gerenciar e exibir cutscenes com diálogos, escolhas e sprites animados
local Cutscenes = {}
Cutscenes.__index = Cutscenes

-- Constantes para configuração da interface
local DIALOG_HEIGHT = 150
local TEXT_PADDING = 20
local CHOICE_PADDING = 10
local PORTRAIT_SIZE = 120

-- Função para sanitizar o texto e evitar erros de UTF-8
local function sanitizeText(text)
    if not text then return "" end
    
    -- Remove caracteres inválidos UTF-8
    local sanitized = ""
    for i = 1, #text do
        local c = text:sub(i, i)
        if c:byte() < 0x80 or (c:byte() >= 0xC0 and c:byte() < 0xF8) then
            sanitized = sanitized .. c
        end
    end
    
    return sanitized
end

function Cutscenes.new(cutsceneFile)
    local self = setmetatable({}, Cutscenes)
    
    -- Estado da cutscene
    self.isActive = false
    self.currentStep = 1
    self.dialogText = ""
    self.displayedText = ""
    self.textSpeed = 30 -- caracteres por segundo
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
    
    -- Para efeitos de transição
    self.fadeAlpha = 1
    self.fadeState = "in" -- "in", "hold", "out"
    self.fadeSpeed = 1
    
    return self
end

function Cutscenes:load()
    -- Carrega os dados da cutscene do arquivo especificado
    local success, cutsceneData = pcall(require, self.cutsceneFile)
    
    if not success then
        print("Erro ao carregar cutscene:", self.cutsceneFile, cutsceneData)
        return false
    end
    
    self.data = cutsceneData
    self.isActive = true
    self.currentStep = 1
    self.levelToLoad = nil
    self.selectedLevel = nil
    
    -- Carrega o background inicial se existir
    if cutsceneData.background then
        self.background = love.graphics.newImage(cutsceneData.background)
    end
    
    -- Carrega os retratos dos personagens
    if cutsceneData.characters then
        for name, data in pairs(cutsceneData.characters) do
            if data.portrait then
                self.portraits[name] = love.graphics.newImage(data.portrait)
            end
        end
    end
    
    -- Inicia a primeira etapa da cutscene
    self:processCurrentStep()
    
    return true
end

function Cutscenes:processCurrentStep()
    if not self.data or not self.data.steps or self.currentStep > #self.data.steps then
        -- Finaliza a cutscene se não houver mais etapas
        self:complete()
        return
    end
    
    local step = self.data.steps[self.currentStep]
    
    -- Sanitiza o texto para evitar erros de UTF-8
    self.dialogText = sanitizeText(step.text or "")
    self.displayedText = ""
    self.textComplete = false
    self.textTimer = 0
    
    -- Atualiza o background se especificado nesta etapa
    if step.background then
        self.background = love.graphics.newImage(step.background)
    end
    
    -- Configura os sprites visíveis nesta etapa
    if step.sprites then
        self.sprites = {}
        for i, spriteData in ipairs(step.sprites) do
            local sprite = {
                image = love.graphics.newImage(spriteData.image),
                x = spriteData.x or 0.5,
                y = spriteData.y or 0.5,
                scale = spriteData.scale or 1,
                flip = spriteData.flip or false,
                -- Novos parâmetros para animação
                animated = spriteData.animated or false,
                framesH = spriteData.framesH or 1,
                framesV = spriteData.framesV or 1,
                frameDelay = spriteData.frameDelay or 0.2,
                currentFrame = 1,
                frameTimer = 0
            }
            
            if sprite.animated then
                -- Calcula a largura e altura de cada frame
                sprite.frameWidth = sprite.image:getWidth() / sprite.framesH
                sprite.frameHeight = sprite.image:getHeight() / sprite.framesV
                sprite.totalFrames = sprite.framesH * sprite.framesV
                
                -- Cria quads para cada frame da animação
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
        end
    end
    
    -- Configura as escolhas, se houver
    if step.choices then
        -- Sanitiza o texto das escolhas
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
    
    -- Configura o personagem falante, se houver
    self.speaker = step.speaker
    
    -- Verifica se este passo tem uma ação a ser executada
    if step.action and step.action == "startLevel" and step.levelPath then
        self.levelToLoad = step.levelPath
        -- A ação será executada quando o texto for apresentado completamente
    end
end

function Cutscenes:update(dt)
    if not self.isActive then return end
    
    -- Atualiza a transição de fade
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
    
    -- Atualiza animações dos sprites
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
    
    -- Atualiza a animação do texto
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

function Cutscenes:draw()
    if not self.isActive then 
        return -- Retorna imediatamente se a cutscene não estiver ativa
    end
    
    local screenWidth, screenHeight = love.graphics.getDimensions()
    
    -- Desenha o background, se existir, ajustando para fullscreen
    if self.background then
        love.graphics.setColor(1, 1, 1)
        local bgScaleX = screenWidth / self.background:getWidth()
        local bgScaleY = screenHeight / self.background:getHeight()
        love.graphics.draw(self.background, 0, 0, 0, bgScaleX, bgScaleY)
    end
    
    -- Desenha os sprites da cena
    for _, sprite in ipairs(self.sprites) do
        love.graphics.setColor(1, 1, 1)
        local posX = sprite.x * screenWidth
        local posY = sprite.y * screenHeight
        
        local scaleX = sprite.scale
        if sprite.flip then scaleX = -scaleX end
        
        if sprite.animated and sprite.quads then
            -- Desenha o frame atual para sprites animados
            local currentQuad = sprite.quads[sprite.currentFrame]
            love.graphics.draw(
                sprite.image, 
                currentQuad,
                posX, 
                posY, 
                0, 
                scaleX, 
                sprite.scale,
                sprite.frameWidth / 2,
                sprite.frameHeight / 2
            )
        else
            -- Desenha sprites não animados
            love.graphics.draw(
                sprite.image, 
                posX, 
                posY, 
                0, 
                scaleX, 
                sprite.scale,
                sprite.image:getWidth() / 2,
                sprite.image:getHeight() / 2
            )
        end
    end
    
    -- Desenha a caixa de diálogo
    love.graphics.setColor(0, 0, 0, 0.8)
    love.graphics.rectangle("fill", 0, screenHeight - DIALOG_HEIGHT, 
                          screenWidth, DIALOG_HEIGHT)
    
    -- Desenha o retrato do personagem, se existir
    if self.speaker and self.portraits[self.speaker] then
        love.graphics.setColor(1, 1, 1)
        love.graphics.draw(self.portraits[self.speaker], 
                          TEXT_PADDING, screenHeight - DIALOG_HEIGHT + TEXT_PADDING, 0,
                          PORTRAIT_SIZE / self.portraits[self.speaker]:getWidth(),
                          PORTRAIT_SIZE / self.portraits[self.speaker]:getHeight())
    end
    
    -- Desenha o nome do personagem, se existir
    if self.speaker and self.data.characters and self.data.characters[self.speaker] then
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(self.data.characters[self.speaker].name or self.speaker, 
                           TEXT_PADDING * 2 + PORTRAIT_SIZE, 
                           screenHeight - DIALOG_HEIGHT + TEXT_PADDING)
    end
    
    -- Desenha o texto do diálogo
    love.graphics.setColor(1, 1, 1)
    local textX = TEXT_PADDING
    if self.speaker and self.portraits[self.speaker] then
        textX = TEXT_PADDING * 2 + PORTRAIT_SIZE
    end
    
    -- Usa pcall para capturar erros durante a renderização do texto
    local success, errorMsg = pcall(function()
        love.graphics.printf(
            self.displayedText, 
            textX, screenHeight - DIALOG_HEIGHT + TEXT_PADDING * 3,
            screenWidth - textX - TEXT_PADDING, "left")
    end)

    -- Se houver erro, tenta novamente com uma versão ainda mais sanitizada do texto
    if not success then
        local emergencyText = ""
        for i = 1, #self.displayedText do
            local c = self.displayedText:sub(i, i)
            if c:byte() < 128 then -- Usa apenas ASCII
                emergencyText = emergencyText .. c
            else
                emergencyText = emergencyText .. "?" -- Substitui caracteres não-ASCII
            end
        end
        
        love.graphics.printf(
            emergencyText,
            textX, screenHeight - DIALOG_HEIGHT + TEXT_PADDING * 3,
            screenWidth - textX - TEXT_PADDING, "left")
    end
    
    -- Desenha "Continuar" ou as escolhas
    if self.textComplete then
        if self.waitingForChoice and #self.choices > 0 then
            -- Desenha as opções de escolha
            local choiceY = screenHeight - DIALOG_HEIGHT / 2
            for i, choice in ipairs(self.choices) do
                love.graphics.setColor(0.3, 0.3, 0.3, 0.8)
                
                -- Usa pcall para evitar erros ao obter a largura do texto
                local choiceWidth
                local success, result = pcall(function()
                    return love.graphics.getFont():getWidth(choice.text) + CHOICE_PADDING * 2
                end)
                
                if success then
                    choiceWidth = result
                else
                    -- Valor padrão caso ocorra erro
                    choiceWidth = 200
                end
                
                local choiceHeight = love.graphics.getFont():getHeight() + CHOICE_PADDING
                local choiceX = screenWidth / 2 - choiceWidth / 2
                
                -- Ajusta a posição Y com base no número de escolhas
                local offsetY = (-#self.choices / 2 + (i - 1)) * (choiceHeight + CHOICE_PADDING)
                local currentChoiceY = choiceY + offsetY
                
                love.graphics.rectangle("fill", choiceX, currentChoiceY, choiceWidth, choiceHeight)
                
                love.graphics.setColor(1, 1, 1)
                -- Usa pcall novamente ao desenhar o texto
                pcall(function()
                    love.graphics.print(choice.text, 
                                      choiceX + CHOICE_PADDING, 
                                      currentChoiceY + CHOICE_PADDING / 2)
                end)
            end
        else
            -- Desenha indicador de "Continuar"
            love.graphics.setColor(1, 1, 1)
            love.graphics.print("Pressione [ESPAÇO] para continuar", 
                              screenWidth - 250, screenHeight - TEXT_PADDING * 2)
        end
    end
    
    -- Desenha o efeito de fade
    if self.fadeAlpha > 0 then
        love.graphics.setColor(0, 0, 0, self.fadeAlpha)
        love.graphics.rectangle("fill", 0, 0, screenWidth, screenHeight)
    end
end

function Cutscenes:mousepressed(x, y, button)
    if not self.isActive or button ~= 1 then return end
    
    -- Se estamos esperando uma escolha e o texto está completo
    if self.waitingForChoice and self.textComplete then
        local screenWidth, screenHeight = love.graphics.getDimensions()
        local choiceY = screenHeight - DIALOG_HEIGHT / 2
        
        for i, choice in ipairs(self.choices) do
            -- Usa pcall para evitar erros ao obter a largura do texto
            local choiceWidth
            local success, result = pcall(function()
                return love.graphics.getFont():getWidth(choice.text) + CHOICE_PADDING * 2
            end)
            
            if success then
                choiceWidth = result
            else
                -- Valor padrão caso ocorra erro
                choiceWidth = 200
            end
            
            local choiceHeight = love.graphics.getFont():getHeight() + CHOICE_PADDING
            local choiceX = screenWidth / 2 - choiceWidth / 2
            
            -- Ajusta a posição Y com base no número de escolhas
            local offsetY = (-#self.choices / 2 + (i - 1)) * (choiceHeight + CHOICE_PADDING)
            local currentChoiceY = choiceY + offsetY
            
            -- Verifica se o clique foi dentro da área da escolha
            if x >= choiceX and x <= choiceX + choiceWidth and
               y >= currentChoiceY and y <= currentChoiceY + choiceHeight then
                -- Executa a ação associada à escolha
                
                -- Processa ação especial se existir
                if choice.action and choice.action == "startLevel" and choice.levelPath then
                    self.levelToLoad = choice.levelPath
                end
                
                -- Vai para o próximo passo, se especificado
                if choice.nextStep then
                    self.currentStep = choice.nextStep
                    self.waitingForChoice = false
                    self:processCurrentStep()
                    return
                end
            end
        end
    else
        -- Se o texto ainda não está completo, completa-o
        if not self.textComplete then
            self.displayedText = self.dialogText
            self.textComplete = true
        else
            -- Se há uma ação para este passo, executa-a
            if self.levelToLoad then
                self.selectedLevel = self.levelToLoad
                -- Armazena o nível a ser carregado e finaliza a cutscene
                self:complete()
                return
            end
            
            -- Avança para a próxima etapa
            if not self.waitingForChoice then
                self.currentStep = self.currentStep + 1
                self:processCurrentStep()
            end
        end
    end
end

function Cutscenes:keypressed(key)
    if not self.isActive then return end
    
    if key == "space" or key == "return" then
        -- Comportamento similar ao mousepressed
        if not self.textComplete then
            self.displayedText = self.dialogText
            self.textComplete = true
        else
            -- Se há uma ação para este passo, executa-a
            if self.levelToLoad then
                self.selectedLevel = self.levelToLoad
                -- Armazena o nível a ser carregado e finaliza a cutscene
                self:complete()
                return
            end
            
            -- Só avança se não estiver esperando uma escolha
            if not self.waitingForChoice then
                self.currentStep = self.currentStep + 1
                self:processCurrentStep()
            end
        end
    end
    
    -- Adicione teclas para pular a cutscene inteira
    if key == "escape" then
        self.fadeState = "out"
    end
end

function Cutscenes:complete()
    self.isActive = false
    if self.onComplete then
        self.onComplete()
    end
end

return Cutscenes