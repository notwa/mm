require "lib.setup"
require "boilerplate"
local a = require "addrs"
local inv = a.inventory
local masks = a.masks
local quantities = a.quantities

local iv
if version == "M JP10" or version == "M JP11" then
    iv = require "data.item values early"
elseif oot then
    iv = require "data.item values oot"
else
    iv = require "data.item values"
end

require "flag manager"

-- TODO: just force a song of time cutscene to reset most things

for i=a.link.addr, a.link.addr + a.link.type - 1, 4 do
    W4(i, 0)
end

a.exit_value(0xD800)
--a.mask_worn(0)
a.intro_completed(1)
a.time(0x3FFF)
--a.owl_id(0)
--a.day_night(0)
--a.time_speed(0)
--a.day(0)
--a.days_elapsed(0)
a.transformation(4)
a.have_tatl(1)
--a.owl_save(0)
a.sot_count(2)
a.max_hearts(0x30)
a.hearts(0x30)
a.magic_level(1)
a.magic(0x30)
a.magic_max(0x30)
--a.rupees(0)
a.has_normal_magic(1)
--a.has_double_magic(0)
--a.owls_hit(0)
for k, f in pairs(inv) do f(-1) end
for k, f in pairs(masks) do f(-1) end
inv.b_button_item(0x4D) -- TODO: add to item values table
inv.b_button_goron(0x4D)
inv.b_button_zora(0x4D)
inv.b_button_deku(iv.deku_nuts)
inv.c_left_item(iv.ocarina)
inv.c_down_item(-1)
inv.c_right_item(-1)
inv.c_left_slot(iv.ocarina)
inv.c_down_slot(-1)
inv.c_right_slot(-1)
--a.tunic_boots(0)
a.sword_shield(0x11)
inv.ocarina(iv.ocarina)
masks.deku(iv.deku)
--for k, f in pairs(quantities) do f(0) end
a.upgrades(0x00120000) -- deku nut 20 and deku stick 10
a.quest_items(0x10003000)
AL(0x3D7, 5) -- unknown
scene_flag_set(9, 0, 10)
scene_flag_set(94, 2, 0)
scene_flag_set(111, 4, 10)
AL(0xE6C, 0x1D4C) -- unknown
AL(0xE70, 0x1D4C) -- unknown
AL(0xE74, 0x1DB0) -- unknown
AL(0xEE8, 0x0013000A) -- unknown
AL(0xEEC, 0x1770) -- unknown
AL(0xEF4, 0x000A0027) -- unknown
event_flag_set(2, 5)
event_flag_set(2, 4)
event_flag_set(2, 3)
event_flag_set(31, 2)
event_flag_set(59, 2)
event_flag_set(92, 7)
a.map_visited(0x20)
a.map_visible(0x00)
a.bombers_code[1](1)
a.bombers_code[2](2)
a.bombers_code[3](3)
a.bombers_code[4](4)
a.bombers_code[5](5)
a.spider_mask_order[1](0) -- red
a.spider_mask_order[2](1) -- blue
a.spider_mask_order[3](0) -- red
a.spider_mask_order[4](1) -- blue
a.spider_mask_order[5](0) -- red
a.spider_mask_order[6](1) -- blue
a.lottery_numbers[1][1](1)
a.lottery_numbers[1][2](2)
a.lottery_numbers[1][3](3)
a.lottery_numbers[2][1](4)
a.lottery_numbers[2][2](5)
a.lottery_numbers[2][3](6)
a.lottery_numbers[3][1](7)
a.lottery_numbers[3][2](8)
a.lottery_numbers[3][3](9)
a.epona_scene(53)
a.epona_x(-1420)
a.epona_y(257)
a.epona_z(-1285)
a.epona_angle(10922)
