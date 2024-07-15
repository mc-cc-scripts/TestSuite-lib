local helperFunctions = {}

function helperFunctions.deepCopy(t)
    local u = {}
    for k, v in pairs(t) do u[k] = v end
    return setmetatable(u, getmetatable(t))
end

return helperFunctions
