---@type installSuit
local installer = require "./installSuit"

describe("installSuit", function()
    setup(function ()
        stub(installer.http, "request", function (...)
            local url = ...
            -- cut "https://raw.githubusercontent.com/mc-cc-scripts/TestSuite-lib/master" out of the url
            local filepath = url:sub(#installer.source + 1)
            local file = io.open("./"..filepath, "r")
            if not file then
                return "404:Not Found", 400, nil
            end
            local content = file:read("*all")
            file:close()
            return content, 200, nil
        end)
    end)
    after_each(function ()
        os.execute("rm -rf " .. installer.suitPath)
    end)

    it("should install all files", function()
        installer.install()
        io.open("./suits/vector/vector.lua", "r"):close()
        io.open("./suits/http/http.lua", "r"):close()
        io.open("./suits/helperFunctions/helperFunctions.lua", "r"):close()
        io.open("./suits/json/json.lua", "r"):close()
        io.open("./suits/fs/fs.lua", "r"):close()
        io.open("./suits/ccClass/ccClass.lua", "r"):close()
    end)

    it("vector should require the correct files", function()
        installer.install()
        local vector = require(installer.suitPath.."/vector/vector")
        assert.is_table(vector)
        assert.is_function(vector.new)
        assert.is_table(vector.new(1, 2, 3))
    end)

end)