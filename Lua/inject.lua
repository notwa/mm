require = require "depend"
require "boilerplate"
require "addrs.init"
require "messages"
local assemble = require "inject.lips"

local injection_points = {
    ['M US10'] = {
        inject_addr = 0x780000,
        inject_maxlen = 0x5A800,
        ow_addr = 0x1749D0,
        ow_before = 0x0C05CEC6,
    },
    ['M JP10'] = {
        inject_addr = 0x780000,
        inject_maxlen = 0x5A800,
        ow_addr = 0x1701A8,
        ow_before = 0x0C05BCD4,
    },
    ['O US10'] = {
        inject_addr = 0x3BC000,
        inject_maxlen = 0x1E800,
        ow_addr = 0x0A19C8,
        ow_before = 0x0C0283EE,
    },
}

local header = [[
[overwritten]: 0x%08X
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

injection_points['O JP10'] = injection_points['O US10']

function inject(fn)
    local asm_dir = bizstring and 'inject/' or './mm/Lua/inject/'
    local asm_path = asm_dir..fn

    local point = injection_points[version]
    if point == nil then
        print("Sorry, inject.lua is unimplemented for your game version.")
        return
    end

    -- seemingly unused region of memory
    local inject_addr = point.inject_addr
    -- how much room we have to work with
    local inject_maxlen = point.inject_maxlen
    -- the jal instruction to overwrite with our hook
    local ow_addr = point.ow_addr
    -- what its value is normally supposed to be
    local ow_before = point.ow_before

    -- encode our jal instruction
    local ow_after = 0x0C000000 + math.floor(inject_addr/4)
    if R4(ow_addr) ~= ow_before and R4(ow_addr) ~= ow_after then
        print("Can't inject -- game code is different!")
        return
    end

    -- decode the original address
    local ow_before_addr = (ow_before % 0x4000000)*4

    -- set up a header to handle calling our function and the original
    local header = header:format(ow_before_addr)

    local inject_bytes = {}
    local length = 0
    local function write(pos, line)
        length = length + #line/2
        dprint(("%08X"):format(pos), line)
        pos = pos % 0x80000000
        inject_bytes[pos] = tonumber(line, 16)
    end

    -- offset assembly labels so they work properly, and assemble!
    local true_offset = 0x80000000 + inject_addr
    assemble(header, write, {unsafe=true, offset=true_offset})
    assemble(asm_path, write, {unsafe=true, offset=true_offset + length})

    printf("length: %i words", length/4)
    if length > inject_maxlen then
        print("Assembly too large!")
        return
    end

    for pos, val in pairs(inject_bytes) do
        W1(pos, val)
    end
    print_deferred()

    -- finally, write our new jump over the original
    printf('%08X: %08X', ow_addr, ow_after)
    W4(ow_addr, ow_after)

    -- force code cache to be reloaded
    if bizstring then
        local ss_fn = 'inject temp.State'
        savestate.save(ss_fn)
        savestate.load(ss_fn)
    else
        m64p.reloadCode()
    end
end

if oot then
    inject('spawn oot.asm')
else
    if version == 'M JP10' or version == 'M JP11' then
        inject('spawn mm early.asm')
    else
        inject('spawn mm.asm')
    end
end
