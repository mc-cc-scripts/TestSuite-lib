--- Returns only the class, not in instance of it!
---
--- Init by _classname_(...), which returns an Instance!
---@source http://lua-users.org/wiki/SimpleLuaClasses
---@param base function | table initfunction | baseclass
---@param init function | nil new InitFunction, overrides base init
---@return table
function Class(base, init)
    local c = {}
    if not init and type(base) == 'function' then
        -- New class
        init = base;
        base = nil;
    elseif type(base) == "table" then
        -- Inherited from base
        for i, v in pairs(base) do
            c[i] = v
        end
        c._base = base
    end
    -- the class will be the metatable for all its objects,
    -- and they will look up their methods in it.
    c.__index = c

    --constructor
    local mt = {}
    mt.__call = function(class_tbl, ...)
        local obj = {}
        setmetatable(obj, c)
        if init then
            init(obj, ...)
        else
            if base and base.init then
                base.init(obj, ...)
            end
        end
        return obj
    end
    c.init = init
    c.is_a = function(self, class)
        local m = getmetatable(self)
        while m do
            if m == class then return true end
            m = m._base
        end
        return false
    end
    setmetatable(c, mt)
    return c
end

return Class