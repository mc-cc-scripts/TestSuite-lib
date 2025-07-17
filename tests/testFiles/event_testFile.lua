---@class TestFile
local TestFile = {
    status = {}
}

function TestFile:event1(p1)
    local event = os.pullEvent(p1)
    self.status.event1 = event
    return p1
end



return TestFile