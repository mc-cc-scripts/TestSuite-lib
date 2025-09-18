# Events

__Includes:__
```lua
os.pullEvent()
os.startTimer()
os.queueEvent()
```
---

Restrictions:
---

__YOU CANNOT USE EVENTS GLOBALLY.__

_You cannot yield the "main" coroutine, therefore os.pullevent() cannot just be set globally.
Therefore You need to wrap everything you intent to run in the wrapper._

___Modules CANNOT yield outside of their fields__

```lua 
local TestModule = {}
-- ...
coroutine.yield() -- <- Breaks the EventManager, as the module cannot be wrapped
-- ...
return TestModule
```

How to use:
---

### Setup

1. Require the emulator-script for events and -
2. create as many managed Instances as required:
> ```lua
> local EventModule = require("events")
> local eventManager1 = EventModule()
> local eventManager2 = EventModule()
> ```
3. Load your script through the wrapper:
> ```lua
> local path = "<path to your Script>.lua"
> local file = loadfile(path, "t") -- Modules need to be loaded through loadfile, as require would run them instantly!
> local yourModule = eventManager1:wrap(file, true) -- <false> for Functions, <true> for modules
>```


### Trigger Event from the Test-env

os.queueEvent will work from within any loaded Module, however if one wants to trigger an event while testing the Module from "outside", the best way to do this, is:
> ```lua
> eventManager:invoke(eventname, ...)
> ```