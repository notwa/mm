require "lib.setup"
require "boilerplate"
local a = require "addrs"

-- gimme gimme gimme

local iv
if version == "M JP10" or version == "M JP11" then
    iv = require "data.item values early"
elseif oot then
    iv = require "data.item values oot"
else
    iv = require "data.item values"
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
--set(sword_active, 1)
set(a.owl_save, 0)
set(a.sot_count, 0)

set(a.target_style, 1)
set(a.bubble_timer, 0)
set(a.chateau_romani, 8)

a.hearts        (16*20)
a.max_hearts    (16*20)
a.doubled_hearts(20)
a.magic         (0x60)
set(a.magic_max, 0x60)
a.rupees        (500)

-- nuts, sticks, bombs, wallet, Scale, gauntlets, Bullets, quiver
--                   ?????????nnnsssbbbwwSSSgggBBBqqq
a.upgrades(tonumber('00000000010101101110010011011011', 2))

if oot then
    a.tunic_boots  (0xFF) -- normally 0x77
    a.sword_shield (0xF7) -- normally 0x77?

    -- get epona
    local addr = a.event_chk_inf.addr + 2
    if bit then
        W2(addr, bit.bor(R2(addr), 0x0100))
    else
        --FIXME
    end
else
    a.sword_shield  (0x23)
    a.owls_hit      (0xFFFF)
    a.map_visible   (0xFFFF)
    a.map_visited   (0xFFFF)
    a.banked_rupees (5000)

    a.lottery_numbers[1][1](1)
    a.lottery_numbers[1][2](2)
    a.lottery_numbers[1][3](3)
    a.lottery_numbers[2][1](4)
    a.lottery_numbers[2][2](5)
    a.lottery_numbers[2][3](6)
    a.lottery_numbers[3][1](7)
    a.lottery_numbers[3][2](8)
    a.lottery_numbers[3][3](9)
    a.spider_mask_order[1](0)
    a.spider_mask_order[2](0)
    a.spider_mask_order[3](0)
    a.spider_mask_order[4](0)
    a.spider_mask_order[5](0)
    a.spider_mask_order[6](0)
    a.bombers_code[1](1)
    a.bombers_code[2](2)
    a.bombers_code[3](3)
    a.bombers_code[4](4)
    a.bombers_code[5](5)

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

    -- great spin attack
    -- this one's a bit odd; it goes off an event flag
    local addr = a.week_event_reg.addr + 23
    if bit then
        W1(addr, bit.bor(R1(addr), 0x02))
    else
        --W1(addr, R1(addr) | 0x02) -- FIXME
    end
end

set(a.magic_level, 2)
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
