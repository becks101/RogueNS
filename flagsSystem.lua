-- flagsSystem.lua
--[[ 
    System for managing flags, achievements, and rewards.
    Tracks game progress, unlocks content, and manages persistent state.
]]

local Save = require "save"

local FlagsSystem = {}

-- Global game state for flags and achievements tracking
local GameState = {
    itemsColetados = {},         -- Collected items
    nextFase = nil,              -- Next level to load
    flagsAtivadas = {},          -- Activated flags
    achievementsDesbloqueados = {} -- Unlocked achievements
}

-- Rhythm game variables monitored for conditions
local RhythmGame = {
    bpm = 120,
    beatTime = 0,
    timer = 0,
    bpms = {},
    stageName = "",
    rhythmName = "",
    hitWindow = 0.2,
    approachTime = 2,
    nextSpawnIndex = 1,
    finished = false,
    achievements = {},
    score = 0,
    combo = 0,
    maxCombo = 0,
    comboMultiplier = 1,
    musicProgress = 0,
    musicDuration = 60,
    terminationReason = "none",
    hitEffects = {},
    target = {
        x = 0, y = 300,
        radius = 30,
        hitMargin = 60
    }
}

-- Reward types and their execution functions
local AchievementType = {
    -- Unlocks a stage scene
    stage_scene = function(reward) 
        print("Unlocked new stage scene:", reward)
        -- Notify gallery manager
        if FlagsSystem.callbacks.onStageSceneUnlocked then
            FlagsSystem.callbacks.onStageSceneUnlocked(reward)
        end
    end,
    
    -- Unlocks a cutscene
    cutscene = function(reward) 
        print("Unlocked new cutscene:", reward)
        -- Notify gallery manager
        if FlagsSystem.callbacks.onCutsceneUnlocked then
            FlagsSystem.callbacks.onCutsceneUnlocked(reward)
        end
    end,
    
    -- Unlocks a level
    fase = function(reward) 
        print("Unlocked new level:", reward)
        GameState.nextFase = reward
        -- Notify callback if exists
        if FlagsSystem.callbacks.onFaseUnlocked then
            FlagsSystem.callbacks.onFaseUnlocked(reward)
        end
    end,
    
    -- Default handler for unknown types
    default = function(reward) 
        print("[ERROR] Unimplemented reward type:", reward) 
    end
}

-- Condition checkers for achievements
local Flags = {
    conditions = {
        -- Check if combo reaches value
        acertos_consecutivos = function(v) 
            return RhythmGame.combo >= v 
        end,
        
        -- Check if max combo reaches value
        combo_maximo = function(v) 
            return RhythmGame.maxCombo >= v 
        end,
        
        -- Check if score reaches value
        pontuacao_minima = function(v) 
            return RhythmGame.score >= v 
        end,
        
        -- Check if music is finished
        musica_terminada = function() 
            return RhythmGame.finished 
        end,
        
        -- Check if level ended due to stamina
        stamina_drained = function() 
            return RhythmGame.terminationReason == "stamina" 
        end,
        
        -- Check if level completed full duration
        complete_duration = function() 
            return RhythmGame.terminationReason == "time" 
        end,
        
        -- Check if player has item
        has_item = function(i) 
            return GameState.itemsColetados[i] and 
                   GameState.itemsColetados[i].quantidade > 0 
        end
    }
}

-- Callbacks for integration with other modules
FlagsSystem.callbacks = {
    onStageSceneUnlocked = nil,
    onCutsceneUnlocked = nil,
    onFaseUnlocked = nil,
    onAchievementUnlocked = nil
}

-- Updates rhythm game data from gameplay state
function FlagsSystem.updateRhythmGameData(gameplay)
    if not gameplay then return end
    
    -- Update core data
    RhythmGame.score = gameplay.getPontuacao()
    RhythmGame.combo = gameplay.getCombo()
    RhythmGame.maxCombo = math.max(RhythmGame.maxCombo, RhythmGame.combo)
    RhythmGame.comboMultiplier = gameplay.getMultiplicador()
    
    -- Update time data if available
    if gameplay.getTempoDecorrido then
        RhythmGame.musicProgress = gameplay.getTempoDecorrido()
    end
end

-- Reset rhythm game data for a new level
function FlagsSystem.resetRhythmGameData(level)
    if not level then return end
    
    RhythmGame.bpm = level.bpm or 120
    RhythmGame.stageName = level.nome or ""
    RhythmGame.rhythmName = level.nome or ""
    RhythmGame.musicDuration = level.duracao or 60
    RhythmGame.score = 0
    RhythmGame.combo = 0
    RhythmGame.maxCombo = 0
    RhythmGame.comboMultiplier = 1
    RhythmGame.finished = false
    RhythmGame.terminationReason = "none"
end

-- Check if a specific achievement should be unlocked
function FlagsSystem.checkAchievement(achievement)
    if not achievement or not achievement.id then 
        return false 
    end
    
    -- Skip if already unlocked
    if GameState.achievementsDesbloqueados[achievement.id] then
        return false
    end
    
    -- Get condition function
    local conditionFunc = Flags.conditions[achievement.condition]
    if not conditionFunc then
        print("[ERROR] Unimplemented condition:", achievement.condition)
        return false
    end
    
    -- Check if condition is met
    if conditionFunc(achievement.value) then
        -- Mark as unlocked
        GameState.achievementsDesbloqueados[achievement.id] = true
        
        -- Notify about unlock
        if FlagsSystem.callbacks.onAchievementUnlocked then
            FlagsSystem.callbacks.onAchievementUnlocked(achievement.id)
        end
        
        -- Apply reward
        local rewardFunc = AchievementType[achievement.reward_type] or AchievementType.default
        rewardFunc(achievement.reward_value)
        
        return true
    end
    
    return false
end

-- Check all achievements for a level
function FlagsSystem.checkAllAchievements(fase)
    if not fase or not fase.achievements then
        return
    end
    
    for _, achievement in ipairs(fase.achievements) do
        FlagsSystem.checkAchievement(achievement)
    end
end

-- Check only real-time achievements
function FlagsSystem.checkRealTimeAchievements(fase)
    if not fase or not fase.achievements then
        return
    end
    
    for _, achievement in ipairs(fase.achievements) do
        if achievement.real_time_check then
            FlagsSystem.checkAchievement(achievement)
        end
    end
end

-- Finalize current level and check achievements
function FlagsSystem.finalizeFase(reason)
    RhythmGame.finished = true
    RhythmGame.terminationReason = reason or "time"
    
    -- Return next level if available
    local nextFase = GameState.nextFase
    GameState.nextFase = nil
    return nextFase
end

-- Save current flags and achievements state
function FlagsSystem.saveState()
    local saveData = {
        flags = GameState.flagsAtivadas,
        achievements = GameState.achievementsDesbloqueados,
        items = GameState.itemsColetados
    }
    
    Save.saveFlags(saveData)
end

-- Load saved flags and achievements state
function FlagsSystem.loadState()
    local savedData = Save.loadFlags()
    if savedData then
        GameState.flagsAtivadas = savedData.flags or {}
        GameState.achievementsDesbloqueados = savedData.achievements or {}
        GameState.itemsColetados = savedData.items or {}
        return true
    end
    return false
end

-- Set flag value
function FlagsSystem.setFlag(flagName, value)
    if not flagName then return end
    GameState.flagsAtivadas[flagName] = value or true
end

-- Get flag value
function FlagsSystem.getFlag(flagName)
    if not flagName then return false end
    return GameState.flagsAtivadas[flagName]
end

-- Add item to player's collection
function FlagsSystem.addItem(itemId, quantidade)
    if not itemId then return end
    quantidade = quantidade or 1
    
    if not GameState.itemsColetados[itemId] then
        GameState.itemsColetados[itemId] = { quantidade = quantidade }
    else
        GameState.itemsColetados[itemId].quantidade = 
            GameState.itemsColetados[itemId].quantidade + quantidade
    end
end

-- Check if player has an item
function FlagsSystem.hasItem(itemId, quantidade)
    if not itemId then return false end
    quantidade = quantidade or 1
    return GameState.itemsColetados[itemId] and 
           GameState.itemsColetados[itemId].quantidade >= quantidade
end

-- Get current rhythm game state (for debugging)
function FlagsSystem.getRhythmGameState()
    return RhythmGame
end

-- Reset the system
function FlagsSystem.reset()
    GameState.nextFase = nil
    
    -- Reset rhythm game but keep flags and achievements
    RhythmGame.score = 0
    RhythmGame.combo = 0
    RhythmGame.maxCombo = 0
    RhythmGame.comboMultiplier = 1
    RhythmGame.finished = false
    RhythmGame.terminationReason = "none"
end

return FlagsSystem