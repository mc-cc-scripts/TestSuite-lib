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

package.path = package.path .. ";"
    .."libs/?.lua;"

local EventEmulator = require("events")

describe("Event-Tests", function ()
    ---@type ccEvent, TestFile
    local eventManager, testModule
    before_each(function()
        eventManager, testModule = EventEmulator:new("tests/testFiles/event_testFile.lua")
    end)
    describe("Basics", function()
        it("pull And Invoke", function()
            assert(type(testModule)=="table", type(testModule))
            testModule:event1()
            assert.is.falsy(testModule.status.event1)
            eventManager:invoke("TestEvent")
            assert.is.truthy(testModule.status.event1)
        end)
    end)
end)