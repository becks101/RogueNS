-- gameplay.lua
--[[
    Module that contains all rhythm game logic.
    
    This module implements a rhythm game where colored blocks fall along tracks
    and the player must move to capture them.
    
    The game uses a fixed-position layout with the gameplay area positioned
    on the right side of the screen.
]]

local ScreenUtils = require "screen_utils"

local gameplay = {}

--------------------------
-- PRIVATE VARIABLES
--------------------------

-- Game dimensions and positioning
local gameWidthPercent = 0.15  -- Percentage of screen width
local minGameWidth = 160       -- Minimum width in pixels
local maxGameWidth = 200       -- Maximum width in pixels
local gameMargin = 20          -- Margin from screen edge
local gameWidth, gameHeight = 0, 0
local offsetX, offsetY = 0, 0

-- Game state
local player = nil
local blocks = {}
local level = nil
local points = 0
local timeSinceLastBlock = 0

-- Reference to external modules (lazy-loaded when needed)
local levelCreator, phaseGenerator = nil, nil

--------------------------
-- PRIVATE HELPER FUNCTIONS
--------------------------

-- Recalculates game dimensions based on screen size
local function recalculateDimensions()
    -- Calculate proportional width with limits
    gameWidth = math.max(minGameWidth, math.min(ScreenUtils.width * gameWidthPercent, maxGameWidth))
    
    -- Keep gameHeight nearly full height with margin
    gameHeight = ScreenUtils.height - gameMargin * 2
    
    -- Position at the right side of screen with margin
    offsetX = ScreenUtils.width - gameWidth - gameMargin
    offsetY = gameMargin
    
    -- Update player positions if player exists
    if player then
        -- Recalculate track positions
        local numPositions = 4
        local spacing = math.floor(gameWidth / 5)
        
        player.posicoesJogador = {}
        for i = 1, numPositions do
            player.posicoesJogador[i] = math.floor(i * spacing)
        end
        
        -- Update current position
        player.x = player.posicoesJogador[player.posicaoAtual]
        
        -- Update player radius for visual consistency
        player.raio = math.max(8, math.floor(gameWidth / 20))
    end
    
    -- Update level track positions if level exists
    if level and level.posicoesX then
        local numPositions = 4
        local spacing = math.floor(gameWidth / 5)
        
        level.posicoesX = {}
        for i = 1, numPositions do
            level.posicoesX[i] = math.floor(i * spacing)
        end
    end
end

-- Creates a new block based on current level configuration
local function createBlock()
    if not level then return nil end

    local positionIndex = math.random(1, 4)
    local colorIndex = math.random(1, 4)
    
    -- Fixed block size for visual consistency
    local minSize = 12
    local blockSize = math.max(minSize, math.floor(gameWidth / 16))
    
    local block = {
        x = level.posicoesX[positionIndex],
        y = -blockSize,  -- Start above the screen
        width = blockSize,
        height = blockSize,
        color = level.cores[colorIndex],
        positionIndex = positionIndex,
        cornerRadius = math.floor(blockSize * 0.2) -- 20% of block size
    }
    
    table.insert(blocks, block)
    return block
end

-- Checks collision between a block and the player
local function checkCollision(block, playerObj)
    if not block or not playerObj then return false end
    
    -- Find the closest point on the rectangle to the circle
    local closestX = math.max(block.x - block.width/2, 
                             math.min(playerObj.x, block.x + block.width/2))
    local closestY = math.max(block.y - block.height/2, 
                             math.min(playerObj.y, block.y + block.height/2))
    
    -- Calculate distance between closest point and circle center
    local distX = closestX - playerObj.x
    local distY = closestY - playerObj.y
    local distSquared = distX * distX + distY * distY
    
    -- Check if distance is less than circle radius
    return distSquared <= (playerObj.raio * playerObj.raio)
end

-- Initialize player with calculated positions
local function initializePlayer()
    if not gameWidth or not gameHeight then return nil end
    
    -- Fixed player size for consistency
    local playerRadius = math.max(8, math.floor(gameWidth / 20))
    
    -- Fixed Y position from bottom
    local posY = gameHeight - 40
    
    local player = {
        posicaoAtual = 2, -- Start at position 2 (of 1-4)
        posicoesJogador = {},
        x = 0, -- Will be set after calculating positions
        y = posY,
        raio = playerRadius,
        cor = {0.9, 0.85, 0.95} -- Light pastel pink
    }
    
    -- Calculate player positions
    local numPositions = 4
    local spacing = math.floor(gameWidth / 5)
    
    for i = 1, numPositions do
        player.posicoesJogador[i] = math.floor(i * spacing)
    end
    
    -- Set initial X position
    player.x = player.posicoesJogador[player.posicaoAtual]
    
    return player
end

-- Calculate track positions
local function calculateTrackPositions()
    if not level or not gameWidth then return end
    
    local numPositions = 4
    local spacing = math.floor(gameWidth / 5)
    
    level.posicoesX = {}
    for i = 1, numPositions do
        level.posicoesX[i] = math.floor(i * spacing)
    end
end

--------------------------
-- PUBLIC API
--------------------------

-- Sets the offset (position) of the gameplay area on the screen
function gameplay.setOffset(x, y)
    offsetX = x or 0
    offsetY = y or 0
end

-- Sets the dimensions of the gameplay area and recalculates layout
function gameplay.setDimensoes(width, height)
    if width and height then
        gameWidth = width
        gameHeight = height
        recalculateDimensions()
    end
end

-- Legacy API (maintained for compatibility)
function gameplay.setCentro(x, y) end
function gameplay.setRaioCentral(raio) end
function gameplay.setRaioExterno(raio) end
function gameplay.setDistanciaOrigem(dist) end
function gameplay.setVelocidadeSuavizacao(velocidade) end
function gameplay.setTempoAntecipacao(tempo) end
function gameplay.setForcaGravitacional(forca) end
function gameplay.setVelocidadeLaser(velocidade) end
function gameplay.setLarguraArcoEscudo(largura) end
function gameplay.setAnguloEscudo(angulo) end
function gameplay.getAnguloEscudo() return 0 end

-- Loads a level
function gameplay.carregar(fase)
    if not fase then return false end
    
    -- Initialize helper modules if needed
    if not levelCreator then
        local Game = require("game")
        levelCreator = Game.newLevelCreator(gameWidth, gameHeight)
        phaseGenerator = Game.newPhaseGenerator()
    end
    
    -- Set up the level
    level = fase
    
    -- Configure track positions
    calculateTrackPositions()
    
    -- Set default colors if not defined
    if not level.cores then
        level.cores = {
            {0.92, 0.7, 0.85},  -- Soft pastel pink
            {0.7, 0.9, 0.8},    -- Mint pastel green
            {0.7, 0.8, 0.95},   -- Sky blue pastel
            {0.97, 0.9, 0.7}    -- Soft pastel yellow
        }
    end
    
    -- Initialize the player
    player = initializePlayer()
    
    -- Reset game state
    blocks = {}
    points = 0
    timeSinceLastBlock = 0
    
    return true
end

-- Updates the game state
function gameplay.atualizar(dt, anguloEscudoInput)
    if not player or not level then return nil end
    
    -- Update player X position based on current position
    player.x = player.posicoesJogador[player.posicaoAtual]
    
    -- Create new blocks based on level timing
    timeSinceLastBlock = timeSinceLastBlock + dt
    if level and timeSinceLastBlock >= level.intervalo then
        createBlock()
        timeSinceLastBlock = 0
    end
    
    -- Update blocks position and check collisions
    for i = #blocks, 1, -1 do
        local block = blocks[i]
        block.y = block.y + level.velocidade * dt
        
        -- Check collision with player
        if checkCollision(block, player) then
            table.remove(blocks, i)
            points = points + 10
        -- Remove blocks that left the screen
        elseif block.y > gameHeight + block.height/2 then
            table.remove(blocks, i)
        end
    end
    
    -- Return nil for compatibility (game continues)
    -- Return "fase_concluida" if level should end
    return nil
end

-- Main drawing function
function gameplay.desenhar(drawUI)
    if not player or not level then return end
    
    -- Save current transform state
    love.graphics.push()
    
    -- Apply transform to position gameplay area
    love.graphics.translate(offsetX, offsetY)
    
    -- Semi-transparent background for gameplay area (for overlay over stage scene)
    love.graphics.setColor(0.97, 0.89, 0.91, 0.85)
    love.graphics.rectangle("fill", 0, 0, gameWidth, gameHeight, 12, 12)
    
    -- Soft border for gameplay area
    love.graphics.setColor(0.8, 0.75, 0.8, 0.7)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", 0, 0, gameWidth, gameHeight, 12, 12)
    
    -- Game title at the top
    love.graphics.setColor(0.6, 0.5, 0.7, 0.9)
    local fontSize = math.max(10, math.floor(gameWidth / 15))
    local font = love.graphics.newFont(fontSize)
    love.graphics.setFont(font)
    love.graphics.printf("Rhythm Game", 0, 10, gameWidth, "center")
    
    -- Draw tracks
    for i, pos in ipairs(player.posicoesJogador) do
        -- Track width proportional but with limits
        local trackWidth = math.min(math.max(gameWidth * 0.2, 15), 30)
        
        -- Track color based on player position (more transparent for overlay)
        if i == player.posicaoAtual then
            love.graphics.setColor(0.95, 0.78, 0.85, 0.7) -- Active track is brighter
        else
            love.graphics.setColor(0.93, 0.83, 0.87, 0.5) -- Inactive tracks
        end
        
        love.graphics.rectangle("fill", 
            pos - trackWidth/2, 
            0, 
            trackWidth, 
            gameHeight,
            8, 8) -- Tracks with rounded corners
    end
    
    -- Draw action line (where player should hit blocks)
    love.graphics.setColor(0.7, 0.65, 0.75, 0.7)
    love.graphics.setLineWidth(2)
    love.graphics.line(0, player.y, gameWidth, player.y)
    
    -- Draw blocks with shadows and rounded corners
    for _, block in ipairs(blocks) do
        -- Draw subtle shadow
        love.graphics.setColor(0.7, 0.7, 0.8, 0.4)
        love.graphics.rectangle("fill", 
            block.x - block.width/2 + 4, 
            block.y - block.height/2 + 4, 
            block.width, 
            block.height,
            block.cornerRadius, 
            block.cornerRadius)
        
        -- Draw main block with rounded corners
        love.graphics.setColor(block.color)
        love.graphics.rectangle("fill", 
            block.x - block.width/2, 
            block.y - block.height/2, 
            block.width, 
            block.height,
            block.cornerRadius, 
            block.cornerRadius)
        
        -- More defined border
        love.graphics.setColor(0.6, 0.6, 0.7, 0.9)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", 
            block.x - block.width/2, 
            block.y - block.height/2, 
            block.width, 
            block.height,
            block.cornerRadius, 
            block.cornerRadius)
        
        -- Small highlight in upper left corner
        love.graphics.setColor(1, 1, 1, 0.5)
        love.graphics.circle("fill", 
            block.x - block.width/2 + block.cornerRadius, 
            block.y - block.height/2 + block.cornerRadius, 
            block.cornerRadius * 0.5)
    end
    
    -- Draw player (circle with glow effect)
    -- First draw larger circle for glow effect
    love.graphics.setColor(1, 1, 1, 0.3)
    love.graphics.circle("fill", player.x, player.y, player.raio * 1.2)
    
    -- Main player circle
    love.graphics.setColor(0.9, 0.85, 0.95)
    love.graphics.circle("fill", player.x, player.y, player.raio)
    
    -- Player border
    love.graphics.setColor(0.7, 0.65, 0.75)
    love.graphics.circle("line", player.x, player.y, player.raio)
    
    -- Light effect on player (small circle on upper left)
    love.graphics.setColor(1, 1, 1, 0.8)
    love.graphics.circle("fill", 
        player.x - player.raio * 0.3, 
        player.y - player.raio * 0.3, 
        player.raio * 0.2)
    
    -- Draw UI if requested
    if drawUI then
        -- Semi-transparent background for UI text
        love.graphics.setColor(0.2, 0.2, 0.3, 0.6)
        love.graphics.rectangle("fill", 5, 5, gameWidth - 10, 60, 8, 8)
        
        -- Draw score with better visibility
        love.graphics.setColor(0.95, 0.95, 1)
        local uiFontSize = math.max(10, math.floor(gameWidth / 20))
        local uiFont = love.graphics.newFont(uiFontSize)
        love.graphics.setFont(uiFont)
        love.graphics.print("Pontuação: " .. points, 10, 15)
        
        -- Draw level if available
        if level and level.dificuldade then
            love.graphics.print("Nível: " .. level.dificuldade, 10, 35)
        end
    end
    
    -- Restore transform state
    love.graphics.pop()
end

-- Get current score
function gameplay.getPontuacao()
    return points
end

-- Get current combo (kept for compatibility)
function gameplay.getCombo()
    return 0
end

-- Get current multiplier (kept for compatibility)
function gameplay.getMultiplicador()
    return 1
end

-- Get elapsed time (kept for compatibility)
function gameplay.getTempoDecorrido()
    return 0
end

-- Handle key presses
function gameplay.keypressed(key)
    if not player then return end
    
    if key == "left" then
        -- Move left or wrap to rightmost position
        if player.posicaoAtual > 1 then
            player.posicaoAtual = player.posicaoAtual - 1
        else
            player.posicaoAtual = #player.posicoesJogador
        end
    elseif key == "right" then
        -- Move right or wrap to leftmost position
        if player.posicaoAtual < #player.posicoesJogador then
            player.posicaoAtual = player.posicaoAtual + 1
        else
            player.posicaoAtual = 1
        end
    end
end

-- For compatibility with existing code
function gameplay.pausar() end
function gameplay.continuar() end

-- Handle window resize
function gameplay.onResize()
    recalculateDimensions()
end

-- Initialize with current screen dimensions
function gameplay.init()
    recalculateDimensions()
end

-- Return the module
return gameplay