require "lib.setup"
require "boilerplate"
local a = require "addrs"
local inv = a.inventory
local masks = a.masks
local quantities = a.quantities

if not mm then return end
local early = version == "M JP10" or version == "M JP11"

local zelda3 = "ZELDA3"
-- TODO: support (E) text format too
local link_str = {0x15, 0x12, 0x17, 0x14, 0x3E, 0x3E, 0x3E, 0x3E}
local lastsaveslot = 1
local iv
if early then
    link_str = {0xB6, 0xB3, 0xB8, 0xB5, 0xDF, 0xDF, 0xDF, 0xDF}
    lastsaveslot = 2
    iv = require "data.item values early"
else
    iv = require "data.item values"
end

require "flag manager"

for i = a.link.addr, a.link.addr + a.link.type - 1, 4 do W4(i, 0) end

if a.current_save() == 0xFF then a.current_save(lastsaveslot) end

for i = 1, 6 do W1(a.ZELDA3.addr + i - 1, zelda3:sub(i, i):byte()) end
AL(0x50, 4)(0x6CFFFFFF) -- goron C/B buttons
AL(0x54, 4)(0x6CFFFFFF) -- zora C/B buttons
AL(0x58, 4)(0x09FFFFFF) -- deku C/B buttons
AL(0x60, 4)(0xFFFFFFFF) -- unknown
AL(0x64, 4)(0xFFFFFFFF) -- unknown
AL(0x68, 4)(0xFFFFFFFF) -- unknown

-- TODO: support (E) text format too
if early then
    for i = 0, 7 do W1(a.name.addr + i, 0xDF) end
    W1(a.name.addr, 0)
else
    for i = 0, 7 do W1(a.name.addr + i, 0x3E) end
    W1(a.name.addr, 0)
end

a.warp_begin(1)
a.warp_destination(0xD800)
a.cutscene_status_2(3)
a.target_style(1)
--a.fade_timer(0x3C) -- doesn't help...
-- TODO: force dialog after scene is loaded with SoT stored? could be nice

for i = 1, 8 do W1(a.link.addr + 0xDE + i - 1, link_str[i]) end
for i = 1, 8 do W1(a.link.addr + 0xE6 + i - 1, link_str[i]) end
for i = 1, 8 do W1(a.link.addr + 0xEE + i - 1, link_str[i]) end

AL(0xD2, 1)(0xFF) -- unused key counter

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
a.sot_count(1)
a.max_hearts(0x30)
a.hearts(0x30)
a.magic_level(1)
a.magic(0x30)
a.magic_max(0x30)
--a.rupees(0)
a.has_normal_magic(1)
--a.has_double_magic(0)
AL(0x44, 2)(0xFF00) -- unknown
--a.owls_hit(0)
AL(0x48, 2)(0xFF00) -- unknown
AL(0x4A, 2)(0x0008) -- unknown
for k, f in pairs(inv) do f(-1) end
for k, f in pairs(masks) do f(-1) end
inv.b_button_item(iv.kokiri_sword)
inv.b_button_goron(iv.kokiri_sword)
inv.b_button_zora(iv.kokiri_sword)
inv.b_button_deku(iv.deku_nut)
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
a.banked_rupees(101)
AL(0xE6C, 4)(0x1D4C) -- unknown
AL(0xE70, 4)(0x1D4C) -- unknown
AL(0xE74, 4)(0x1DB0) -- unknown
AL(0xEE8, 4)(0x0013000A) -- unknown
AL(0xEEC, 4)(0x1770) -- unknown
AL(0xEF4, 4)(0x000A0027) -- unknown
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
a.epona_angle(10922) -- should actually be 35500? maybe?

local scene_count = 0x78

-- wipe all scene flags.
for scene_id = 0, scene_count - 1 do
    local temp = a.scene_flags_ingame.addr + 0x14 * scene_id
    W4(temp + 0, 0)
    W4(temp + 1, 0)
    W4(temp + 2, 0)
    W4(temp + 3, 0)
    W4(temp + 4, 0)
end

-- 0x1EFA44 should be 0x00000005
scene_flag_set(26, 1, 0)
scene_flag_set(26, 1, 2)
-- 0x1EFB94 should be 0x00000400
scene_flag_set(38, 1, 10)
-- 0x1F0240 should be 0x00000001
scene_flag_set(99, 1, 0)
-- 0x1F039C should be 0x00000400
scene_flag_set(111, 4, 10)

local src = a.scene_flags_ingame.addr
local dst = a.scene_flags_save.addr
for scene_id = 0, scene_count - 1 do
    local src_temp = src + scene_id * 0x14
    local dst_temp = dst + scene_id * 0x1C
    W4(dst_temp + 0, R4(src_temp + 0))
    W4(dst_temp + 4, R4(src_temp + 4))
    W4(dst_temp + 8, R4(src_temp + 8))
    W4(dst_temp + 12, R4(src_temp + 12))
    W4(dst_temp + 16, R4(src_temp + 16))
    W4(dst_temp + 20, 0)
    W4(dst_temp + 24, 0)
end
