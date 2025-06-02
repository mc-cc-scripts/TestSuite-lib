---@source https://raw.githubusercontent.com/cc-tweaked/CC-Tweaked/876fd8ddb805365c33942afb81d6da7cbd0cbca5/projects/core/src/main/resources/data/computercraft/lua/rom/apis/textutils.lua

local TextUtils = {}

--#region local functions

local g_tLuaKeywords = {
    ["and"] = true,
    ["break"] = true,
    ["do"] = true,
    ["else"] = true,
    ["elseif"] = true,
    ["end"] = true,
    ["false"] = true,
    ["for"] = true,
    ["function"] = true,
    ["if"] = true,
    ["in"] = true,
    ["local"] = true,
    ["nil"] = true,
    ["not"] = true,
    ["or"] = true,
    ["repeat"] = true,
    ["return"] = true,
    ["then"] = true,
    ["true"] = true,
    ["until"] = true,
    ["while"] = true,
}

--- A version of the ipairs iterator which ignores metamethods
local function inext(tbl, i)
    i = (i or 0) + 1
    local v = rawget(tbl, i)
    if v == nil then return nil else return i, v end
end

local serialize_infinity = math.huge
local function serialize_impl(t, tracking, indent, opts)
    local sType = type(t)
    if sType == "table" then
        if tracking[t] ~= nil then
            if tracking[t] == false then
                error("Cannot serialize table with repeated entries", 0)
            else
                error("Cannot serialize table with recursive entries", 0)
            end
        end
        tracking[t] = true

        local result
        if next(t) == nil then
            -- Empty tables are simple
            result = "{}"
        else
            -- Other tables take more work
            local open, sub_indent, open_key, close_key, equal, comma = "{\n", indent .. "  ", "[ ", " ] = ", " = ", ",\n"
            if opts.compact then
                open, sub_indent, open_key, close_key, equal, comma = "{", "", "[", "]=", "=", ","
            end

            result = open
            local seen_keys = {}
            for k, v in inext, t do
                seen_keys[k] = true
                result = result .. sub_indent .. serialize_impl(v, tracking, sub_indent, opts) .. comma
            end
            for k, v in next, t do
                if not seen_keys[k] then
                    local sEntry
                    if type(k) == "string" and not g_tLuaKeywords[k] and string.match(k, "^[%a_][%a%d_]*$") then
                        sEntry = k .. equal .. serialize_impl(v, tracking, sub_indent, opts) .. comma
                    else
                        sEntry = open_key .. serialize_impl(k, tracking, sub_indent, opts) .. close_key .. serialize_impl(v, tracking, sub_indent, opts) .. comma
                    end
                    result = result .. sub_indent .. sEntry
                end
            end
            result = result .. indent .. "}"
        end

        if opts.allow_repetitions then
            tracking[t] = nil
        else
            tracking[t] = false
        end
        return result

    elseif sType == "string" then
        return string.format("%q", t)

    elseif sType == "number" then
        if t ~= t then --nan
            return "0/0"
        elseif t == serialize_infinity then
            return "1/0"
        elseif t == -serialize_infinity then
            return "-1/0"
        else
            return tostring(t)
        end

    elseif sType == "boolean" or sType == "nil" then
        return tostring(t)

    else
        error("Cannot serialize type " .. sType, 0)

    end
end

--#endregion

function TextUtils.serialize(t, opts)
    local tTracking = {}
    return serialize_impl(t, tTracking, "", opts or {})
end

---@param s string
---@return table | nil
function TextUtils.unserialize(s)
    if type(s) ~= "string" then
        return nil
    end
    local func = loadstring("return " .. s, "unserialize", "t", {})
    if func then
        local ok, result = pcall(func)
        if ok then
            return result
        end
    end
    return nil
end

return TextUtils