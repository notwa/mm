-- boilerplate convenience functions

require "extra"

local ram = 0x80000000
R1 = function(addr) return m64p.memory:read(addr+ram, 'u8') end
R2 = function(addr) return m64p.memory:read(addr+ram, 'u16') end
R3 = function() error('unimplemented', 2) end
R4 = function(addr) return m64p.memory:read(addr+ram, 'u32') end
RF = function(addr) return m64p.memory.read(addr+ram, 'float') end

W1 = function(addr, value) m64p.memory:write(addr+ram, 'u8', value) end
W2 = function(addr, value) m64p.memory:write(addr+ram, 'u16', value) end
W3 = function() error('unimplemented', 2) end
W4 = function(addr, value) m64p.memory:write(addr+ram, 'u32', value) end
WF = function(addr, value) m64p.memory.write(addr+ram, 'float', value) end

--[[
X1 = m.readbyte
X2 = m.read_u16_be
X3 = m.read_u24_be
X4 = m.read_u32_be
XF = function(addr) return m.readfloat(addr, true) end
--]]

local H1 = function(self, value)
    return value and W1(self.addr, value) or R1(self.addr)
end
local H2 = function(self, value)
    return value and W2(self.addr, value) or R2(self.addr)
end
local H3 = function(self, value)
    return value and W3(self.addr, value) or R3(self.addr)
end
local H4 = function(self, value)
    return value and W4(self.addr, value) or R4(self.addr)
end
local HF = function(self, value)
    return value and WF(self.addr, value) or RF(self.addr)
end

local mts = {
    [1]   = {__call = H1},
    [2]   = {__call = H2},
    [3]   = {__call = H3},
    [4]   = {__call = H4},
    ['f'] = {__call = HF},
}

function A(addr, atype)
    local mt = mts[atype]
    return setmetatable({
        addr=addr,
        type=atype,
    }, mt)
end

Class = function(inherit)
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

function getindex(obj)
    local gm = getmetatable(obj)
    if not gm then return end
    return gm.__index
end

function printf(fmt, ...)
    print(fmt:format(...))
end

function is_ptr(ptr)
    return bit.band(0xFF800000, ptr) == 0x80000000
end

function deref(ptr)
    return is_ptr(ptr) and ptr - 0x80000000
end

function asciize(bytes)
    local str = ""
    local seq = false
    for i, v in ipairs(bytes) do
        local c = type(v) == 'number' and v or tonumber(v, 16)
        if c == 9 or c == 10 or c == 13 or (c >= 32 and c < 127) then
            str = str..string.char(c)
            seq = false
        elseif seq == false then
            str = str..' '
            seq = true
        end
    end
    return str
end

function hex(i)
    -- convenience function for use in console
    if i > 0xFFFFFFFF then
        print('warning: truncated')
    end
    printf("%08X", i)
end

--[[
--  now we can just write:
handle = A(0x123456, 1)
print(handle()) -- get 1 byte at address
handle(0xFF)    -- set 1 byte at address

--  or just:
A(0x123456, 1)(0xFF) -- set address value

--  and taking advantage of A returning a table and not just a function:
A(handle.addr + 1, handle.type)(0x00) -- set the byte after our address

--  this doesn't limit us to just the type we initially specified. eg:
A(handle.addr, 2)(0x1234) -- set 2 bytes as opposed to our original 1
--]]

return A
