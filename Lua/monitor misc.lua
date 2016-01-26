require "lib.setup"
require "boilerplate"
require "addrs"
require "messages"
require "classes"

-- no effect on OoT
local unk_only = false

local unk = ByteMonitor('unk', AL(0xF6, 0x37A))
unk.byvalue = true
unk:load('data/_unk.lua')

local size = addrs.checksum.addr - addrs.exit_value.addr + 4
local link = ByteMonitor('link', AL(0, size))
local ignore_fields = mm and {
    addrs.exit_value,
    addrs.mask_worn,
    addrs.intro_completed,
    addrs.anti_mash_timer,
    addrs.cutscene_status,
    addrs.time,
    addrs.owl_id,
    addrs.day_night,
    addrs.time_speed,
    addrs.day,
    addrs.days_elapsed,
    addrs.transformation,
    addrs.have_tatl,
    addrs.owl_save,
    addrs.ZELDA3,
    addrs.sot_count,
    addrs.name,
    addrs.max_hearts,
    addrs.hearts,
    addrs.magic_level,
    addrs.magic,
    addrs.rupees,
    addrs.navi_timer,
    addrs.has_normal_magic,
    addrs.has_double_magic,
    addrs.owls_hit,
--  addrs.tunic_boots,
    addrs.sword_shield,
    addrs.inventory_items,
    addrs.inventory_masks,
    addrs.inventory_quantities,
    addrs.upgrades,
    addrs.quest_items,
    addrs.items_wft,
    addrs.items_sht,
    addrs.items_gbt,
    addrs.items_stt,
    addrs.keys_wft,
    addrs.keys_sht,
    addrs.keys_gbt,
    addrs.keys_stt,
    addrs.doubled_hearts,
    addrs.fairies_wft,
    addrs.fairies_sht,
    addrs.fairies_gbt,
    addrs.fairies_stt,
--  addrs.strange_string,

    addrs.inventory.b_button_item,
    addrs.inventory.c_left_item,
    addrs.inventory.c_down_item,
    addrs.inventory.c_right_item,
    addrs.inventory.c_left_slot,
    addrs.inventory.c_down_slot,
    addrs.inventory.c_right_slot,
    addrs.scene_flags_save,
    addrs.scene_flags_ingame,
    addrs.week_event_reg,
    addrs.event_inf,
} or {
    addrs.exit_value,
    addrs.cutscene_status,
    addrs.time,
    addrs.hearts,
    addrs.magic,
    addrs.rupees,
    addrs.navi_timer,
    addrs.scene_flags_save,
    addrs.inventory_items,
    addrs.inventory_quantities,
    addrs.event_chk_inf,
    addrs.item_get_inf,
    addrs.inf_table,
    addrs.event_inf,
}

function link:ignore(i)
    for _, v in pairs(ignore_fields) do
        local size = v.type
        if size == 'f' then size = 4 end
        local a = v.addr - self.begin
        if i >= a and i < a + size then return true end
    end
end

while mm or oot do
    if mm and unk_only then
        unk:diff()
        unk:save()
    else
        link:diff()
    end
    draw_messages()
    print_deferred()
    emu.frameadvance()
end
