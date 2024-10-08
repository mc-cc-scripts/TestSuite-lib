local cPath = debug.getinfo(1).source:match("@?(.*/)")
cPath = string.gsub(cPath, "/vector/", "/ccClass/ccClass")
---@type function
local class = require(cPath)

---@class Vector
---@field x number
---@field y number
---@field z number
---@field new function @Create a new Vector
---@field add function @Add two vectors
---@field sub function @Subtract two vectors
---@field mul function @Multiply by value
---@field div function @Divide by value
---@field unm function @negate the vector
---@field dot function @dot product of two vectors
---@field cross function @cross product of two vectors
---@field length function @magnitude / length of the vector
---@field norm function @normalize the vector
---@field round function @round the vector
---@field toString function @Returns a String of the vector
---@field equals function @check if two vectors are equal

---@type Vector
---@diagnostic disable-next-line: missing-fields
local Vector = {}

---Create a new Vector
---@param x number
---@param y number
---@param z number
---@return Vector
function Vector.new(x, y, z)
    assert(type(x) == "number", "x must be a number")
    assert(type(y) == "number", "y must be a number")
    assert(type(z) == "number", "z must be a number")
    local mt = {
        __add = Vector.add,
        __sub = Vector.sub,
        __mul = Vector.mul,
        __div = Vector.div,
        __unm = Vector.unm,
        __tostring = Vector.toString,
        __eq = Vector.equals,
        __index = Vector
    }
    local v = setmetatable({}, mt)
    v.x = x or 0
    v.y = y or 0
    v.z = z or 0
    return v
end

--- Add two vectors
---@param other Vector
---@return Vector
function Vector:add(other)
    return Vector.new(self.x + other.x, self.y + other.y, self.z + other.z)
end

--- Subtract two vectors
---@param other Vector
---@return Vector
function Vector:sub(other)
    return Vector.new(self.x - other.x, self.y - other.y, self.z - other.z)
end

--- Multiply by value
---@param value number
---@return Vector
function Vector:mul(value)
    return Vector.new(self.x * value, self.y * value, self.z * value)
end

--- Divide by value
---@param value number
---@return Vector
function Vector:div(value)
    return Vector.new(self.x / value, self.y / value, self.z / value)
end

--- negate the vector
---@return Vector
function Vector:unm()
    return Vector.new(-self.x, -self.y, -self.z)
end

--- dot product of two vectors
---@param other Vector
---@return number
function Vector:dot(other)
    return self.x * other.x + self.y * other.y + self.z * other.z
end

--- cross product of two vectors
---@param other Vector
---@return Vector
function Vector:cross(other)
    return Vector.new(
        self.y * other.z - self.z * other.y,
        self.z * other.x - self.x * other.z,
        self.x * other.y - self.y * other.x
    )
end

--- magnitude / length of the vector
---@return number
function Vector:length()
    return math.sqrt(self.x * self.x + self.y * self.y + self.z * self.z)
end

---normalize the vector
---@return Vector
function Vector:norm()
    return self:mul(1/self:length())
end

--- round the vector
---@return Vector
---@param tolerance number -- default 1.0. - f.e.: 0.1 will round to the nearest 0.1
---@source https://github.com/cc-tweaked/CC-Tweaked/blob/d77f5f135f9251d027cc900dc27fd80160b632b9/projects/core/src/main/resources/data/computercraft/lua/rom/apis/vector.lua#L168
function Vector:round(tolerance)
    tolerance = tolerance or 1.0
    return Vector.new(
        math.floor((self.x + tolerance * 0.5) / tolerance) * tolerance,
        math.floor((self.y + tolerance * 0.5) / tolerance) * tolerance,
        math.floor((self.z + tolerance * 0.5) / tolerance) * tolerance
    )
end

--- Returns a String of the vector
---@return string
function Vector:toString()
    return self.x .. "," .. self.y .. "," .. self.z
end

--- check if two vectors are equal
---@param other any
---@return boolean
function Vector:equals(other)
    return self.x == other.x and self.y == other.y and self.z == other.z
end

---Rotate the vector by a given angle (90, 180, 270 degrees) around the Z-axis
---@param angle number @The angle to rotate (90, 180, or 270)
---@return Vector
function Vector:rotate(angle)
    local newX, newZ
    if angle == 90 then
        newX = -self.z
        newZ = self.x
    elseif angle == 180 then
        newX = -self.x
        newZ = -self.z
    elseif angle == 270 then
        newX = self.z
        newZ = -self.x
    else
        error("Invalid angle. Only 90, 180, and 270 degrees are supported.")
    end
    return Vector.new(newX,self.y, newZ)
end


return Vector