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
    ['O EUDB MQ'] = {
        inject_addr = 0x700000,
        inject_maxlen = 0x100000,
        ow_addr = 0x0C6940,
        ow_before = 0x0C03151F,
    },
}
injection_points['O JP10'] = injection_points['O US10']

local hook = [[
[hooked]: 0x%08X
    // note: this will fail when the hooked function takes args on stack
    sw      ra, -4(sp)
    sw      a0,  0(sp)
    sw      a1,  4(sp)
    sw      a2,  8(sp)
    sw      a3, 12(sp)
    bal     start
    subi    sp, sp, 20
    lw      ra, 16(sp)
    lw      a0, 20(sp)
    lw      a1, 24(sp)
    lw      a2, 28(sp)
    lw      a3, 32(sp)
    j       @hooked
    addi    sp, sp, 20
start:
]]

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

    local inject_end = inject_addr + inject_maxlen

    -- encode our jal instruction
    local ow_after = 0x0C000000 + math.floor(inject_addr/4)
    if R4(ow_addr) ~= ow_before and R4(ow_addr) ~= ow_after then
        print("Can't inject -- game code is different!")
        return
    end

    -- decode the original address
    local ow_before_addr = (ow_before % 0x4000000)*4

    -- set up a hook to handle calling our function and the original
    local hook = hook:format(ow_before_addr)

    local inject_bytes = {}
    local size = 0
    local cons_pos = inject_addr
    local function write(pos, line)
        assert(#line == 2, "that ain't const")
        dprint(("%08X"):format(pos), line)
        pos = pos % 0x80000000
        size = size + 1
        if pos > cons_pos and (pos < inject_end or cons_pos == pos - 1) then
            cons_pos = pos
        end
        inject_bytes[pos] = tonumber(line, 16)
    end

    -- offset assembly labels so they work properly, and assemble!
    local true_offset = 0x80000000 + inject_addr
    assemble(hook, write, {unsafe=true, offset=true_offset})
    assemble(asm_path, write, {unsafe=true, offset=true_offset + size})

    print_deferred()
    printf("size: %i words", size/4)
    if cons_pos >= inject_end then
        print("Assembly too large!")
        print("The game will probably crash.")
    end

    for pos, val in pairs(inject_bytes) do
        W1(pos, val)
    end

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

local asms = {
    ['O US10'] = 'spawn oot.asm',
    ['O JP10'] = 'spawn oot.asm',
    ['O EUDB MQ'] = 'print.asm',

    ['M US10'] = 'spawn mm.asm',
    ['M JP10'] = 'spawn mm early.asm',
}

local asm = asms[version]
if asm then
    inject(asm)
else
    print('no appropriate assembly found for this game')
end
