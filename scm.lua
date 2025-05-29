--- This simulates the files requried from the SCM module
local scm = {}

function scm:load(name)
    local success, result = pcall(function()
        return require(name)
    end)
    if success then
        return result
    else
        print(debug.traceback("Error while loading Module: " .. name))
        error(result)
    end

end


return scm