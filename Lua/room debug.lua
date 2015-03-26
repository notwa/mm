local A = require "boilerplate"
local addrs = require "addrs.init"

function gs2(addr, value)
    printf("81%06X %04X", addr, value)
    W2(addr, value)
end

function dump_half_row(addr)
    printf("%04X %04X  %04X %04X", R2(addr), R2(addr+2), R2(addr+4), R2(addr+6))
end

function dump_room(start, addr)
    local addr = addr or start
    printf("start:  %06X", start)

    local object_n, objects
    local actor_n, actors

    local alt_header_list

    for _ = 1,127 do -- give up after a while
        local cmd = R1(addr)
        if cmd == 0x14 then
            local unk = R4(addr+4)
            if unk > 0 then
                -- odds are someone meant to type 0x16 instead of 0x14
                -- the game lets this slide and keeps reading
            else
                break
            end
        end

        local dumpy = function()
            local bank = R1(addr+4)
            local offset = R3(addr+5)
            if bank ~= 3 then
                printf(" in bank %i at %06X", bank, offset)
                return
            else
                local new_addr = start + offset
                printf(" at %06X (+%06X)", new_addr, offset)
                return new_addr
            end
        end

        if cmd == 0x18 then
            printf("alt:")
            alt_header_list = dumpy()
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
            --dump_half_row(addr)
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
        elseif cmd == 0x14 then
            printf("faulty end command:")
            dump_half_row(addr)
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

    print()

    if actors then
        print("# actors")
        local actor_names = require "actor names"
        local buf = ""
        for i = 0, actor_n - 1 do
            local id = R2(actors + 16*i)
            id = bit.band(id, 0x0FFF)
            local name = actor_names[id]
            buf = buf..("%04X: %s\n"):format(id, name or "unset")
        end
        print(buf)
    end

    if objects then
        print("# objects")
        local object_names = require "object names"
        local buf = ""
        for i = 0, object_n - 1 do
            local id = R2(objects + 2*i)
            local rid = bit.band(id, 0x0FFF)
            local name = object_names[rid]
            buf = buf..("%04X: %s\n"):format(id, name or "unset")
        end
        print(buf)
    end

    if alt_header_list then
        local addr = alt_header_list
        local i = 1
        while R1(addr) == 0x03 do
            printf("# setup: %02X", i)
            dump_room(start, start + R3(addr+1))
            addr = addr + 4
            i = i + 1
        end
    end
end

local last_addr
while true do
    local addr = deref(addrs.room_pointer())
    if addr and addr ~= last_addr then
        console.clear()
        print('# setup: 00')
        dump_room(addr)
        print('')
    end
    last_addr = addr

    gui.clearGraphics()

    emu.frameadvance()
end
