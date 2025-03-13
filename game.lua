-- game.lua - Modificado para usar o novo sistema de gameplay
local Game = {}
Game.__index = Game
local FlagsSystem = require "flagsSystem"
local Gameplay = require "gameplay"
local Config = require "config"

function Game.new()
    local self = setmetatable({}, Game)
    self.state = "menu"  -- Estados possíveis: "menu", "playing", "paused"
    self.currentLevel = nil
    
    -- Dimensões do jogo
    self.screenWidth, self.screenHeight = love.graphics.getDimensions()
    
    -- Configuração de posicionamento
    self.positionRatioX = 0.5  -- 50% da largura da tela
    self.positionRatioY = 0.5  -- 50% da altura da tela
    
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
    
    -- Calcula dimensões da área de jogo com posicionamento proporcional para ambos os modos
    local minGameWidth = 160  -- Largura mínima em pixels 
    local maxGameWidth = 200  -- Largura máxima em pixels
    
    -- Cálculo proporcional com limites
    self.gameWidth = math.max(minGameWidth, math.min(self.screenWidth * 0.15, maxGameWidth))
    self.gameHeight = self.screenHeight - 20  -- Quase toda a altura com margem pequena
    
    -- Posiciona à direita com margem fixa de pixels
    self.gameOffsetX = self.screenWidth - self.gameWidth - 20  -- 20 pixels de margem à direita
    self.gameOffsetY = 10  -- 10 pixels de margem superior
    
    -- Inicializa o gameplay com essas dimensões
    Gameplay.setDimensoes(self.gameWidth, self.gameHeight)
    Gameplay.setOffset(self.gameOffsetX, self.gameOffsetY)
    
    -- Carrega estado salvo de flags e achievements
    FlagsSystem.loadState()
    
    return self
end

-- Permite configurar o posicionamento do centro do jogo
function Game:setCirclePosition(ratioX, ratioY)
    self.positionRatioX = ratioX
    self.positionRatioY = ratioY
    
    -- Não afeta mais o posicionamento do gameplay, mantido para compatibilidade
    -- O gameplay agora tem posição fixa na direita da tela
end

-- Carrega um nível
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
    
    -- Configura parâmetros adicionais para o novo gameplay
    if not level.velocidade then
        -- Configura velocidade baseada no BPM se não estiver definida
        level.velocidade = (level.bpm or 90) * 2
    end
    
    if not level.intervalo then
        -- Calcula intervalo baseado no BPM (60/BPM = duração de um beat em segundos)
        level.intervalo = 60 / (level.bpm or 90)
    end
    
    -- Adiciona dificuldade baseada no BPM se não estiver definida
    if not level.dificuldade then
        level.dificuldade = math.floor((level.bpm or 90) / 30)
    end
    
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
        
        -- Atualiza dados do sistema de flags com informações do gameplay
        FlagsSystem.updateRhythmGameData(Gameplay)
        
        -- Verifica achievements em tempo real
        if self.currentLevel then
            FlagsSystem.checkRealTimeAchievements(self.currentLevel)
        end
        
        -- Atualiza o gameplay
        local result = Gameplay.atualizar(dt, 0)
        
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
        -- Desenha a stage scene primeiro como background ocupando a tela inteira
        if self.stageScene then
            -- Sem scissor para permitir que ocupe toda a tela
            self.stageScene:draw()
        end
        
        -- Depois desenha o gameplay como overlay na área direita designada
        Gameplay.desenhar(true) -- true para desenhar UI
    end
end

function Game:keypressed(key)
    if self.state == "playing" then
        if key == "escape" then
            self.state = "menu"
        else
            -- Passa as teclas para o gameplay
            Gameplay.keypressed(key)
        end
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
    -- Atualiza as dimensões
    self.screenWidth = w
    self.screenHeight = h
    
    -- Recalcula com valores fixos em pixels ao invés de proporções
    local minGameWidth = 160  -- Largura mínima em pixels 
    local maxGameWidth = 200  -- Largura máxima em pixels
    
    -- Cálculo proporcional com limites
    self.gameWidth = math.max(minGameWidth, math.min(self.screenWidth * 0.15, maxGameWidth))
    self.gameHeight = self.screenHeight - 20  -- Quase toda a altura com margem pequena
    
    -- Posiciona à direita com margem fixa de pixels
    self.gameOffsetX = self.screenWidth - self.gameWidth - 20  -- 20 pixels de margem à direita
    self.gameOffsetY = 10  -- 10 pixels de margem superior
    
    -- Atualiza o gameplay
    Gameplay.setDimensoes(self.gameWidth, self.gameHeight)
    Gameplay.setOffset(self.gameOffsetX, self.gameOffsetY)
    
    -- Notifica o sistema de que o tamanho da tela mudou
    if self.stageScene and self.stageScene.resize then
        self.stageScene:resize(w, h)
    end
    
    -- Notifica o gameplay sobre o redimensionamento
    Gameplay.onResize()
end

-- Implementa os métodos do Game para criar fases, compatível com o novo gameplay
-- Retorna um novo criador de níveis
function Game.newLevelCreator(larguraTela, alturaTela)
    local levelCreator = {}
    
    -- Dimensões da tela para referência
    levelCreator.larguraTela = larguraTela
    levelCreator.alturaTela = alturaTela
    
    -- Definições padrões para fases
    levelCreator.cores = {
        {0.92, 0.7, 0.85},  -- Rosa pastel suave
        {0.7, 0.9, 0.8},    -- Verde mint pastel
        {0.7, 0.8, 0.95},   -- Azul céu pastel
        {0.97, 0.9, 0.7}    -- Amarelo pastel suave
    }
    
    -- As 4 posições possíveis para os blocos
    levelCreator.posicoesX = {
        larguraTela * 0.2,
        larguraTela * 0.4, 
        larguraTela * 0.6,
        larguraTela * 0.8
    }
    
    -- Cria uma nova fase com configurações específicas
    levelCreator.createLevel = function(config)
        local nivel = {}
        
        -- Configurações de dificuldade
        nivel.dificuldade = config.dificuldade or 1
        nivel.velocidade = config.velocidade or 200
        nivel.intervalo = config.intervalo or 1.0
        nivel.nome = config.nome or "Fase sem nome"
        nivel.duracao = config.duracao or 60
        
        -- Posições dos blocos
        nivel.posicoesX = config.posicoesX or levelCreator.posicoesX
        
        -- Cores dos blocos
        nivel.cores = config.cores or levelCreator.cores
        
        -- Padrões de blocos
        nivel.padroes = config.padroes or levelCreator.gerarPadroesAleatorios(nivel.dificuldade)
        
        return nivel
    end
    
    -- Gera padrões aleatórios de blocos baseados na dificuldade
    levelCreator.gerarPadroesAleatorios = function(dificuldade)
        local padroes = {}
        
        -- Quanto maior a dificuldade, mais padrões complexos
        local numPadroes = 5 + dificuldade * 2
        
        for i = 1, numPadroes do
            local padrao = {}
            local tamanhoPadrao = math.random(3, 5 + dificuldade)
            
            for j = 1, tamanhoPadrao do
                table.insert(padrao, {
                    posicao = math.random(1, 4),
                    cor = math.random(1, 4),
                    tempo = j * (0.8 - dificuldade * 0.1) -- Intervalo vai diminuindo com a dificuldade
                })
            end
            
            table.insert(padroes, padrao)
        end
        
        return padroes
    end
    
    return levelCreator
end

-- Retorna um novo gerador de fases
function Game.newPhaseGenerator()
    local phaseGenerator = {}
    
    -- Gera uma seed aleatória para a run atual com 9 dígitos
    phaseGenerator.runSeed = math.random(100000000, 999999999)
    
    -- Diretório onde as definições de fase estão armazenadas
    phaseGenerator.levelsDirectory = "levels/"
    
    -- Cache de fases carregadas
    phaseGenerator.loadedPhases = {}
    
    -- Define uma nova seed para a run atual
    phaseGenerator.setRunSeed = function(seed)
        phaseGenerator.runSeed = seed
    end
    
    -- Obtém a seed da run atual
    phaseGenerator.getRunSeed = function()
        return phaseGenerator.runSeed
    end
    
    -- Carrega uma definição de fase de um arquivo
    phaseGenerator.loadPhaseDefinition = function(phaseName)
        -- Verifica se a fase já está em cache
        if phaseGenerator.loadedPhases[phaseName] then
            return phaseGenerator.loadedPhases[phaseName]
        end
        
        -- Caminho para o arquivo de definição da fase
        local filePath = phaseGenerator.levelsDirectory .. phaseName .. ".lua"
        
        -- Tenta carregar o arquivo
        local success, phaseDefinition = pcall(function()
            return love.filesystem.load(filePath)()
        end)
        
        if success then
            -- Armazena em cache para uso futuro
            phaseGenerator.loadedPhases[phaseName] = phaseDefinition
            return phaseDefinition
        else
            print("Erro ao carregar definição de fase: " .. phaseName)
            print(phaseDefinition) -- Imprime o erro
            return nil
        end
    end
    
    -- Gera uma fase com base na definição de fase e seed da run
    phaseGenerator.generatePhase = function(levelCreator, phaseName)
        -- Carrega a definição da fase
        local phaseDefinition = phaseGenerator.loadPhaseDefinition(phaseName)
        if not phaseDefinition then
            print("Fase não encontrada: " .. phaseName)
            return nil
        end
        
        -- Se a fase_seed não estiver definida, cria uma com base no nome da fase
        if not phaseDefinition.fase_seed then
            local hash = 0
            for i = 1, #phaseName do
                hash = (hash * 31 + string.byte(phaseName, i)) % 1000000000
            end
            phaseDefinition.fase_seed = hash
            print("Seed automática criada para " .. phaseName .. ": " .. hash)
        end
        
        -- Combina a seed da fase com a seed da run para criar uma seed única
        local combinedSeed = phaseDefinition.fase_seed * phaseGenerator.runSeed
        math.randomseed(combinedSeed)
        
        -- Calcula a velocidade dos blocos com base no BPM
        local velocidade = phaseDefinition.bpm * 2
        
        -- Calcula o intervalo entre blocos (em segundos) com base no BPM
        -- 60 / BPM = duração de um beat em segundos
        local intervalo = 60 / phaseDefinition.bpm
        
        -- Cria configurações para o levelCreator
        local config = {
            velocidade = phaseDefinition.velocidade or velocidade,
            intervalo = phaseDefinition.intervalo or intervalo,
            dificuldade = phaseDefinition.dificuldade or math.floor(phaseDefinition.bpm / 30),
            duracao = phaseDefinition.duracao,
            nome = phaseDefinition.nome or phaseName,
            cores = phaseDefinition.cores
        }
        
        -- Usa o levelCreator para criar o nível com as configurações calculadas
        local nivel = levelCreator.createLevel(config)
        
        -- Adiciona metadados da fase ao nível
        nivel.phaseDefinition = phaseDefinition
        nivel.phaseName = phaseName
        nivel.phaseSeed = phaseDefinition.fase_seed
        nivel.runSeed = phaseGenerator.runSeed
        nivel.combinedSeed = combinedSeed
        
        -- Copia os dados originais da fase para compatibilidade com o sistema antigo
        nivel.bpm = phaseDefinition.bpm
        nivel.duracao = phaseDefinition.duracao
        nivel.animation = phaseDefinition.animation
        nivel.achievements = phaseDefinition.achievements
        
        -- Restaura a seed aleatória
        math.randomseed(os.time())
        
        return nivel
    end
    
    -- Lista todas as fases disponíveis no diretório de levels
    phaseGenerator.listAvailablePhases = function()
        local phases = {}
        
        -- Verifica se o diretório existe
        local info = love.filesystem.getInfo(phaseGenerator.levelsDirectory)
        if not info or info.type ~= "directory" then
            -- Cria o diretório se não existir
            love.filesystem.createDirectory(phaseGenerator.levelsDirectory)
            return phases
        end
        
        -- Lista todos os arquivos no diretório
        local files = love.filesystem.getDirectoryItems(phaseGenerator.levelsDirectory)
        for _, file in ipairs(files) do
            -- Verifica se é um arquivo Lua
            if file:match("%.lua$") then
                -- Remove a extensão .lua
                local phaseName = file:gsub("%.lua$", "")
                table.insert(phases, phaseName)
            end
        end
        
        return phases
    end
    
    -- Cria um arquivo de fase de exemplo se não existir nenhum
    phaseGenerator.createExamplePhase = function()
        local examplePath = phaseGenerator.levelsDirectory .. "ExemploDeFase01.lua"
        local info = love.filesystem.getInfo(examplePath)
        
        if not info then
            local content = [[
-- ExemploDeFase01.lua
-- Exemplo de fase para o jogo de ritmo no novo sistema

local fase = {
    nome = "Tutorial 01",
    bpm = 90,      -- Define a velocidade base (beats per minute)
    duracao = 50,  -- Duração da fase em segundos
    fase_seed = 13312212,  -- Seed usada para geração de padrões
    
    -- Parâmetros específicos do novo sistema
    velocidade = 180,  -- Velocidade de queda dos blocos
    intervalo = 0.7,   -- Intervalo entre blocos em segundos
    dificuldade = 1,   -- Nível de dificuldade
    
    -- Cores customizadas (opcional)
    cores = {
        {0.92, 0.7, 0.85},  -- Rosa pastel suave
        {0.7, 0.9, 0.8},    -- Verde mint pastel
        {0.7, 0.8, 0.95},   -- Azul céu pastel
        {0.97, 0.9, 0.7}    -- Amarelo pastel suave
    },
    
    -- Animação inicial do tutorial
    animation = "stages/ss_mast01",
    
    -- Achievements do tutorial (mais fáceis)
    achievements = {
        {
            id = "Primeira Fase Completa",
            condition = "musica_terminada",
            value = true,
            reward_type = "fase",
            reward_value = "exemploDeFase01"
        },
        {
            id = "Primeiros Passos",
            condition = "pontuacao_minima",
            value = 100,
            reward_type = "cutscene",
            reward_value = "cutscenes/chapter1"
        }
    }
}

return fase
]]
            love.filesystem.write(examplePath, content)
            print("Fase de exemplo criada em: " .. examplePath)
        end
    end
    
    -- Gera uma nova seed aleatória para a run
    phaseGenerator.generateNewRunSeed = function()
        phaseGenerator.runSeed = math.random(100000000, 999999999)
        return phaseGenerator.runSeed
    end
    
    return phaseGenerator
end

-- Funções de formatação de seed para exibição
function Game.formatSeed(seed)
    local seedStr = tostring(seed)
    local formatted = ""
    
    -- Adiciona zeros à esquerda se necessário para garantir 9 dígitos
    while #seedStr < 9 do
        seedStr = "0" .. seedStr
    end
    
    -- Formata como XXX-XXX-XXX para melhor leitura
    formatted = string.sub(seedStr, 1, 3) .. "-" .. 
                string.sub(seedStr, 4, 6) .. "-" .. 
                string.sub(seedStr, 7, 9)
    
    return formatted
end

return Game