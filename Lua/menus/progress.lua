local a = addrs
local inv = a.inventory
local masks = a.masks
local quantities = a.quantities

local function set(f, v)
    -- for addresses that *might* be undefined
    if f then f(v) end
end

local iv
if version == "M JP10" or version == "M JP11" then
    iv = require "data.item values early"
elseif oot then
    iv = require "data.item values oot"
else
    iv = require "data.item values"
end

local function first_cycle()
    a.warp_begin(0x14)
    a.warp_destination(0xC000)
    a.transformation(3) -- deku
    a.day(0)
    a.days_elapsed(0)
    a.time(0x3FD2) -- default time
    a.day_night(1)
    a.time_speed(0)
    a.intro_completed(0)
    a.have_tatl(1)
    a.sot_count(0)
    -- remove ocarina so time passes at first-cycle speed, among other things.
    -- if really you need your ocarina, just put it on a C button beforehand.
    a.inventory.ocarina(0xFF)

    -- happy mask salesman talking at door
    scene_flag_reset(0x63, 1, 0)
    -- bombers ladder balloon
    scene_flag_reset(0x29, 1, 1)

    -- other things to consider resetting:
    -- skull kid stuff
    -- deed trading quest entirely
    -- bombers stuff (they don't let you do it twice)
    -- ability to learn song of healing + get deku mask <--
    -- "oh no! the great fairy!"

    -- moon's tear has landed
    event_flag_reset(74, 5)
    event_flag_reset(74, 7)
    -- moon's tear acquired
    event_flag_reset(74, 6)
    -- skullkid jumped off clock tower thru telescope
    event_flag_reset(12, 2)
    -- clock town fairy acquired
    event_flag_reset(8, 7)
    -- deku merchant has landed)
    event_flag_reset(73, 2)
    -- Talked to Town Scrub once as Deku
    event_flag_reset(86, 2)
    -- similar to above?
    event_flag_reset(17, 5)
    -- Obtained Land Title Deed
    event_flag_reset(17, 7)
    -- Tatl talks about clock tower entrance
    event_flag_reset(79, 4)
    -- Clock Tower is open?
    event_flag_reset( 8, 6)
    -- Tatl telling Link to hurry at Clock Tower
    event_flag_reset(88, 5)
end

local function all_items()
    for k, f in pairs(inv) do
        if iv[k] then f(iv[k]) end
    end

    if iv.longshot then
        inv.hookshot(iv.longshot)
    end
end

local function all_bottles()
    inv.bottle_1        (iv.bottle        )
    inv.bottle_2        (iv.fairy         )
    inv.bottle_3        (iv.bugs          )
    inv.bottle_4        (iv.fish          )
    set(inv.bottle_5,    iv.milk          )
    set(inv.bottle_6,    iv.chateau_romani)
end

local function all_masks()
    for k, f in pairs(masks) do
        f(iv[k])
    end
end

local function max_hearts()
    a.hearts        (16*20)
    a.max_hearts    (16*20)
    a.doubled_hearts(20)
    -- TODO: set heart pieces to 0
end

local function max_magic()
    a.magic         (0x60)
    set(a.magic_max, 0x60)
    set(a.chateau_romani, 8)
    set(a.magic_level, 2)
    set(a.has_normal_magic, 1)
    set(a.has_double_magic, 1)
    if mm then
        -- great spin attack
        -- this one's a bit odd; it goes off an event flag
        local addr = a.week_event_reg.addr + 23
        W1(addr, bit.bor(R1(addr), 0x02))
    end
end

local function max_rupees()
    a.rupees(500)
    set(a.banked_rupees, 5000)
end

local function all_upgrades()
    -- nuts, sticks, bullets, wallet, Scale, gauntlets, Bombs, quiver (verify?)
    --                   ?????????nnnsssbbbwwSSSgggBBBqqq
    a.upgrades(tonumber('00000000010101101110010011011011', 2))
end

local function all_dungeon()
    if oot then
        -- TODO
    else
        a.items_wft(7)
        a.items_sht(7)
        a.items_gbt(7)
        a.items_stt(7)
        a.keys_wft(9)
        a.keys_sht(9)
        a.keys_gbt(9)
        a.keys_stt(9)
        a.fairies_wft(20)
        a.fairies_sht(20)
        a.fairies_gbt(20)
        a.fairies_stt(20)
        a.slulltula_count_wf(20)
        a.slulltula_count_gb(20)
    end
end

local function all_map()
    if oot then
        -- TODO
    else
        a.owls_hit      (0xFFFF)
        a.map_visible   (0xFFFF)
        a.map_visited   (0xFFFF)
    end
end

local function max_quantity()
    -- TODO: check upgrade flags for actual maximums
    for k, f in pairs(quantities) do
        f(69)
    end
end

local function all_quest()
    a.quest_items(0x00FFFFFF)
end

local function all_equips()
    if oot then
        a.tunic_boots (0xFF) -- normally 0x77
        a.sword_shield(0xF7) -- normally 0x77?
    else
        a.sword_shield(0x23)
    end
end

local function all_notebook()
    for i=66,72 do
        W1(a.week_event_reg.addr + i, 0xFF)
    end
end

return oot and Menu{
    Screen{
        -- cheaty stuff
        Text("Progress Menu #1/2"),
        Oneshot("All Items", all_items),
        Oneshot("Max Quantities", max_quantity),
        Oneshot("All Bottles", all_bottles),
        Oneshot("All Equipment", all_equips),
        Oneshot("Max Hearts", max_hearts),
        Oneshot("Max Magic", max_magic),
        Oneshot("Max Rupees", max_rupees),
        Oneshot("All Upgrades", all_upgrades),
        Oneshot("All Dungeon Items", all_dungeon),
        Oneshot("Complete Map", all_map),
        Oneshot("All Songs", all_quest), -- TODO
        Oneshot("All Medallions", all_quest), -- TODO
        Text(""),
        Back(),
    },
    Screen{
        -- not so cheaty
        Text("Progress Menu #2/2"),
        Oneshot("Z Targeting: Switch", Setter{[a.target_style]=0}),
        Oneshot("Z Targeting: Hold",   Setter{[a.target_style]=1}),
        Text(""),
        Oneshot("Reset Death Count", Setter{[a.death_count]=0}),
        Text(""),
        Back(),
    },
} or Menu{
    Screen{
        -- cheaty stuff
        Text("Progress Menu #1/2"),
        Oneshot("All Items", all_items),
        Oneshot("Max Quantities", max_quantity),
        Oneshot("All Bottles", all_bottles),
        Oneshot("All Masks", all_masks),
        Oneshot("All Equipment", all_equips),
        Oneshot("Max Hearts", max_hearts),
        Oneshot("Max Magic", max_magic),
        Oneshot("Max Rupees", max_rupees),
        Oneshot("All Upgrades", all_upgrades),
        Oneshot("All Dungeon Items", all_dungeon),
        Oneshot("Complete Map", all_map),
        Oneshot("All Songs", all_quest), -- TODO
        Oneshot("All Remains", all_quest), -- TODO
        Oneshot("Complete Notebook", all_notebook),
        Text(""),
        Back(),
    },
    Screen{
        -- not so cheaty
        Text("Progress Menu #2/2"),
        Oneshot("Z Targeting: Switch", Setter{[a.target_style]=0}),
        Oneshot("Z Targeting: Hold",   Setter{[a.target_style]=1}),
        Text(""),
        Oneshot("Setup First Cycle", first_cycle),
        Oneshot("Setup Race File", Setter{[dofile]="race.lua"}),
        Text(""),
        Oneshot("Set Bombers Code to 12345", Setter{
            [a.bombers_code[1]]=1,
            [a.bombers_code[2]]=2,
            [a.bombers_code[3]]=3,
            [a.bombers_code[4]]=4,
            [a.bombers_code[5]]=5,
        }),
        Oneshot("Set Spider Mask Puzzle to All Red", Setter{
            [a.spider_mask_order[1]]=0,
            [a.spider_mask_order[2]]=0,
            [a.spider_mask_order[3]]=0,
            [a.spider_mask_order[4]]=0,
            [a.spider_mask_order[5]]=0,
            [a.spider_mask_order[6]]=0,
        }),
        Oneshot("Set Lottery Numbers to 123,456,789", Setter{
            [a.lottery_numbers[1]]=0x010203,
            [a.lottery_numbers[2]]=0x040506,
            [a.lottery_numbers[3]]=0x070809,
        }),
        Text(""),
        Oneshot("Enable Owl Save",  Setter{[a.owl_save]=1}),
        Oneshot("Disable Owl Save", Setter{[a.owl_save]=0}),
        Oneshot("Reset Song of Time Count", Setter{[a.sot_count]=0}),
        Text(""),
        Back(),
    },
}
