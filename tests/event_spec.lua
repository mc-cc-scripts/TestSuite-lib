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
    ---@type ccEvent, TestFile | nil, string
    local eventManager, testModule, invokeWord
    local path = "tests/testFiles/event_testFile.lua"
    before_each(function()
        eventManager = EventEmulator()
    end)
    describe("Basics", function()
        it("Pull and invoke on function only", function ()
            invokeWord = "testEvent"
            local testFunc = eventManager:wrap(function(parameter)
                assert(parameter == "parameterCheck")
                os.pullEvent(invokeWord)
            end, false)
            
            testFunc("parameterCheck")
            assert.are.equal(coroutine.status(eventManager.thread), "suspended")
            eventManager:invoke()
            assert.are.equal(coroutine.status(eventManager.thread), "suspended")
            eventManager:invoke(invokeWord)
            assert.are.equal(coroutine.status(eventManager.thread), "dead")
        end)
        it("Pull and invoke on module", function()
            local file = loadfile(path, "t")
            testModule = eventManager:wrap(file, true)
            assert(type(testModule)=="table", type(testModule))
            invokeWord = "test"
            assert.are.equal(eventManager.subThreads.event1.waiting, false)
            testModule:event1(invokeWord) -- start function (in thread)
            assert.are.equal(eventManager.subThreads.event1.waiting, true)
            eventManager:invoke("wrongword")
            assert.are.equal(coroutine.status(eventManager.subThreads.event1.thread), "suspended")
            eventManager:invoke(invokeWord)
            assert.are.equal(coroutine.status(eventManager.subThreads.event1.thread), "dead")
            assert.are.equal(testModule.status.event1, invokeWord)
        end)
    end)
end)