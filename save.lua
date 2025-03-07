-- save.lua
local Save = {}
local json = require "dkjson"

local saveFile = "savegame.json"

function Save.saveConfig(config)
    local file = love.filesystem.write(saveFile, json.encode(config, { indent = true }))
end

function Save.loadConfig()
    if love.filesystem.getInfo(saveFile) then
        local contents, size = love.filesystem.read(saveFile)
        return json.decode(contents)
    end
    return nil
end

return Save
