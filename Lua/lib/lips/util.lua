local floor = math.floor
local open = io.open

local function Class(inherit)
    local class = {}
    local mt_obj = {__index = class}
    local mt_class = {
        __call = function(self, ...)
            local obj = setmetatable({}, mt_obj)
            obj:init(...)
            return obj
        end,
        __index = inherit,
    }

    return setmetatable(class, mt_class)
end

local function readfile(fn, binary)
    local mode = binary and 'rb' or 'r'
    local f = open(fn, mode)
    if not f then
        local kind = binary and 'binary' or 'assembly'
        error('could not open '..kind..' file for reading: '..tostring(fn), 2)
    end
    local data = f:read('*a')
    f:close()
    return data
end

local function bitrange(x, lower, upper)
    return floor(x/2^lower) % 2^(upper - lower + 1)
end

return {
    Class = Class,
    readfile = readfile,
    bitrange = bitrange,
}
