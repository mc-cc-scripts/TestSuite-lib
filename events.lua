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

---@class ccEvent
---@field FIFOEventList Event[]
---@field FIFOTimerList timerList
---@field co thread
---@field time number eq. os.time("ingame") from ccTweaked)
---@field epoch number eq. os.epoch("ingame") from ccTweaked)
---@field private tmpObj any
local Events = {}

---@param path string
---@return ccEvent
---@return table loadedModule
function Events:new(path)

    local eventObj = class(function(baseClass)
        ---@cast baseClass ccEvent
        baseClass.FIFOEventList = {}
        baseClass.FIFOTimerList = {timers = {}, currentID = 1}
        baseClass.time = 0
        baseClass.epoch = 0
        
    end)()
    
    local env = {}
        ---@class EventOS: oslib
    env.os = setmetatable({

        pullEvent = function(name)
            local t = {coroutine.yield(name)}
            while not t or (name and t[1] ~= name) do
                t = {coroutine.yield(name, "does not match")}
            end
            return table.unpack(t)
        end,
        queueEvent = function(name, ...)
            eventObj:invoke(name, arg)
        end,
        startTimer = function(time)
            return eventObj:addTimer(time)
        end,
        cancleTimer = function(id)
            eventObj:removeTimer(id)
        end

    }, {__index = os})
    setmetatable(env, {__index = _G})
    
    print("stuff", env.os.pullEvent)
    local func = assert(loadfile(path, "t", env))
    print("func", func)

    eventObj.co = coroutine.create(function ()
        return func()
    end)
    local _, loadedModule = coroutine.resume(eventObj.co)
    return eventObj, loadedModule
end



---@param ccEvent ccEvent
local run = coroutine.create(function(ccEvent)
    while true do
        while #ccEvent.FIFOEventList > 0 and coroutine.status(ccEvent.co) == "suspended" do
            coroutine.resume(ccEvent.co, table.remove(ccEvent.FIFOEventList, 1))
            -- just empty the list until an event was valid OR no Events are left
        end
        coroutine.yield("tick")
    end
end)

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
    local event = {eventName = eventName, receivedBy = {}, eventArgs = arg}
    table.insert(self.FIFOEventList, event)
    self.newEventAdded = true
    coroutine.resume(run, "tick")
end

return Events