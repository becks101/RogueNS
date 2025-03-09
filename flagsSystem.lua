-- flagsSystem.lua
-- Sistema para gerenciar flags, achievements e recompensas

local Save = require "save"

local FlagsSystem = {}

-- Estado global do jogo para rastreamento de flags e achievements
local GameState = {
    itemsColetados = {},
    nextFase = nil,
    flagsAtivadas = {},
    achievementsDesbloqueados = {}
}

-- Variáveis de jogo de ritmo que são monitoradas para condições
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

-- Tipos de recompensas e suas funções de execução
local AchievementType = {
    stage_scene = function(reward) 
        print("Desbloqueou nova cena de palco:", reward)
        -- Implemente a lógica para ativar/desbloquear stage scenes
        -- Exemplo: Notificar o gerenciador de galeria
        if FlagsSystem.callbacks.onStageSceneUnlocked then
            FlagsSystem.callbacks.onStageSceneUnlocked(reward)
        end
    end,
    
    cutscene = function(reward) 
        print("Desbloqueou nova cutscene:", reward)
        -- Implemente a lógica para ativar/desbloquear cutscenes
        -- Exemplo: Notificar o gerenciador de galeria
        if FlagsSystem.callbacks.onCutsceneUnlocked then
            FlagsSystem.callbacks.onCutsceneUnlocked(reward)
        end
    end,
    
    fase = function(reward) 
        print("Desbloqueou nova fase:", reward)
        GameState.nextFase = reward
        -- Notifica callback se existir
        if FlagsSystem.callbacks.onFaseUnlocked then
            FlagsSystem.callbacks.onFaseUnlocked(reward)
        end
    end,
    
    default = function(reward) 
        print("[ERRO] Tipo de recompensa não implementado:", reward) 
    end
}

-- Condições que podem ser verificadas para desbloquear achievements
local Flags = {
    conditions = {
        acertos_consecutivos = function(v) return RhythmGame.combo >= v end,
        combo_maximo = function(v) return RhythmGame.maxCombo >= v end,
        pontuacao_minima = function(v) return RhythmGame.score >= v end,
        musica_terminada = function() return RhythmGame.finished end,
        stamina_drained = function() return RhythmGame.terminationReason == "stamina" end,
        complete_duration = function() return RhythmGame.terminationReason == "time" end,
        has_item = function(i) return GameState.itemsColetados[i] and GameState.itemsColetados[i].quantidade > 0 end
    }
}

-- Callbacks para integração com outros módulos
FlagsSystem.callbacks = {
    onStageSceneUnlocked = nil,
    onCutsceneUnlocked = nil,
    onFaseUnlocked = nil,
    onAchievementUnlocked = nil
}

-- Atualiza os dados do RhythmGame com base no Gameplay
function FlagsSystem.updateRhythmGameData(gameplay)
    RhythmGame.score = gameplay.getPontuacao()
    RhythmGame.combo = gameplay.getCombo()
    RhythmGame.maxCombo = math.max(RhythmGame.maxCombo, RhythmGame.combo)
    RhythmGame.comboMultiplier = gameplay.getMultiplicador()
    
    -- Atualiza outros dados se disponíveis
    if gameplay.getTempoDecorrido then
        RhythmGame.musicProgress = gameplay.getTempoDecorrido()
    end
end

-- Reseta os dados do RhythmGame para uma nova fase
function FlagsSystem.resetRhythmGameData(level)
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

-- Verifica se um achievement específico deve ser desbloqueado
function FlagsSystem.checkAchievement(achievement)
    -- Verifica se já foi desbloqueado
    if GameState.achievementsDesbloqueados[achievement.id] then
        return false
    end
    
    -- Obtém a função de condição
    local conditionFunc = Flags.conditions[achievement.condition]
    if not conditionFunc then
        print("[ERRO] Condição não implementada:", achievement.condition)
        return false
    end
    
    -- Verifica se a condição é atendida
    if conditionFunc(achievement.value) then
        -- Marca como desbloqueado
        GameState.achievementsDesbloqueados[achievement.id] = true
        
        -- Notifica sobre o desbloqueio
        if FlagsSystem.callbacks.onAchievementUnlocked then
            FlagsSystem.callbacks.onAchievementUnlocked(achievement.id)
        end
        
        -- Aplica a recompensa
        local rewardFunc = AchievementType[achievement.reward_type] or AchievementType.default
        rewardFunc(achievement.reward_value)
        
        return true
    end
    
    return false
end

-- Verifica todos os achievements de uma fase
function FlagsSystem.checkAllAchievements(fase)
    if not fase or not fase.achievements then
        return
    end
    
    for _, achievement in ipairs(fase.achievements) do
        FlagsSystem.checkAchievement(achievement)
    end
end

-- Verifica apenas os achievements marcados para verificação em tempo real
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

-- Finaliza a fase atual e verifica todos os achievements
function FlagsSystem.finalizeFase(reason)
    RhythmGame.finished = true
    RhythmGame.terminationReason = reason or "time"
    
    -- Retorna a próxima fase se houver
    local nextFase = GameState.nextFase
    GameState.nextFase = nil
    return nextFase
end

-- Salva o estado atual das flags e achievements
function FlagsSystem.saveState()
    local saveData = {
        flags = GameState.flagsAtivadas,
        achievements = GameState.achievementsDesbloqueados,
        items = GameState.itemsColetados
    }
    
    Save.saveFlags(saveData)
end

-- Carrega o estado salvo de flags e achievements
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

-- Marca uma flag como ativada
function FlagsSystem.setFlag(flagName, value)
    GameState.flagsAtivadas[flagName] = value or true
end

-- Verifica se uma flag está ativada
function FlagsSystem.getFlag(flagName)
    return GameState.flagsAtivadas[flagName]
end

-- Adiciona um item à coleção do jogador
function FlagsSystem.addItem(itemId, quantidade)
    quantidade = quantidade or 1
    
    if not GameState.itemsColetados[itemId] then
        GameState.itemsColetados[itemId] = { quantidade = quantidade }
    else
        GameState.itemsColetados[itemId].quantidade = GameState.itemsColetados[itemId].quantidade + quantidade
    end
end

-- Verifica se o jogador tem um determinado item
function FlagsSystem.hasItem(itemId, quantidade)
    quantidade = quantidade or 1
    return GameState.itemsColetados[itemId] and GameState.itemsColetados[itemId].quantidade >= quantidade
end

-- Retorna o estado atual do RhythmGame (útil para debugging)
function FlagsSystem.getRhythmGameState()
    return RhythmGame
end

-- Reinicia o sistema
function FlagsSystem.reset()
    GameState.nextFase = nil
    
    -- Reseta RhythmGame mas mantém flags e achievements
    RhythmGame.score = 0
    RhythmGame.combo = 0
    RhythmGame.maxCombo = 0
    RhythmGame.comboMultiplier = 1
    RhythmGame.finished = false
    RhythmGame.terminationReason = "none"
end

return FlagsSystem