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
        it("#PullAndInvokeOnFunction", function ()
            invokeWord = "testEvent"
            local testFunc = osEnv:wrap(function(parameter)
                assert(parameter == "parameterCheck")
                os.pullEvent(invokeWord)
            end, false)
            assert(testFunc)
            testFunc("parameterCheck")
            assert.are.equal("suspended", coroutine.status(osEnv.thread))
            -- osEnv:invoke()
            -- assert.are.equal("suspended", coroutine.status(osEnv.thread))
            osEnv:invoke(invokeWord)
            assert.are.equal("dead", coroutine.status(osEnv.thread))
        end)
        it("#EmptyEvent", function ()
            local testFunc = osEnv:wrap(function()
                local test = "t"
                while test ~= nil do
                    test = os.pullEvent()
                end
            end, false)
            assert(testFunc)
            testFunc()
            assert.are.equal("suspended", coroutine.status(osEnv.thread))
            osEnv:invoke("Hi there")
            assert.are.equal("suspended", coroutine.status(osEnv.thread))
            osEnv:invoke()
            assert.are.equal("dead", coroutine.status(osEnv.thread))
        end)
        it("#PullAndInvokeOnModule", function()
            local func = loadfile(path, "t")
            testModule = osEnv:wrap(func, true)
            assert(type(testModule)=="table", type(testModule))

            invokeWord = "test"
            assert.are.equal("suspended", coroutine.status(osEnv.subThreads.event1.thread))
            testModule:event1(invokeWord) -- start function (runs in a thread)
            -- osEnv:invoke("wrongword")
            -- assert.are.equal("suspended", coroutine.status(osEnv.subThreads.event1.thread))
            osEnv:invoke(invokeWord)
            assert.are.equal("dead", coroutine.status(osEnv.subThreads.event1.thread))
            assert.are.equal(invokeWord, testModule.status.event1)
        end)
    end)
    describe("#timer",function()
        it("#start", function()
            local file = loadfile(path, "t")
            testModule = osEnv:wrap(file, true)
            assert(testModule)

            testModule:event2(5)
            testModule:event2(5)
            testModule:event2(5)
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

            testModule:event2(5)
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
    describe("#MultipleScripts",function()
        it("#Functions", function ()
            local osEnv2 = osEmulator()
            local invokeWord = "testEvent"
            local testFunc = osEnv:wrap(function(parameter)
                assert(parameter == "parameterCheck")
                os.pullEvent(invokeWord)
            end, false)
            assert(testFunc)
            local testFunc2 = osEnv2:wrap(function(parameter)
                os.pullEvent(invokeWord)
            end, false)
            
            testFunc("parameterCheck")
            osEnv:invoke(invokeWord)
            osEnv2:invoke(invokeWord)
            assert.are.equal("dead", coroutine.status(osEnv.thread))
            assert.are.equal(nil, osEnv2.thread)
            assert.are.equal("dead", coroutine.status(osEnv.thread))
            testFunc("parameterCheck")
            assert.are.equal("suspended", coroutine.status(osEnv.thread))
            testFunc2()
            assert.are.equal("dead", coroutine.status(osEnv2.thread))
        end)
        it("#Modules", function()
            local osEnv2 = osEmulator()
            local testModule = osEnv:wrap(loadfile(path, "t"), true)
            local testModule2 = osEnv2:wrap(loadfile(path, "t"), true)
            assert(type(testModule)=="table", type(testModule))
            assert(type(testModule2)=="table", type(testModule2))
            invokeWord = "test"
            testModule:event1(invokeWord) -- start function (runs in a thread)
            testModule2:event1(invokeWord)
            osEnv:invoke(invokeWord)
            assert.are.equal("dead", coroutine.status(osEnv.subThreads.event1.thread))
            assert.are.equal(invokeWord, testModule.status.event1)
            assert.are.equal("suspended", coroutine.status(osEnv2.subThreads.event1.thread))
            assert.are.equal(nil, testModule2.status.event1)
        end)
    end)
    describe("#QueueEvents", function ()
        it("#Basic", function ()
            local testModule = osEnv:wrap(loadfile(path, "t"), true)
            assert(testModule)
            local word = "test"
            testModule:event1(word)
            testModule:queueEvent(word)
            assert.are.equal("dead", coroutine.status(osEnv.subThreads.event1.thread))
        end)
        it("#ExistingEvents", function ()
            local testModule = osEnv:wrap(loadfile(path, "t"), true)
            assert(testModule)
            local word = "test"
            testModule:queueEvent(word)
            assert.are.equal("dead", coroutine.status(osEnv.subThreads.queueEvent.thread))
            assert.are.equal(true, testModule.status.queueEvent)
            
            -- make sure functions can be restarted
            testModule.status.queueEvent = false
            testModule:queueEvent(word)
            assert.are.equal(true, testModule.status.queueEvent)
        end)
    end)
end)