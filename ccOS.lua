local class = require("ccClass")

---@class Event
---@field eventName string
---@field eventArgs table | nil
---@field receivedBy table

---@class timer
---@field id number
---@field triggerAfter number

---@class timerList
---@field timers timer[]
---@field currentID number

---@class subThread
---@field originalFunction function 
---@field thread thread
---@field waiting boolean

---@class ccOS
---@field FIFOEventList Event[]
---@field TimerList timerList
---@field thread thread
---@field subThreads table<string, subThread>
---@field time number eq. os.time("ingame") from ccTweaked)
---@field epoch number eq. os.epoch("ingame") from ccTweaked)
---@field private run thread
local ccOS = class(
    function(baseClass)
        ---@cast baseClass ccOS
        baseClass.FIFOEventList = {}
        baseClass.TimerList = {timers = {}, currentID = 1}
        baseClass.time = 0
        baseClass.epoch = 0
        baseClass.subThreads = {}
        baseClass.run = coroutine.create(
            function()
                while true do
                    while #baseClass.FIFOEventList > 0 do -- TODO if a DID trigger something, stop?
                        local event = table.remove(baseClass.FIFOEventList, 1)
                        ---@cast event Event
                        if coroutine.status(baseClass.thread) == "suspended" then -- Modules should be "dead"
                            coroutine.resume(baseClass.thread, event.eventName, table.unpack(event.eventArgs))
                            -- just empty the list until an event was valid OR no Events are left
                        end
                        for key, value in pairs(baseClass.subThreads) do
                            if value.waiting then
                                assert(coroutine.resume(value.thread, event.eventName, table.unpack(event.eventArgs)))
                                if coroutine.status(value.thread) == "dead" then 
                                    value.waiting = false
                                end
                            end
                        end
                    end
                    coroutine.yield("tick")
                end
            end
        )
    end
)

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
            local firstStart = true
            local event
            while firstStart or (event[1] ~= expectedEventName) do
                event = {coroutine.yield(expectedEventName)}
                firstStart = false
            end
            return table.unpack(event)
        end,
        queueEvent = function(name, ...)
            ccOSInstance:invoke(name, ...)
        end,
        startTimer = function(time)
            assert(type(time) == "number")
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

    
    self.thread = coroutine.create(func)
    
    if(not wrapModule) then
        return function(...)
            local ok, result = coroutine.resume(self.thread, ...)
            assert(ok, "coroutine Error: "..tostring(result))
            return result
        end
    end
    
    local ok, result = coroutine.resume(self.thread, ...)
    assert(ok, "Could not load Module")
    assert(type(result) == "table")
    for k,v in pairs(result) do
        if type(v) == "function" and (self.subThreads[k] == nil)then
            local thread = coroutine.create(v)
                self.subThreads[k] = {
                    thread = thread,
                    originalFunction = v,
                    waiting = false
                }
            result[k] =  function(...)
                local ok, result = coroutine.resume(self.subThreads[k].thread, ...)
                local status = coroutine.status(self.subThreads[k].thread)
                if status == "dead" then 
                    -- "restart" function => create new Thread
                    self.subThreads[k].thread = coroutine.create(self.subThreads[k].originalFunction)
                    self.subThreads[k].waiting = false
                else
                    self.subThreads[k].waiting = true
                end
                assert(ok, "coroutine Error: "..tostring(result))
                return result
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
    self.time = (self.time + (time / 60 / 24)) % 24 -- TODO: Test
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
    self.newEventAdded = true
    assert(coroutine.resume(self.run, "tick"))
end

return ccOS