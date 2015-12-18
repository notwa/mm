require = require "depend"
require "boilerplate"
require "addrs.init"
local assemble = require "inject.lips"

function inject(fn)
    local asm_dir = bizstring and 'inject/' or './mm/Lua/inject/'
    local asm_path = asm_dir..fn

    local inject_addr -- seemingly unused region of memory
    local inject_maxlen -- how much room we have to work with
    local ow_addr -- the jal instruction to overwrite with our hook
    local ow_before -- what its value is normally supposed to be
    if version == 'M US10' then
        inject_addr = 0x780000
        inject_maxlen = 0x5A800
        ow_addr = 0x1749D0
        ow_before = 0x0C05CEC6
    else
        print("Sorry, inject.lua is unimplemented for your game version.")
        return
    end

    -- encode our jal instruction
    local ow_after = 0x0C000000 + math.floor(inject_addr/4)
    if R4(ow_addr) ~= ow_before and R4(ow_addr) ~= ow_after then
        print("Can't inject -- game code is different!")
        return
    end

    -- decode the original address
    local ow_before_addr = (ow_before % 0x4000000)*4

    -- set up a header to handle calling our function and the original
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

    local inject_words = {}
    local length = 0
    local function add_word(line)
        -- takes assembled code, up to 4 bytes at a time, as hex strings
        length = length + #line/2
        table.insert(inject_words, tonumber(line, 16))
    end

    -- offset assembly labels so they work properly, and assemble!
    local true_offset = 0x80000000 + inject_addr
    assemble(header, add_word, {unsafe=true, offset=true_offset})
    assemble(asm_path, add_word, {unsafe=true, offset=true_offset + length})

    printf("length: %i words", length/4)
    if #inject_words > inject_maxlen then
        print("Assembly too large!")
        return
    end

    for i, v in ipairs(inject_words) do
        W4(inject_addr + (i - 1)*4, v)
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

inject('spawn.asm')
