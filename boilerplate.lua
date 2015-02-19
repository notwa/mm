-- boilerplate convenience functions
-- TODO: respect little endian consoles too

local mm = mainmemory

function M1(self, value)
    return (value and mm.writebyte or mm.readbyte)(self.addr, value)
end
function M2(self, value)
    return (value and mm.write_u16_be or mm.read_u16_be)(self.addr, value)
end
function M3(self, value)
    return (value and mm.write_u24_be or mm.read_u24_be)(self.addr, value)
end
function M4(self, value)
    return (value and mm.write_u32_be or mm.read_u32_be)(self.addr, value)
end
function MF(self, value)
    return (value and mm.writefloat or mm.readfloat)(self.addr, value or true, true)
end

local Ms = {
    [1]   = {__call = M1},
    [2]   = {__call = M2},
    [3]   = {__call = M3},
    [4]   = {__call = M4},
    ['f'] = {__call = MF},
}

function A(addr, atype)
    return setmetatable({addr=addr, type=atype}, Ms[atype])
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
