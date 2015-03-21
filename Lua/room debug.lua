local A = require "boilerplate"
local addrs = require "addrs.init"

function printf(fmt, ...)
    print(fmt:format(...))
end

function gs2(addr, value)
    printf("81%06X %04X", addr, value)
    W2(addr, value)
end

function is_ptr(ptr)
    local head = bit.band(0xFF000000, ptr)
    return head == 0x80000000
end

function deref(ptr)
    return is_ptr(ptr) and ptr - 0x80000000
end

function dump_half_row(addr)
    printf("%04X %04X  %04X %04X", R2(addr), R2(addr+2), R2(addr+4), R2(addr+6))
end

function dump_room(start)
    local addr = start
    printf("start: %08X", start)

    local object_n, objects
    local actor_n, actors

    for _ = 1,128 do -- give up after a while
        local cmd = R1(addr)
        if cmd == 0x14 then break end

        local dumpy = function()
            local bank = R1(addr+4)
            local offset = R3(addr+5)
            if bank ~= 3 then
                printf(" in bank %i at %06X", bank, offset)
                return
            else
                local new_addr = start + offset
                printf(" at %08X (+%06X)", new_addr, offset)
                return new_addr
            end
        end

        if cmd == 0x18 then
            printf("alt:")
            dumpy()
        elseif cmd == 0x01 then
            actor_n = R1(addr+1)
            printf("actors:     %2i", actor_n)
            actors = dumpy()
        elseif cmd == 0x02 then
            printf("cameras:    %2i", R1(addr+1))
            dumpy()
        elseif cmd == 0x03 then
            printf("collisions:")
            dumpy()
        elseif cmd == 0x04 then
            printf("maps:       %2i", R1(addr+1))
            dumpy()
        elseif cmd == 0x06 then
            printf("entrances:")
            dumpy()
        elseif cmd == 0x08 then
            print("[room behaviour]")
            dump_half_row(addr)
        elseif cmd == 0x0A then
            printf("mesh:")
            dumpy()
        elseif cmd == 0x0B then
            object_n = R1(addr+1)
            printf("objects:    %2i", object_n)
            objects = dumpy()
        elseif cmd == 0x0D then
            printf("pathways:   %2i", R1(addr+1))
            dumpy()
        elseif cmd == 0x10 then
            print("[time]")
        elseif cmd == 0x12 then
            print("[skybox]")
        elseif cmd == 0x13 then
            printf("exits:")
            dumpy()
        elseif cmd == 0x16 then
            printf("echo:       %2i", R1(addr+7))
        elseif cmd == 0x17 then
            printf("cutscenes:  %2i", R1(addr+1))
            dumpy()
        else
            dump_half_row(addr)
        end

        addr = addr + 8
    end

    --[[
    local obj_i = 0
    local act_i = 1
    if objects and object_n > obj_i and actors and actor_n > act_i then
        gs2(objects + 2*obj_i, 0x00FC)
        gs2(actors + 16*act_i+0x0, 0x00A8)
        gs2(actors + 16*act_i+0xE, 0x0010)
    end
    --]]
    if objects and actors then
        for i = 0, object_n - 1 do
            --printf('O: %04X', R2(objects + 2*i))
            --gs2(objects+2*i, 0x00FC)
            
        end
        for i = 0, actor_n - 1 do
            --print('A:')
            --dump_half_row(actors+16*i+0)
            --dump_half_row(actors+16*i+8)
            --gs2(actors+16*i+0x0, 0x00A8)
            --gs2(actors+16*i+0xE, 0x0010)
        end
    end
end

local last_addr
while true do
    local addr = deref(addrs.room_ptr())
    if addr and addr ~= last_addr then
        print('# new room loaded #')
        dump_room(addr)
        print('')
    end
    last_addr = addr

    gui.clearGraphics()

    emu.yield()
end
