local class = require("ccClass")

---@class Event
---@field eventName string
---@field eventArgs table | nil
---@field receivedBy table

---@class _pullEventWrapper
---@field expectedEventName string
---@field firstStart boolean

---@class Promise
---@field fullFilled boolean
---@field currentValue any

---@class timer
---@field id number
---@field triggerAfter number

---@class timerList
---@field timers timer[]
---@field currentID number

---@class subThread
---@field originalFunction function 
---@field thread thread
---@field promise Promise
---@field waiting boolean To confirm if a function was actually called or is just wrapped.
-- Relevant for Events.run, as it resumes ALL coroutines - therefore invoking each method if not for this check

---@class ccOS : subThread
---@field FIFOEventList Event[]
---@field TimerList timerList
---@field subThreads table<string, subThread>
---@field time number eq. os.time("ingame") from ccTweaked)
---@field epoch number eq. os.epoch("ingame") from ccTweaked)
local ccOS = class(
    function(baseClass)
        ---@cast baseClass ccOS
        baseClass.FIFOEventList = {}
        baseClass.TimerList = {timers = {}, currentID = 1}
        baseClass.time = 0
        baseClass.epoch = 0
        baseClass.subThreads = {}
    end
)

---comment
---@param threadHolder subThread
---@param ... any
function ccOS:resumeThread(threadHolder, ...)
    local ok
    local wrapper
    local result
    
    ok, result = coroutine.resume(threadHolder.thread, ...)
    ---@cast result _pullEventWrapper | any
    
    wrapper = type(result) =="table" and (result.firstStart or result.firstStart == false)
    local status = coroutine.status(threadHolder.thread)
    threadHolder.promise.currentValue = wrapper and result.expectedEventName or result
    threadHolder.promise.fullFilled = status == "dead"
    threadHolder.waiting = not threadHolder.promise.fullFilled
    assert(ok, debug.traceback("coroutine Error: "..tostring(result))) --TODO: Checkout current behaviour
    if wrapper and result.firstStart and status == "suspended" then
        result.firstStart = false
        -- TODO: If there is a coroutine.yield with a table containing this value -> I need a better way to guard...
        -- this is required bc. the test-script would normaly be in the "main" thread, therefore it would resume instantly
        -- on os.pullEvent, assuming there is an Event already waiting prior
        self:checkForUpdates()
    end
    return ok, threadHolder.promise.currentValue
end

---@generic T
---@param func function | T
---@param wrapModule? boolean This will modify the Module!
---@param ... any If loading a Module, these are the parameters
---@return T|nil result if module is wrapped, it returns the wrapped module. 
function ccOS:wrap(func, wrapModule, ...)
    assert(self.subThreads, "Do not use Eventclass, create an Event-Object via 'local eventObj = ccEvent()'")
    local ccOSInstance = self
    local env = {}
        ---@class EventOS: oslib
    env.os = setmetatable({

        pullEvent = function(expectedEventName)
            ---@type _pullEventWrapper
            local _pullEventWrapper = {expectedEventName = expectedEventName, firstStart = true}
            local event
            while _pullEventWrapper.firstStart or (expectedEventName ~= nil and (event[1] ~= expectedEventName)) do
                event = {coroutine.yield(_pullEventWrapper)}
                ---@cast event Event
            end
            return table.unpack(event)
        end,
        queueEvent = function(name, ...)
            ccOSInstance:invoke(name, ...)
        end,
        startTimer = function(time)
            assert(type(time) == "number" ,type(time))
            return ccOSInstance:addTimer(time)
        end,
        cancleTimer = function(id)
            ccOSInstance:removeTimer(id)
        end,
        sleep = function(time)
            local expectedId = env.os.startTimer(time)
            local correctTimer = false
            while not correctTimer do
                local _, id = env.os.pullEvent("timer")
                correctTimer = id == expectedId
            end
        end,
        time = function()
            -- TODO: add locale
            return ccOSInstance.time
        end,
        epoch = function()
            -- TODO: add args
            return ccOSInstance.epoch
        end,

    }, {__index = os})
    setmetatable(env, {__index = _G})
    setfenv(func, env)

    
    
    if(not wrapModule) then
        self.originalFunction = func
        return function(...)
            if self.thread == nil or coroutine.status(self.thread) == "dead" then 
                self.waiting = true
                self.promise = {
                    currentValue = nil,
                    fullFilled = false
                }
                -- "restart" function => create new Thread
                self.thread = coroutine.create(self.originalFunction)
                
                self.waiting = false
            end
            local ok, result = self:resumeThread(self, ...)
            assert(ok, "coroutine Error: "..tostring(result))
            return result
        end
    end
    local thread = coroutine.create(func)
    local ok, result = coroutine.resume(thread, ...)
    assert(ok, "Could not load Module")
    assert(type(result) == "table", "Module could not be loaded")
    for k,v in pairs(result) do
        if type(v) == "function" and (self.subThreads[k] == nil)then
            local thread = coroutine.create(v)
            self.subThreads[k] = {
                thread = thread,
                originalFunction = v,
                waiting = false,
                promise = {
                    currentValue = nil,
                    fullFilled = false
                }
            }
            result[k] =  function(...)
                
                local status = coroutine.status(self.subThreads[k].thread)
                if status == "dead" then 
                    -- "restart" function => create new Thread
                    self.subThreads[k].thread = coroutine.create(self.subThreads[k].originalFunction)
                    self.subThreads[k].waiting = false
                end
                self:resumeThread(self.subThreads[k], ...)

                return self.subThreads[k].promise
            end
        end
    end

    return result
end


---@param time number seconds
---@return number timerID
function ccOS:addTimer(time)
    assert(type(time) == "number" and time > 0)
    local triggerAfter = time * 1000 + self.epoch - 1
    local id = self.TimerList.currentID
    self.TimerList.currentID = self.TimerList.currentID + 1
    table.insert(self.TimerList.timers, {triggerAfter = triggerAfter, id = id})
    return id
end

function ccOS:removeTimer(id)
    assert(type(id) == "number")
    for k,v in pairs(self.TimerList.timers) do
        if v.id == id then
            self.TimerList.timers[id] = nil
        end
    end
end

---Passes time (in Seconds)
---Required for timers
---@param time number seconds
function ccOS:passTime(time)
    assert(type(time) == "number")
    time = time * 1000
    self.time = (self.time + (time / 60 / 24)) % 24
    self.epoch = self.epoch + time

    for key, value in pairs(self.TimerList.timers) do
        if value.triggerAfter < self.epoch then
            self:invoke("timer", value.id)
            self.TimerList.timers[key] = nil
        end
    end

end

function ccOS:invoke(eventName, ...)
    ---@type Event
    local event = {eventName = eventName, receivedBy = {}, eventArgs = {...}}
    table.insert(self.FIFOEventList, event)
    self:checkForUpdates()
end

function ccOS:checkForUpdates()
    local modifier = 0
    
    local removeEvent = function(i)
            table.remove(self.FIFOEventList, i + modifier)
            modifier = modifier - 1;
    end

    for i = 1,#self.FIFOEventList do
        local read = false
        local event = self.FIFOEventList[i + modifier]
        ---@cast event Event
        if self.waiting and coroutine.status(self.thread) == "suspended" then -- On it Modules should be "dead"
        
            removeEvent(i)
            assert(self:resumeThread(self, event.eventName, table.unpack(event.eventArgs)))

        end
        for key, value in pairs(self.subThreads) do -- should be empty on Function
            -- if status = running -> The thread making the call,- obvious skip
            if value.waiting and coroutine.status(value.thread) ~= "normal" then
                removeEvent(i)
                assert(self:resumeThread(value, event.eventName, table.unpack(event.eventArgs)))
                if coroutine.status(value.thread) == "dead" then 
                    value.waiting = false
                end
                break;
            end
        end
    end
end


return ccOS
