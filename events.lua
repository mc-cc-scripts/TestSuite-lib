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
---@field thread thread
---@field waiting boolean

---@class ccEvent
---@field FIFOEventList Event[]
---@field FIFOTimerList timerList
---@field thread thread
---@field subThreads table<string, subThread>
---@field time number eq. os.time("ingame") from ccTweaked)
---@field epoch number eq. os.epoch("ingame") from ccTweaked)
---@field private run thread
local Events = class(
    function(baseClass)
        ---@cast baseClass ccEvent
        baseClass.FIFOEventList = {}
        baseClass.FIFOTimerList = {timers = {}, currentID = 1}
        baseClass.time = 0
        baseClass.epoch = 0
        baseClass.subThreads = {}
        baseClass.run = coroutine.create(
            function()
                while true do
                    while #baseClass.FIFOEventList > 0 do
                        local event = table.remove(baseClass.FIFOEventList, 1)
                        ---@cast event Event
                        if coroutine.status(baseClass.thread) == "suspended" then -- Modules should be "dead"
                            coroutine.resume(baseClass.thread, event.eventName, table.unpack(event.eventArgs))
                            -- just empty the list until an event was valid OR no Events are left
                        end
                        for key, value in pairs(baseClass.subThreads) do
                            if value.waiting then
                                assert(coroutine.status(value.thread) == "suspended")
                                assert(coroutine.resume(value.thread, event.eventName, table.unpack(event.eventArgs)))
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
---@return T|any|nil result if module is wrapped, it returns the wrapped module. 
function Events:wrap(func, wrapModule, ...)
    assert(self.subThreads, "Do not use Eventclass, create an Event-Object via 'local eventObj = ccEvent()'")
    local manager = self
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
            manager:invoke(name, arg)
        end,
        startTimer = function(time)
            return manager:addTimer(time)
        end,
        cancleTimer = function(id)
            manager:removeTimer(id)
        end

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
                waiting = false
            }
            result[k] =  function(...)
                local ok, result = coroutine.resume(self.subThreads[k].thread, ...)
                self.subThreads[k].waiting = coroutine.status(self.subThreads[k].thread) == "suspended"
                assert(ok, "coroutine Error: "..tostring(result))
                return result
            end
        end
    end

    return result
end



function Events:addTimer(time)
    local triggerAt = time * 1000 + self.epoch
    local id = self.FIFOTimerList.currentID
    self.FIFOTimerList.currentID = self.FIFOTimerList.currentID + 1
    table.insert(self.FIFOTimerList.timers, {triggerAt = triggerAt, id = id})
    return id
end

function Events:removeTimer(id)
    for k,v in pairs(self.FIFOTimerList.timers) do
        if v.id == id then
            self.FIFOTimerList.currentID[id] = nil
        end
    end
end

---Passes time (in Seconds)
---Required for timers
---@param time number seconds
function Events:passTime(time)
    self.time = (self.time + (time / 60 / 24)) % 24
    self.epoch = self.epoch + time

    for key, value in pairs(self.FIFOTimerList.timers) do
        if value.triggerAfter <= self.epoch then
            self:invoke("timer", value.id)
        end
    end

end

function Events:invoke(eventName, ...)
    ---@type Event
    local event = {eventName = eventName, receivedBy = {}, eventArgs = ... or {}}
    table.insert(self.FIFOEventList, event)
    self.newEventAdded = true
    assert(coroutine.resume(self.run, "tick"))
end

return Events