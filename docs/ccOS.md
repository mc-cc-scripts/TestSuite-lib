# OS

## How to use

### for functions
```lua
-- import 
local osEmulator = require("ccOS")

-- create instance
local osInstance = osEmulator()

local testFunction = osInstance:wrap(function()
    os.pullEvent("CustomEvent")
    print("Event got called")
end)

testFunction() -- < Programm yields until event gets invoked, in the instances' thread
osInstance:invoke("CustomEvent") -- < Programm continues -> prints: "Event got called"

```

### for Modules
```lua
local osEmulator = require("ccOS")
-- create instance
local osInstance = osEmulator()

local moduleFile = loadfile("someModule","t")
local testModule = osInstance:wrap(moduleFile, true, ...)
-- <true> tells the wrapper to wrap all functioncalls, so they run in a coroutine thread, instead of the callers thread
-- <...> as the module will need to be called once, you can provide additional parameters as need

testModule:someFunction(...)
-- the function will now run on the osInstance-Thread, knowing all currently implemented os-Functions
```