-- save.lua (atualizado)
local Save = {}
local json = require "dkjson"

local saveFile = "savegame.json"
local flagsFile = "gameflags.json"

-- Salva as configurações do jogo
function Save.saveConfig(config)
    local file = love.filesystem.write(saveFile, json.encode(config, { indent = true }))
end

-- Carrega as configurações do jogo
function Save.loadConfig()
    if love.filesystem.getInfo(saveFile) then
        local contents, size = love.filesystem.read(saveFile)
        return json.decode(contents)
    end
    return nil
end

-- Salva o estado das flags e achievements
function Save.saveFlags(flagsData)
    local file = love.filesystem.write(flagsFile, json.encode(flagsData, { indent = true }))
end

-- Carrega o estado das flags e achievements
function Save.loadFlags()
    if love.filesystem.getInfo(flagsFile) then
        local contents, size = love.filesystem.read(flagsFile)
        return json.decode(contents)
    end
    return {
        flags = {},
        achievements = {},
        items = {}
    }
end

-- Salva o progresso do jogo e todas as informações
function Save.saveGameProgress(data)
    local fullSaveFile = "gameprogress.json"
    local file = love.filesystem.write(fullSaveFile, json.encode(data, { indent = true }))
end

-- Carrega o progresso completo do jogo
function Save.loadGameProgress()
    local fullSaveFile = "gameprogress.json"
    if love.filesystem.getInfo(fullSaveFile) then
        local contents, size = love.filesystem.read(fullSaveFile)
        return json.decode(contents)
    end
    return nil
end

-- Verifica se existem dados salvos
function Save.hasSaveData()
    return love.filesystem.getInfo(saveFile) ~= nil
end

-- Apaga todos os dados salvos (reset)
function Save.clearAllData()
    if love.filesystem.getInfo(saveFile) then
        love.filesystem.remove(saveFile)
    end
    
    if love.filesystem.getInfo(flagsFile) then
        love.filesystem.remove(flagsFile)
    end
    
    local fullSaveFile = "gameprogress.json"
    if love.filesystem.getInfo(fullSaveFile) then
        love.filesystem.remove(fullSaveFile)
    end
end

return Save