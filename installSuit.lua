-- Install all lua script in /suits, respecting the files.txt


local http = require("socket.http")

---@class installSuit
local installSuit = {}

installSuit.http = http
installSuit.source = "https://raw.githubusercontent.com/mc-cc-scripts/TestSuite-lib/master/"
installSuit.suitPath = "./suits/"

function installSuit.getFileTxt()
    local content, c, h = http.request(installSuit.source .. "files.txt")
    if c ~= 200 then
        error("Error: files.txt not found")
    end
    return content
end

function installSuit.install()
    local files = installSuit.getFileTxt()
    os.execute("mkdir -p " .. installSuit.suitPath)
    for line in files:gmatch("[^\r\n]+") do
        -- cut leading "/", if it exists
        if line:sub(1, 1) == "/" then
            line = line:sub(2)
        end

        local content, c, h = http.request(installSuit.source .. line)
        if c ~= 200 then
            error("Error: file ".. line .." not found")
        end
        local path = line:match("^(.*/)")
        if path then
            os.execute("mkdir -p " .. installSuit.suitPath .. path)
        end
        -- create the file
        local f = io.open(installSuit.suitPath .. line, "w")
        if not f then
            error("Error: could not create file ".. installSuit.suitPath .. line)
        end
        f:write(content)
        f:close()
    end
end
return installSuit