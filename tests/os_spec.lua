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

local osEmulator = require("ccOS")

describe("Event-Tests", function ()
    ---@type ccOS, TestFile, string
    local osEnv, testModule, invokeWord
    local path = "tests/testFiles/event_testFile.lua"
    before_each(function()
        osEnv = osEmulator()
    end)
    describe("#basics", function()
        it("#pullAndInvokeOnFunctionOnly", function ()
            invokeWord = "testEvent"
            local testFunc = osEnv:wrap(function(parameter)
                assert(parameter == "parameterCheck")
                os.pullEvent(invokeWord)
            end, false)
            
            testFunc("parameterCheck")
            assert.are.equal("suspended", coroutine.status(osEnv.thread))
            osEnv:invoke()
            assert.are.equal("suspended", coroutine.status(osEnv.thread))
            osEnv:invoke(invokeWord)
            assert.are.equal("dead", coroutine.status(osEnv.thread))
        end)
        it("#pullAndInvokeModule", function()
            local file = loadfile(path, "t")
            testModule = osEnv:wrap(file, true)
            assert(type(testModule)=="table", type(testModule))

            invokeWord = "test"
            assert.are.equal(false, osEnv.subThreads.event1.waiting)
            testModule:event1(invokeWord) -- start function (runs in a thread)
            assert.are.equal(true, osEnv.subThreads.event1.waiting)
            osEnv:invoke("wrongword")
            assert.are.equal("suspended", coroutine.status(osEnv.subThreads.event1.thread))
            osEnv:invoke(invokeWord)
            assert.are.equal(false, osEnv.subThreads.event1.waiting)
            assert.are.equal(invokeWord, testModule.status.event1)
        end)
    end)
    describe("#timer",function()
        it("#start", function()
            local file = loadfile(path, "t")
            testModule = osEnv:wrap(file, true)
            assert(testModule)

            testModule:event2()
            testModule:event2()
            testModule:event2()
            assert.are.same(1, #osEnv.TimerList.timers) -- only one timer is inserted, the pullEvent didn't trigger
            
            assert.are.same(1, testModule.status.event2)
            osEnv:passTime(3)
            assert.are.same(1, testModule.status.event2)
            osEnv:passTime(1)
            assert.are.same(1, testModule.status.event2)
            osEnv:passTime(1)
            assert.are.same(nil, testModule.status.event2)
            osEnv:passTime(1)
            assert.are.same(nil, testModule.status.event2) -- the next pullEvent should never be triggered
        end)
        it("#cancel", function()
            local file = loadfile(path, "t")
            testModule = osEnv:wrap(file, true)
            assert(testModule)

            testModule:event2()
            osEnv:removeTimer(1)
            osEnv:passTime(8)
            assert.are.same(1, testModule.status.event2)
        end)
        it("#sleep", function()
            local file = loadfile(path, "t")
            testModule = osEnv:wrap(file,true)
            assert(testModule)

            testModule:event3()
            assert.are.same(nil, testModule.status.event3)
            osEnv:passTime(4)
            assert.are.same(nil, testModule.status.event3)
            osEnv:passTime(1)
            assert.are.same(true, testModule.status.event3)
        end)
    end)
end)