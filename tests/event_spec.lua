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
    ---@type ccEvent, TestFile, string
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
            assert.are.equal("suspended", coroutine.status(eventManager.thread))
            eventManager:invoke()
            assert.are.equal("suspended", coroutine.status(eventManager.thread))
            eventManager:invoke(invokeWord)
            assert.are.equal("dead", coroutine.status(eventManager.thread))
        end)
        it("Pull and invoke on module", function()
            local file = loadfile(path, "t")
            testModule = eventManager:wrap(file, true)
            assert(type(testModule)=="table", type(testModule))

            invokeWord = "test"
            assert.are.equal(false, eventManager.subThreads.event1.waiting)
            testModule:event1(invokeWord) -- start function (runs in a thread)
            assert.are.equal(true, eventManager.subThreads.event1.waiting)
            eventManager:invoke("wrongword")
            assert.are.equal("suspended", coroutine.status(eventManager.subThreads.event1.thread))
            eventManager:invoke(invokeWord)
            assert.are.equal(false, eventManager.subThreads.event1.waiting)
            assert.are.equal(invokeWord, testModule.status.event1)
        end)
    end)
    describe("Timer",function()
        it("startTimer", function()
            local file = loadfile(path, "t")
            testModule = eventManager:wrap(file, true)
            assert(testModule)

            testModule:event2()
            testModule:event2()
            testModule:event2()
            assert.are.same(1, #eventManager.TimerList.timers) -- only one timer is inserted, the pullEvent didn't trigger
            
            assert.are.same(1, testModule.status.event2)
            eventManager:passTime(3)
            assert.are.same(1, testModule.status.event2)
            eventManager:passTime(1)
            assert.are.same(1, testModule.status.event2)
            eventManager:passTime(1)
            assert.are.same(nil, testModule.status.event2)
            eventManager:passTime(1)
            assert.are.same(nil, testModule.status.event2) -- the next pullEvent should never be triggered
        end)

    end)
end)