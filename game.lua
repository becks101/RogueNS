-- game.lua - Atualizado com posicionamento personalizado e correção da renderização da stage scene
-- Módulo para gerenciar o estado do jogo e interações com o gameplay

local Game = {}
Game.__index = Game
local FlagsSystem = require "flagsSystem"
local Gameplay = require "gameplay"
local Config = require "config"

function Game.new()
    local self = setmetatable({}, Game)
    self.state = "menu"  -- Estados possíveis: "menu", "playing", "paused"
    self.currentLevel = nil
    self.escudoAngle = 180 -- Ângulo inicial do escudo
    self.escudoSpeed = 120 -- Velocidade de rotação em graus por segundo
    
    -- Armazena as dimensões da tela para cálculos de escala
    self.screenWidth, self.screenHeight = love.graphics.getDimensions()
    
    -- Configurações de layout de referência (para uma tela 800x600)
    self.baseWidth = 800
    self.baseHeight = 600
    
    -- Configuração de posicionamento
    self.positionRatioX = 0.98  -- 80% da largura da tela
    self.positionRatioY = 0.98  -- 80% da altura da tela
    
    -- Configura callbacks do sistema de flags
    FlagsSystem.callbacks.onStageSceneUnlocked = function(sceneId)
        -- Adicionar lógica para desbloquear uma stage scene na galeria
        print("Stage scene desbloqueada: " .. sceneId)
    end
    
    FlagsSystem.callbacks.onCutsceneUnlocked = function(cutsceneId)
        -- Adicionar lógica para desbloquear uma cutscene na galeria
        print("Cutscene desbloqueada: " .. cutsceneId)
    end
    
    FlagsSystem.callbacks.onFaseUnlocked = function(faseId)
        -- Adicionar lógica para desbloquear uma fase
        print("Fase desbloqueada: " .. faseId)
    end
    
    -- Aplica configurações iniciais ao gameplay
    self:updateGameplayDimensions()
    
    -- Carrega estado salvo de flags e achievements
    FlagsSystem.loadState()
    
    return self
end

-- Permite configurar o posicionamento do centro dos círculos
function Game:setCirclePosition(ratioX, ratioY)
    self.positionRatioX = ratioX
    self.positionRatioY = ratioY
    self:updateGameplayDimensions()
end

-- Atualiza as dimensões e posições do gameplay quando a tela muda
function Game:updateGameplayDimensions()
    self.screenWidth, self.screenHeight = love.graphics.getDimensions()
    
    -- Calcula fator de escala com base na menor dimensão (para manter proporção)
    local scaleFactor = math.min(
        self.screenWidth / self.baseWidth,
        self.screenHeight / self.baseHeight
    )
    
    -- Calcula a posição central com base nas proporções definidas
    local centerX = self.screenWidth * self.positionRatioX
    local centerY = self.screenHeight * self.positionRatioY
    
    -- Define o centro dos círculos
    Gameplay.setCentro(centerX, centerY)
    
    -- Escala os raios e distâncias com base no fator de escala
    Gameplay.setRaioCentral(40 * scaleFactor)
    Gameplay.setRaioExterno(200 * scaleFactor)
    Gameplay.setDistanciaOrigem(1000 * scaleFactor)
    
    -- Define outros parâmetros que podem precisar de escala
    Gameplay.setForcaGravitacional(32000000 * scaleFactor)
    Gameplay.setVelocidadeLaser(20 * scaleFactor)
end

function Game:loadLevel(levelModule)
    -- Remove a extensão .lua se ela já estiver presente no nome do arquivo
    local moduleName = levelModule
    if levelModule:sub(-4) == ".lua" then
        moduleName = levelModule:sub(1, -5)  -- Remove a extensão .lua
    end
    
    local success, level = pcall(require, moduleName)
    if not success then
        print("Erro ao carregar fase:", moduleName, level)
        return false
    end
    
    self.currentLevel = level
    
    -- Reseta dados de jogo no sistema de flags
    FlagsSystem.resetRhythmGameData(level)
    
    -- Carrega a fase no gameplay   
    Gameplay.carregar(level)
    self.state = "playing"
    
    -- Inicia a animação inicial se definida
    if level.animation then
        -- Carrega a stage scene da animação inicial
        local StageScene = require "stagescenes"
        self.stageScene = StageScene.new(level.animation)
        self.stageScene:load()
    end
    
    return true
end

function Game:update(dt)
    if self.state == "playing" then
        -- Se tiver uma animação em execução, atualize-a primeiro
        if self.stageScene then
            self.stageScene:update(dt)
        end
        
        -- Verifica input para movimentação do escudo
        local keyLeft = love.keyboard.isDown("left")
        local keyRight = love.keyboard.isDown("right")
        
        -- Atualiza o ângulo do escudo com base no input
        if keyLeft and not keyRight then
            self.escudoAngle = self.escudoAngle - self.escudoSpeed * dt
            if self.escudoAngle < 180 then self.escudoAngle = 180 end
        elseif keyRight and not keyLeft then
            self.escudoAngle = self.escudoAngle + self.escudoSpeed * dt
            if self.escudoAngle > 270 then self.escudoAngle = 270 end
        end
        
        -- Atualiza dados do sistema de flags com informações do gameplay
        FlagsSystem.updateRhythmGameData(Gameplay)
        
        -- Verifica achievements em tempo real
        if self.currentLevel then
            FlagsSystem.checkRealTimeAchievements(self.currentLevel)
        end
        
        -- Passa o ângulo do escudo para o gameplay
        local result = Gameplay.atualizar(dt, self.escudoAngle)
        
        -- Verifica se a fase foi concluída
        if result == "fase_concluida" then
            -- Finaliza o jogo e verifica todos os achievements
            local nextFase = FlagsSystem.finalizeFase("time")
            FlagsSystem.checkAllAchievements(self.currentLevel)
            FlagsSystem.saveState()
            
            -- Carrega próxima fase ou volta para o menu
            if nextFase then
                self:loadLevel("levels/" .. nextFase)
                return "fase_carregada"
            else
                self.state = "menu"
                return "fase_concluida"
            end
        end
    end
    
    return self.state
end

function Game:draw()
    if self.state == "playing" then
        -- MODIFICAÇÃO AQUI: Desenha a stage scene primeiro como background, se existir
        if self.stageScene then
            self.stageScene:draw()
        end
        
        -- Depois desenha o gameplay por cima da stage scene
        Gameplay.desenhar(true) -- true para desenhar UI
    end
end

function Game:keypressed(key)
    if self.state == "playing" then
        if key == "escape" then
            self.state = "menu"
        end
        -- Outros controles de teclado podem ser adicionados aqui
    end
end

function Game:mousepressed(x, y, button)
    -- Implementação futura se necessário
end

function Game:pause()
    if self.state == "playing" then
        self.state = "paused"
        Gameplay.pausar()
    end
end

function Game:resume()
    if self.state == "paused" then
        self.state = "playing"
        Gameplay.continuar()
    end
end

-- Chamada quando a janela é redimensionada
function Game:resize(w, h)
    -- Se uma fase estiver carregada, recarrega-a para atualizar o layout
    if self.state == "playing" and self.currentLevel then
        Gameplay.onResize()
    end
end

-- Substituição da função updateGameplayDimensions (agora obsoleta)
function Game:updateGameplayDimensions()
    -- Função mantida para compatibilidade, 
    -- mas não faz nada porque a lógica foi movida para o gameplay.carregar
end
return Game