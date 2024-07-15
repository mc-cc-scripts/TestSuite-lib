# Install

in your testfile(s), just add these few lines to automaticly install the test-suites in the /suits folder of your current path.

```lua
-- Check if relvant suit is found(only relevant when testing locally)
-- otherwise run the installer
if not pcall(function () io.open("./suits/vector/vector.lua", "r"):close() end) then
    print("Downloading TestSuite-lib")
    local http = require("socket.http")
    local url = "https://raw.githubusercontent.com/mc-cc-scripts/TestSuite-lib/master/installSuit.lua" -- URL of the installer
    local body, statusCode = http.request(url)
    if statusCode == 200 then
        local loader
        if _VERSION == "Lua 5.1" then 
            loader = loadstring
        else
            loader = load
        end
        local installScript = loader(body)().install()
    else
        error("Failed to download TestSuite-lib: " .. tostring(statusCode))
    end
end
```

## Planned features
Specify the install location for the suit
update files already present / add missing files