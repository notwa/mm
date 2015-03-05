-- boilerplate convenience functions
-- TODO: respect little endian consoles too

local mm = mainmemory

R1 = mm.readbyte
R2 = mm.read_u16_be
R3 = mm.read_u24_be
R4 = mm.read_u32_be
RF = function(addr) return mm.readfloat(addr, true) end

W1 = mm.writebyte
W2 = mm.write_u16_be
W3 = mm.write_u24_be
W4 = mm.write_u32_be
WF = function(addr, value) mm.writefloat(addr, value, true) end

local readers = {
    [1]   = R1,
    [2]   = R2,
    [3]   = R3,
    [4]   = R4,
    ['f'] = RF,
}

local writers = {
    [1]   = W1,
    [2]   = W2,
    [3]   = W3,
    [4]   = W4,
    ['f'] = WF,
}

local mt = {
    __call = function(self, value)
        return value and self.write(self.addr, value) or self.read(self.addr)
    end
}

function A(addr, atype)
    return setmetatable({
        addr=addr,
        type=atype,
        read=readers[atype],
        write=writers[atype]
    }, mt)
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
