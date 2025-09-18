---@class TestFile
local TestFile = {
    status = {}
}
---@type EventOS
os = os

function TestFile:event1(p1)
    local event = os.pullEvent(p1)
    self.status.event1 = event
    return p1
end

function TestFile:event2(amount)
    local timerID = os.startTimer(amount)
    self.status.event2 = timerID
    local event, id = os.pullEvent("timer")
    if (id ~= 1) then error("Wrong timer triggerd") end
    self.status.event2 = nil
    event = os.pullEvent("timer")
    self.status.event2 = "Should not be filled"
end

function TestFile:queueEvent(eventName)
    os.queueEvent(eventName)
    os.pullEvent(eventName)
    self.status.queueEvent = true
    return true
end
function TestFile:event3()
    os.sleep(5)
    self.status.event3 = true
end



return TestFile