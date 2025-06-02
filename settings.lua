---@class SettingsManager
SettingsManager = {}

-- TODO:
-- Check how / if defines (Details) are saved

local textutils = require("textutils")

---@alias settingType
---| "string"
---| "number"
---| "boolean"
---| "table"


---@class SettingDetail
---@field default any
---@field description string
---@field type settingType

---@type {[string]: SettingDetail}
local details = {}

---@type {[string]: any}
    local settings = {}

local defaultPath = "tmp/.settings"


local function reserialize(value)
    if type(value) ~= "table" then return value end
    return textutils.unserialize(textutils.serialize(value))
end


    ---@param name string
---@param options SettingDetail 
function SettingsManager.define(name, options)
    details[name] = {}
    if options ~= nil then
        details[name] = options
    end
end

---@param name string
function SettingsManager.undefine(name)
    details[name] = nil
end

---@param name string
---@param value any
function SettingsManager.set(name, value)
    settings[name] = value
end

---@param name string
---@param default any
---@return any
function SettingsManager.get(name, default)
    if settings[name] ~= nil then
        return settings[name]
    end
    if default ~= nil then
        return default
    end
    return (details[name] and details[name]["default"]) or nil
end

---@param name string
---@return any
function SettingsManager.getDetails(name)
    local tmp = details[name]
    if settings[name] ~= nil then 
        if tmp == nil then
            tmp = {}
        end
        tmp["value"] = settings[name]
    end
    return tmp
end

---@param name string
function SettingsManager.unset(name)
    settings[name] = nil
end

--- clears Settings (values only)
function SettingsManager.clear()
    settings = {}
end

--- clears Details (Defines only)
--- does not exist in cc, but might be usefull for testing
function SettingsManager.clearDetails()
    details = {}
end

---@return table<string>
function SettingsManager.getNames()
    ---@source https://github.com/cc-tweaked/CC-Tweaked/blob/876fd8ddb805365c33942afb81d6da7cbd0cbca5/projects/core/src/main/resources/data/computercraft/lua/rom/apis/settings.lua#L199
    local result, n = {}, 1
    for k in pairs(details) do
        result[n], n = k, n + 1
    end
    for k in pairs(settings) do
        if not details[k] then result[n], n = k, n + 1 end
    end
    table.sort(result)
    return result
end

---@param path string | nil
function SettingsManager.load(path)
    path = path or defaultPath
    local file = io.open(path, "r")
    if file == nil then
        return false
    end
    local content = file:read("*all")
    file:close()
    local result = textutils.unserialize(content)
    if not result or (type(result) ~= "table") then
        return false
    end
    settings = result
    return true
end

---@param path string | nil
function SettingsManager.save(path)
    if path == nil then 
        path = defaultPath
    end
    if not os.execute("mkdir -p $(dirname ".. path .. ")") then
        error("Could not create the file")
    end
    local result = textutils.serialize(settings)
    local file = io.open(path, "w")
    if file == nil then
        error("Could not save to File: "..path)
    end
    file:write(result)
    file:close()
    return true

end

return SettingsManager