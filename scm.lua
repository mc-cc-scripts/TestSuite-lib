--- This simulates the files requried from the SCM module
local scm = {}

function scm:load(name)
    return require(name)
end


return scm