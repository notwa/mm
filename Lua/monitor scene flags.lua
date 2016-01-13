require "lib.setup"
require "boilerplate"
require "addrs"
require "classes"
require "messages"

local x1 = SceneFlagMonitor('x1', addrs.current_scene_flags_1)
local x2 = SceneFlagMonitor('x2', addrs.current_scene_flags_2)
local x3 = SceneFlagMonitor('x3', addrs.current_scene_flags_3)
local x4 = SceneFlagMonitor('x4', addrs.current_scene_flags_4)
local x5 = SceneFlagMonitor('x5', addrs.current_scene_flags_5)
local scenes = {}
local n1 = -1
while mm or oot do
    local n = addrs.scene_number()
    if n ~= n1 then
        if not scenes[n] then
            scenes[n] = {}
            printf('new scene %04X',n)--already has {TODO} flags', n)
        end
        if not scenes[n1] then
            scenes[n1] = {}
        end

        scenes[n1][1] = x1.old_bytes
        scenes[n1][2] = x2.old_bytes
        scenes[n1][3] = x3.old_bytes
        scenes[n1][4] = x4.old_bytes
        scenes[n1][5] = x5.old_bytes
        x1.old_bytes = scenes[n][1] or {}
        x2.old_bytes = scenes[n][2] or {}
        x3.old_bytes = scenes[n][3] or {}
        x4.old_bytes = scenes[n][4] or {}
        x5.old_bytes = scenes[n][5] or {}
    end
    n1 = n

    x1:diff()
    x2:diff()
    x3:diff()
    x4:diff()
    x5:diff()
    draw_messages()
    emu.frameadvance()
end
