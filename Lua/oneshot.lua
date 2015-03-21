-- gimme gimme gimme
local a = require "addrs.init"
require "item values"

local iv
if version == "M JP10" or version == "M JP11" then
    iv = require "item values early"
elseif oot then
    iv = require "item values oot"
else
    iv = require "item values"
end

local inv = a.inventory
local masks = a.masks
local quantities = a.quantities

local function set(f, v)
    -- wrapper for addresses that *might* be undefined
    if f then f(v) end
end

set(a.target_style, 1)

--set(buttons_enabled, 0)
--set(infinite_sword, 1)
set(a.owl_save, 1)
set(a.sot_count, 0)

set(a.target_style, 1)
set(a.bubble_timer, 0)
set(a.chateau_romani, 8)

a.hearts        (16*20)
a.max_hearts    (16*20)
a.doubled_hearts(20)
a.magic         (0x60)
a.rupees        (500)

if oot then
    a.tunic_boots  (0xFF) -- normally 0x77
    a.sword_shield (0xF7) -- normally 0x77?
    a.upgrades     (0x36E458) -- normally ?
    a.quest_items  (0x00FFFFFF)

else
    a.sword_shield  (0x23)
    a.quiver_bag    (0x1B)
    a.owls_hit      (0xFFFF)
    a.map_visible   (0xFFFF)
    a.map_visited   (0xFFFF)
    a.wallet_size   (32)
    a.banked_rupees (9999)

    a.lottery_code_1(1*10000 + 2*0x100 + 3)
    a.lottery_code_2(4*10000 + 5*0x100 + 6)
    a.lottery_code_3(7*10000 + 8*0x100 + 9)
    a.spider_mask_color_1(0)
    a.spider_mask_color_2(0)
    a.spider_mask_color_3(0)
    a.spider_mask_color_4(0)
    a.spider_mask_color_5(0)
    a.bombers_code_1(1)
    a.bombers_code_2(2)
    a.bombers_code_3(3)
    a.bombers_code_4(4)
    a.bombers_code_5(5)

    a.items_wft(7)
    a.items_sht(7)
    a.items_gbt(7)
    a.items_stt(7)
    a.keys_wft(69)
    a.keys_sht(69)
    a.keys_gbt(69)
    a.keys_stt(69)
    a.fairies_wft(69)
    a.fairies_sht(69)
    a.fairies_gbt(69)
    a.fairies_stt(69)
end

set(a.has_magic, 1)
set(a.has_normal_magic, 1)
set(a.has_double_magic, 1)
a.quest_items   (0x00FFFFFF)

--a.slulltula_count_wf(69)
--a.slulltula_count_gb(69)

--inv.b_button        (0x4F) -- don't really need this

for k, f in pairs(inv) do
    if iv[k] then f(iv[k]) end
end

if iv.longshot then
    inv.hookshot(iv.longshot)
end

inv.bottle_1        (iv.bottle        )
inv.bottle_2        (iv.fairy         )
inv.bottle_3        (iv.bugs          )
inv.bottle_4        (iv.fish          )
set(inv.bottle_5,    iv.milk          )
set(inv.bottle_6,    iv.chateau_romani)

--set(a.event_1, 0x05)
--set(a.event_2, 0x0B)
--set(a.event_3, 0x11)

if masks then
    for k, f in pairs(masks) do
        f(iv[k])
    end
end

for k, f in pairs(quantities) do
    f(69)
end
