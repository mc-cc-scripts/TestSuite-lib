---@class TestFile
local TestFile = {
    status = {}
}

function TestFile:event1(p1)
    local event = os.pullEvent(p1)
    self.status.event1 = event
    return p1
end

function TestFile:event2()
    local timerID = os.startTimer(5)
    self.status.event2 = timerID
    local event, id = os.pullEvent("timer")
    if (id ~= 1) then error("Wrong timer triggerd") end
    self.status.event2 = nil
    event = os.pullEvent("timer")
    self.status.event2 = "Should not be filled"

end

function TestFile:event3()
    os.sleep(5)
    self.status.event3 = true
end



return TestFile