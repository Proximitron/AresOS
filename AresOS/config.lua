-- Config holds public configuration values (unencrypted)
local self = {}

local configData = nil
local usedKeys = {}
function self:get(param, default)
    if configData == nil then self:load() end
    usedKeys[param] = true
    if configData[param] == nil then return default end
    if default ~= nil and configData[param] == default then
        configData[param] = nil
        return default
    end

    return configData[param]
end
function self:set(param, val, default)
    if configData == nil then self:load() end
    usedKeys[param] = true
    if configData[param] ~= val then
        if val == default then
            configData[param] = nil
        else
            configData[param] = val
        end

        self:save()
    end
end
function self:load()
    if configData == nil then
        if database ~= nil and database.hasKey ~= nil and database.hasKey("config") == 1 then
            local currStr = database.getStringValue("config")
            configData = json.decode(currStr)
        end
        if configData == nil then
            configData = {}
        end
    end
end
function self:save()
    if configData ~= nil then
        if database ~= nil and database.hasKey ~= nil then
            database.setStringValue("config",json.encode(configData))
        end
    end
end
function self:cleanup()
    if configData == nil then return end

    local change = false
    for name, value in pairs(configData) do
        if usedKeys[name] == nil then
            change = true
            configData[name] = nil
        end
    end
    if change then
        self:save()
    end
end
function self:register(env)
    _ENV = env

    register:addAction("systemStop","configCleanup",
            function()
                self:cleanup()
            end
    )
end
return self