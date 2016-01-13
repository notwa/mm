-- movement speed testing
-- for Majora's Mask:
--   go to the fairy's fountain in clock town as human link and run this script.
-- for Ocarina of Time:
--   go to the Temple of Time as a child and run this script.

require "setup.lib"
require "addrs"

local length = 70 -- in frames
local print_each = true

local tests = {
    optimal_roll = {
        [ 1]={        Y=127},
        [ 2]={Z=true, Y=127, A=true},
        [17]={Z=true, Y=127},
        [18]={Z=true, Y=127, A=true},
        [33]={goto=17},
    },

    mash_roll = {
        [ 1]={        Y=127},
        [ 2]={Z=true, Y=127, A=true},
        [13]={Z=true, Y=127},
        [14]={Z=true, Y=127, A=true},
        [25]={goto=13},
    },

    sidehop = {
        [ 1]={        X=127},
        [ 2]={Z=true},
        [ 8]={Z=true, X=-127, A=true},
        [ 9]={Z=true, X=-127},
        [15]={goto=8},
    },

    quick_turnaround = {
        [1]={Z=true},
        [2]={},
        [5]={        Y=-127},
        [6]={Z=true, Y=-127},
    },

    backwalk = {
        [1]={        Y=-127},
        [2]={Z=true},
        [8]={Z=true, Y=-127},
    },

    walk = {
        [1]={Y=127},
    },

    inverse_backwalk = {
        [1]={Z=true, Y=127},
        [4]={},
        [7]={        Y=-127},
        [8]={Z=true, Y=127},
    },
}

local link = addrs.link_actor

local pos = mm and {2400, 20, 375} or {-200, -40, 2330}
local angle = 180

local fn = 'data/lua movement test.State'

function pythag(x, y)
    return math.sqrt(x*x + y*y)
end

function reset_stick()
    joypad.setanalog({["X Axis"]=false, ["Y Axis"]=false}, 1)
end

function find_displacement()
    local x = link.x()
    local y = link.z() -- FIXME
    return pythag(pos[1] - x, pos[2] - y)
end

function setup()
    client.unpause()
    for _=1, 2 do
        reset_stick()
        local angle = (angle/360*65536) % 65536
        --link.angle_old(angle_old)
        link.angle(angle)
        link.x(pos[1])
        link.y(pos[2])
        link.z(pos[3])
        link.x_copy(pos[1])
        link.y_copy(pos[2])
        link.z_copy(pos[3])
        for i=1, 3*21 do
            emu.frameadvance()
            joypad.set({A=i % 4 > 0, Z=i > 9 and i <= 12}, 1)
        end
    end
    savestate.save(fn)
end

function reload()
    savestate.load(fn)
end

function finish()
    reset_stick()
    client.pause()
end

function preprocess(inputs)
    for f, j in pairs(inputs) do
        if type(f) == 'number' then
            j['Start'] = j['S']
            j['C Down']  = j['CD']
            j['C Left']  = j['CL']
            j['C Right'] = j['CR']
            j['C Up']    = j['CU']
            j['X Axis'] = j['X']
            j['Y Axis'] = j['Y']
        end
    end
end

function test_inputs(name, inputs, length)
    preprocess(inputs)
    reload()
    local to = length or inputs.length
    local frame = 0
    local latest, action
    for _=1, to do
        frame = frame + 1
        for _=1, 10 do -- limit number of goto's to follow
            latest = 0
            action = nil
            for f, j in pairs(inputs) do
                if type(f) == 'number' and frame >= f and f > latest then
                    latest = f
                    action = j
                end
            end
            if action == nil or type(action.goto) ~= 'number' then
                break
            else
                frame = action.goto
            end
        end
        if action ~= nil then
            for _=1, 3 do
                joypad.setanalog(action, 1)
                joypad.set(action, 1)
                emu.frameadvance()
            end
        end
        reset_stick()
    end
    return x
end

function run_tests(length)
    setup()

    local fmt = '%20s: %10.5f'
    local spd_fmt = '%20.5f units/frame'
    print('# testing')

    if tests['testme'] ~= nil then
        local key = 'testme'
        local x = test_inputs(key, tests[key], length)
        local distance = find_displacement()
        print(fmt:format(key, distance))
        print(spd_fmt:format(distance/length))
    else
        local furthest = nil
        local distance = 0
        for k, v in pairs(tests) do
            local x = test_inputs(k, v, length)
            local new_distance = find_displacement()
            if print_each then
                print(fmt:format(k, new_distance))
            end
            if new_distance > distance then
                furthest = k
                distance = new_distance
            end
        end
        if furthest ~= nil then
            print()
            print(('## and the winner for %i frames is...'):format(length))
            print(fmt:format(furthest, distance))
            print(spd_fmt:format(distance/length))
        end
    end
    print()
    finish()
end

run_tests(length)
