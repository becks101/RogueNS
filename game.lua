-- game.lua
--[[
    Central game manager that handles loading levels, updating game state,
    and coordinating between different game systems.
]]

local ScreenUtils = require "screen_utils"
local FlagsSystem = require "flagsSystem"
local Gameplay = require "gameplay"
local Config = require "config"
local ButtonTypes = require "button"

local Game = {}
Game.__index = Game

-- Creates a new game instance
function Game.new()
    local self = setmetatable({}, Game)
    self.state = "menu"  -- States: "menu", "playing", "paused"
    self.currentLevel = nil
    
    -- Positioning configuration
    self.positionRatioX = 0.5  -- 50% of screen width
    self.positionRatioY = 0.5  -- 50% of screen height
    
    -- Pause menu buttons
    self.pauseButtons = {}
    
    -- Calculate game dimensions
    self:calculateDimensions()
    
    -- Configure callbacks for flag system
    self:setupCallbacks()
    
    -- Initialize gameplay with dimensions
    Gameplay.setDimensoes(self.gameWidth, self.gameHeight)
    Gameplay.setOffset(self.gameOffsetX, self.gameOffsetY)
    Gameplay.init() -- Make sure gameplay dimensions are initialized
    
    -- Load saved state
    FlagsSystem.loadState()
    
    -- Initialize pause menu
    self:setupPauseMenu()
    
    return self
end

-- Configura os botões do menu de pausa
function Game:setupPauseMenu()
    -- Limpa os botões existentes
    self.pauseButtons = {}
    
    -- Determina as dimensões dos botões
    local btnWidth, btnHeight = ScreenUtils.getUIElementSize(200, 50)
    local spacing = ScreenUtils.scaleValue(20)
    local startY = ScreenUtils.height / 2 - (btnHeight * 3 + spacing * 2) / 2
    
    -- Botão para Continuar
    table.insert(self.pauseButtons, ButtonTypes.Button.new(
        ScreenUtils.centerElement(btnWidth, btnHeight),
        startY,
        btnWidth,
        btnHeight,
        "Continuar",
        function() 
            self:resume() 
        end
    ))
    
    -- Botão para Reiniciar Fase
    table.insert(self.pauseButtons, ButtonTypes.Button.new(
        ScreenUtils.centerElement(btnWidth, btnHeight),
        startY + btnHeight + spacing,
        btnWidth,
        btnHeight,
        "Reiniciar Fase",
        function() 
            if self.currentLevel then
                local levelPath = self.currentLevelPath
                self:loadLevel(levelPath)
            end
        end
    ))
    
    -- Botão para Voltar ao Menu
    table.insert(self.pauseButtons, ButtonTypes.Button.new(
        ScreenUtils.centerElement(btnWidth, btnHeight),
        startY + (btnHeight + spacing) * 2,
        btnWidth,
        btnHeight,
        "Voltar ao Menu",
        function() 
            self.state = "menu"
        end
    ))
end

-- Calculates game dimensions based on screen size
function Game:calculateDimensions()
    -- Fixed constraints for game area
    local minGameWidth = 160  -- Minimum width in pixels 
    local maxGameWidth = 200  -- Maximum width in pixels
    
    -- Calculate proportional width with limits
    self.gameWidth = math.max(minGameWidth, math.min(ScreenUtils.width * 0.15, maxGameWidth))
    
    -- Calculate height with margin
    self.gameHeight = ScreenUtils.height - 20
    
    -- Position at right side with fixed margin
    self.gameOffsetX = ScreenUtils.width - self.gameWidth - 20
    self.gameOffsetY = 10
end

-- Sets up flag system callbacks
function Game:setupCallbacks()
    FlagsSystem.callbacks.onStageSceneUnlocked = function(sceneId)
        -- Logic for unlocking stage scene in gallery
        print("Stage scene unlocked: " .. sceneId)
    end
    
    FlagsSystem.callbacks.onCutsceneUnlocked = function(cutsceneId)
        -- Logic for unlocking cutscene in gallery
        print("Cutscene unlocked: " .. cutsceneId)
    end
    
    FlagsSystem.callbacks.onFaseUnlocked = function(faseId)
        -- Logic for unlocking level
        print("Level unlocked: " .. faseId)
    end
end

-- Sets the position of the game circle (compatibility function)
function Game:setCirclePosition(ratioX, ratioY)
    self.positionRatioX = ratioX
    self.positionRatioY = ratioY
end

-- Loads a level
function Game:loadLevel(levelModule)
    -- Remove file extension if present
    local moduleName = levelModule
    if levelModule:sub(-4) == ".lua" then
        moduleName = levelModule:sub(1, -5)
    end
    
    -- Guarda o caminho do nível para reiniciar se necessário
    self.currentLevelPath = moduleName
    
    -- Try to load level module
    local success, level = pcall(require, moduleName)
    if not success then
        print("Error loading level:", moduleName, level)
        return false
    end
    
    self.currentLevel = level
    
    -- Configure additional parameters if needed
    if not level.velocidade then
        -- Set velocity based on BPM if not defined
        level.velocidade = (level.bpm or 90) * 2
    end
    
    if not level.intervalo then
        -- Calculate interval based on BPM (60/BPM = duration of one beat in seconds)
        level.intervalo = 60 / (level.bpm or 90)
    end
    
    -- Add difficulty based on BPM if not defined
    if not level.dificuldade then
        level.dificuldade = math.floor((level.bpm or 90) / 30)
    end
    
    -- Reset game data in flag system
    FlagsSystem.resetRhythmGameData(level)
    
    -- Load level in gameplay
    Gameplay.carregar(level)
    self.state = "playing"
    
    -- Load initial animation if defined
    if level.animation then
        -- Load stage scene for initial animation
        local StageScene = require "stagescenes"
        self.stageScene = StageScene.new(level.animation)
        self.stageScene:load()
    end
    
    return true
end

-- Updates game state
function Game:update(dt)
    if self.state == "playing" then
        -- Update animation if active
        if self.stageScene then
            self.stageScene:update(dt)
        end
        
        -- Update flag system with gameplay data
        FlagsSystem.updateRhythmGameData(Gameplay)
        
        -- Check real-time achievements
        if self.currentLevel then
            FlagsSystem.checkRealTimeAchievements(self.currentLevel)
        end
        
        -- Update gameplay
        local result = Gameplay.atualizar(dt, 0)
        
        -- Check if level is completed
        if result == "fase_concluida" then
            -- Finalize level and check achievements
            local nextFase = FlagsSystem.finalizeFase("time")
            FlagsSystem.checkAllAchievements(self.currentLevel)
            FlagsSystem.saveState()
            
            -- Load next level or return to menu
            if nextFase then
                self:loadLevel("levels/" .. nextFase)
                return "fase_carregada"
            else
                self.state = "menu"
                return "fase_concluida"
            end
        end
    elseif self.state == "paused" then
        -- Atualiza os botões do menu de pausa
        local mx, my = love.mouse.getPosition()
        for _, button in ipairs(self.pauseButtons) do
            if button.updateHover then
                button:updateHover(mx, my)
            end
            
            if button.update then
                button:update(dt)
            end
        end
    end
    
    return self.state
end

-- Draws the game
function Game:draw()
    if self.state == "playing" or self.state == "paused" then
        -- Draw stage scene first as background
        if self.stageScene then
            self.stageScene:draw()
        end
        
        -- Then draw gameplay overlay in right area
        Gameplay.desenhar(true) -- true to draw UI
        
        -- Se estiver pausado, desenha o menu de pausa
        if self.state == "paused" then
            -- Overlay escuro semi-transparente
            love.graphics.setColor(0, 0, 0, 0.7)
            love.graphics.rectangle("fill", 0, 0, ScreenUtils.width, ScreenUtils.height)
            
            -- Título "PAUSE"
            love.graphics.setColor(1, 1, 1)
            -- Use a nova função para obter a fonte
            local font = ScreenUtils.getFont(30)
            love.graphics.setFont(font)
            
            local titleText = "PAUSADO"
            local textWidth = font:getWidth(titleText)
            love.graphics.print(
                titleText, 
                ScreenUtils.width / 2 - textWidth / 2, 
                ScreenUtils.height / 4
            )
            
            -- Desenha os botões do menu de pausa
            for _, button in ipairs(self.pauseButtons) do
                button:draw()
            end
            
            -- Restaura a cor
            love.graphics.setColor(1, 1, 1)
        end
    end
end

-- Handles key presses
function Game:keypressed(key)
    if key == "escape" then
        -- Toggle entre jogando e pausado
        if self.state == "playing" then
            self:pause()
        elseif self.state == "paused" then
            self:resume()
        elseif self.state == "menu" then
            -- Já está no menu, ignora
        end
    elseif self.state == "playing" then
        -- Só processa outras teclas quando jogando
        Gameplay.keypressed(key)
    end
end

-- Handles mouse presses
function Game:mousepressed(x, y, button)
    if self.state == "paused" then
        -- Processa cliques nos botões do menu de pausa
        for _, btn in ipairs(self.pauseButtons) do
            if btn.mousepressed then
                btn:mousepressed(x, y, button)
            end
        end
    end
end

-- Pauses the game
function Game:pause()
    if self.state == "playing" then
        self.state = "paused"
        Gameplay.pausar()
    end
end

-- Resumes the game
function Game:resume()
    if self.state == "paused" then
        self.state = "playing"
        Gameplay.continuar()
    end
end

-- Handles window resize
function Game:resize(w, h)
    -- Update dimensions
    self:calculateDimensions()
    
    -- Update gameplay
    Gameplay.setDimensoes(self.gameWidth, self.gameHeight)
    Gameplay.setOffset(self.gameOffsetX, self.gameOffsetY)
    Gameplay.onResize()
    
    -- Update stage scene if active
    if self.stageScene and self.stageScene.resize then
        self.stageScene:resize(w, h)
    end
    
    -- Recria os botões do menu de pausa
    self:setupPauseMenu()
end

-- Static functions for level creation

-- Creates a new level creator
function Game.newLevelCreator(larguraTela, alturaTela)
    local levelCreator = {}
    
    -- Screen dimensions for reference
    levelCreator.larguraTela = larguraTela
    levelCreator.alturaTela = alturaTela
    
    -- Default colors for levels
    levelCreator.cores = {
        {0.92, 0.7, 0.85},  -- Soft pastel pink
        {0.7, 0.9, 0.8},    -- Mint pastel green
        {0.7, 0.8, 0.95},   -- Sky blue pastel
        {0.97, 0.9, 0.7}    -- Soft pastel yellow
    }
    
    -- Calculate X positions for blocks
    levelCreator.posicoesX = {
        larguraTela * 0.2,
        larguraTela * 0.4, 
        larguraTela * 0.6,
        larguraTela * 0.8
    }
    
    -- Creates a new level with specific configuration
    levelCreator.createLevel = function(config)
        local nivel = {}
        
        -- Difficulty settings
        nivel.dificuldade = config.dificuldade or 1
        nivel.velocidade = config.velocidade or 200
        nivel.intervalo = config.intervalo or 1.0
        nivel.nome = config.nome or "Unnamed level"
        nivel.duracao = config.duracao or 60
        
        -- Block positions
        nivel.posicoesX = config.posicoesX or levelCreator.posicoesX
        
        -- Block colors
        nivel.cores = config.cores or levelCreator.cores
        
        -- Block patterns
        nivel.padroes = config.padroes or levelCreator.gerarPadroesAleatorios(nivel.dificuldade)
        
        return nivel
    end
    
    -- Generates random block patterns based on difficulty
    levelCreator.gerarPadroesAleatorios = function(dificuldade)
        local padroes = {}
        
        -- More patterns for higher difficulty
        local numPadroes = 5 + dificuldade * 2
        
        for i = 1, numPadroes do
            local padrao = {}
            local tamanhoPadrao = math.random(3, 5 + dificuldade)
            
            for j = 1, tamanhoPadrao do
                table.insert(padrao, {
                    posicao = math.random(1, 4),
                    cor = math.random(1, 4),
                    tempo = j * (0.8 - dificuldade * 0.1) -- Decreasing interval with difficulty
                })
            end
            
            table.insert(padroes, padrao)
        end
        
        return padroes
    end
    
    return levelCreator
end

-- Creates a new phase generator
function Game.newPhaseGenerator()
    local phaseGenerator = {}
    
    -- Generate random run seed with 9 digits
    phaseGenerator.runSeed = math.random(100000000, 999999999)
    
    -- Directory for level definitions
    phaseGenerator.levelsDirectory = "levels/"
    
    -- Cache for loaded levels
    phaseGenerator.loadedPhases = {}
    
    -- Sets a new run seed
    phaseGenerator.setRunSeed = function(seed)
        phaseGenerator.runSeed = seed
    end
    
    -- Gets current run seed
    phaseGenerator.getRunSeed = function()
        return phaseGenerator.runSeed
    end
    
    -- Loads a phase definition from file
    phaseGenerator.loadPhaseDefinition = function(phaseName)
        -- Check if phase is already cached
        if phaseGenerator.loadedPhases[phaseName] then
            return phaseGenerator.loadedPhases[phaseName]
        end
        
        -- Path to phase definition file
        local filePath = phaseGenerator.levelsDirectory .. phaseName .. ".lua"
        
        -- Try to load the file
        local success, phaseDefinition = pcall(function()
            return love.filesystem.load(filePath)()
        end)
        
        if success then
            -- Cache for future use
            phaseGenerator.loadedPhases[phaseName] = phaseDefinition
            return phaseDefinition
        else
            print("Error loading phase definition: " .. phaseName)
            print(phaseDefinition) -- Print error
            return nil
        end
    end
    
    -- Generates a phase based on definition and run seed
    phaseGenerator.generatePhase = function(levelCreator, phaseName)
        -- Load phase definition
        local phaseDefinition = phaseGenerator.loadPhaseDefinition(phaseName)
        if not phaseDefinition then
            print("Phase not found: " .. phaseName)
            return nil
        end
        
        -- Create phase seed if not defined
        if not phaseDefinition.fase_seed then
            local hash = 0
            for i = 1, #phaseName do
                hash = (hash * 31 + string.byte(phaseName, i)) % 1000000000
            end
            phaseDefinition.fase_seed = hash
            print("Auto-generated seed for " .. phaseName .. ": " .. hash)
        end
        
        -- Combine phase seed with run seed for unique result
        local combinedSeed = phaseDefinition.fase_seed * phaseGenerator.runSeed
        math.randomseed(combinedSeed)
        
        -- Calculate block velocity based on BPM
        local velocidade = phaseDefinition.bpm * 2
        
        -- Calculate interval between blocks based on BPM
        local intervalo = 60 / phaseDefinition.bpm
        
        -- Create configuration for level creator
        local config = {
            velocidade = phaseDefinition.velocidade or velocidade,
            intervalo = phaseDefinition.intervalo or intervalo,
            dificuldade = phaseDefinition.dificuldade or math.floor(phaseDefinition.bpm / 30),
            duracao = phaseDefinition.duracao,
            nome = phaseDefinition.nome or phaseName,
            cores = phaseDefinition.cores
        }
        
        -- Create level with calculated configuration
        local nivel = levelCreator.createLevel(config)
        
        -- Add phase metadata to level
        nivel.phaseDefinition = phaseDefinition
        nivel.phaseName = phaseName
        nivel.phaseSeed = phaseDefinition.fase_seed
        nivel.runSeed = phaseGenerator.runSeed
        nivel.combinedSeed = combinedSeed
        
        -- Copy original phase data for compatibility
        nivel.bpm = phaseDefinition.bpm
        nivel.duracao = phaseDefinition.duracao
        nivel.animation = phaseDefinition.animation
        nivel.achievements = phaseDefinition.achievements
        
        -- Restore random seed
        math.randomseed(os.time())
        
        return nivel
    end
    
    -- Lists all available phases in levels directory
    phaseGenerator.listAvailablePhases = function()
        local phases = {}
        
        -- Check if directory exists
        local info = love.filesystem.getInfo(phaseGenerator.levelsDirectory)
        if not info or info.type ~= "directory" then
            -- Create directory if it doesn't exist
            love.filesystem.createDirectory(phaseGenerator.levelsDirectory)
            return phases
        end
        
        -- List all files in directory
        local files = love.filesystem.getDirectoryItems(phaseGenerator.levelsDirectory)
        for _, file in ipairs(files) do
            -- Check if it's a Lua file
            if file:match("%.lua$") then
                -- Remove .lua extension
                local phaseName = file:gsub("%.lua$", "")
                table.insert(phases, phaseName)
            end
        end
        
        return phases
    end
    
    -- Creates an example phase file if none exist
    phaseGenerator.createExamplePhase = function()
        local examplePath = phaseGenerator.levelsDirectory .. "ExemploDeFase01.lua"
        local info = love.filesystem.getInfo(examplePath)
        
        if not info then
            local content = [[
-- ExemploDeFase01.lua
-- Example phase for rhythm game

local fase = {
    nome = "Tutorial 01",
    bpm = 90,      -- Base speed (beats per minute)
    duracao = 50,  -- Phase duration in seconds
    fase_seed = 13312212,  -- Seed for pattern generation
    
    -- System-specific parameters
    velocidade = 180,  -- Block fall speed
    intervalo = 0.7,   -- Interval between blocks in seconds
    dificuldade = 1,   -- Difficulty level
    
    -- Custom colors (optional)
    cores = {
        {0.92, 0.7, 0.85},  -- Soft pastel pink
        {0.7, 0.9, 0.8},    -- Mint pastel green
        {0.7, 0.8, 0.95},   -- Sky blue pastel
        {0.97, 0.9, 0.7}    -- Soft pastel yellow
    },
    
    -- Initial tutorial animation
    animation = "stages/ss_mast01",
    
    -- Tutorial achievements (easier)
    achievements = {
        {
            id = "First Completed Phase",
            condition = "musica_terminada",
            value = true,
            reward_type = "fase",
            reward_value = "exemploDeFase01"
        },
        {
            id = "First Steps",
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
            print("Example phase created at: " .. examplePath)
        end
    end
    
    -- Generates a new random run seed
    phaseGenerator.generateNewRunSeed = function()
        phaseGenerator.runSeed = math.random(100000000, 999999999)
        return phaseGenerator.runSeed
    end
    
    return phaseGenerator
end

-- Formats a seed for display
function Game.formatSeed(seed)
    local seedStr = tostring(seed)
    local formatted = ""
    
    -- Add leading zeros to ensure 9 digits
    while #seedStr < 9 do
        seedStr = "0" .. seedStr
    end
    
    -- Format as XXX-XXX-XXX for readability
    formatted = string.sub(seedStr, 1, 3) .. "-" .. 
                string.sub(seedStr, 4, 6) .. "-" .. 
                string.sub(seedStr, 7, 9)
    
    return formatted
end

return Game