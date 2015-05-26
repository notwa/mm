require = require "depend"
require "boilerplate"
require "addrs.init"
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
    "exit_value",
    "mask_worn",
    "cutscene_status",
    "time",
    "transformation",
    "hearts",
    "magic",
    "rupees",
    "navi_timer",
    "scene_flags_save",
    "week_event_reg",
    "event_inf",
    "inventory_items",
    "inventory_masks",
    "inventory_quantities",
} or {
    "exit_value",
    "cutscene_status",
    "time",
    "hearts",
    "magic",
    "rupees",
    "navi_timer",
    "scene_flags_save",
    "inventory_items",
    "inventory_quantities",
    "event_chk_inf",
    "item_get_inf",
    "inf_table",
    "event_inf",
}

function link:ignore(i)
    for _, k in ipairs(ignore_fields) do
        local v = addrs[k]
        if not v then
            error('unknown addr: '..tostring(k), 1)
        end
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
