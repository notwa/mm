require = require "depend"
require "boilerplate"
require "addrs.init"
local assemble = require "inject.lips"

if version ~= "M US10" then
    print("Sorry, inject.lua is unimplemented for your version.")
    return
end

local asm_path
if bizstring then
    asm_path = "inject/spawn.asm"
else
    asm_path = "./mm/Lua/inject/spawn.asm"
end

local inject_addr, inject_maxlen, ow_addr, ow_before
inject_addr = 0x780000
inject_maxlen = 0x5A800
ow_addr = 0x1749D0
ow_before = 0x0C05CEC6
--ow_addr = 0x174750
--ow_before = 0x0C05D06A

local ss_fn = 'inject temp.State'

-- do it

local ow_after = 0x0C000000 + math.floor(inject_addr/4)
if R4(ow_addr) ~= ow_before and R4(ow_addr) ~= ow_after then
    print("Can't inject -- game code is different!")
    return
end

local ow_before_addr = (ow_before % 0x4000000)*4

local header = ("[overwritten]: 0x%08X\n"):format(ow_before_addr)
header = header..[[
        // TODO: optimize for size
        // TODO: fix case where overwritten function takes 5+ args
        push    ra
        push    a0, a1, a2, a3
        bal     start
        nop
        pop     a0, a1, a2, a3
        jal     @overwritten
        nop
        jpop    ra
start:
]]

local inject = {}
local length = 0
local add_inject = function(line)
    length = length + #line/2
    table.insert(inject, tonumber(line, 16))
end
local true_offset = 0x80000000 + inject_addr
assemble(header, add_inject, {unsafe=true, offset=true_offset})
assemble(asm_path, add_inject, {unsafe=true, offset=true_offset + length})
printf("length: %i words", length/4)

if #inject > inject_maxlen then
    print("Assembly too large!")
    return
end

for i, v in ipairs(inject) do
    W4(inject_addr + (i - 1)*4, v)
end

-- finally, inject over jal
printf('%08X: %08X', ow_addr, ow_after)
W4(ow_addr, ow_after)

-- force code cache to be reloaded
if bizstring then
    savestate.save(ss_fn)
    savestate.load(ss_fn)
else
    m64p.reloadCode()
end
