---@class TestFile
local TestFile = {
    status = {}
}

function TestFile:event1()
    print("os.execute", os.execute)
    print("os.pullEvent", os.pullEvent)
    os.pullEvent()
    self.status.event1 = "Fired"
end



return TestFile