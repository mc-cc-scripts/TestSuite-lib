---@class are
---@field same string
---@field equal string
---@field equals string

---@class is
---@field truthy string
---@field falsy string
---@field not_true string
---@field not_false string

---@class has
---@field error string
---@field errors string

---@class assert
---@field are are
---@field is is
---@field are_not are
---@field is_not is
---@field has has
---@field has_no has
---@field True string
---@field False string
---@field has_error string
---@field is_false string
---@field is_true string
---@field equal string
assert = assert


---@class SettingsManager
local settings = require("settings")

local settingsFile = "tmp/.settings"

describe('Settings', function()
    ---@class SettingDetail
    local detail
    ---@type any
    local setting

    before_each(function ()
        settings.clear()
        settings.clearDetails()
        detail = {
            description = "This is a test Setting",
            default = {["value"] = 14, ["value2"] = "fourteen"},
            type = "table"
        }
        setting = {["value"] = 15, ["value2"] = "fifteen"}
    end)
    after_each(function ()
        os.execute("rm -f "..settingsFile)
    end)
    it('define', function()
        settings.define("Test01", detail)
        local result = settings.getDetails("Test01")
        assert.are.equal(detail, result)
    end)
    it('getNames', function()
        settings.define("Test01", detail)
        local result = settings.getNames()
        assert.are.same({"Test01"}, result)
    end)
    it('get & getDetails', function()
        settings.define("Test01", detail)
        local result = settings.get("Test01")
        assert.are.same(detail.default, result)
        result = settings.getDetails("Test01")
    end)
    it('save and load', function()
        settings.define("Test01", detail)
        local result = settings.load(settingsFile)
        assert.are.same(false, result)
        settings.set("Test01", setting)
        settings.save(settingsFile)
        settings.clear()
        settings.clearDetails()
        result = settings.load(settingsFile)
        assert.is_true(result)
        local get_result = settings.get("Test01")
        assert.are.same(setting, get_result)
    end)
        
end)