require "boilerplate"
require "addrs.init"
require "messages"
require "classes"

local unk_only = false

local unk = ByteMonitor('unk', AL(0xF6, 0x37A))
unk.byvalue = true
unk:load('data/_unk.lua')

local link = ByteMonitor('link', AL(0,0x100C))
local ignore_fields = {
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
}

function link:ignore(i)
    for _, k in ipairs(ignore_fields) do
        local size = addrs[k].type
        if size == 'f' then size = 4 end
        local a = addrs[k].addr - self.begin
        local b = a + size
        if i >= a and i < b then return true end
    end
end

while mm do
    if unk_only then
        unk:diff()
        unk:save()
    else
        link:diff()
    end
    draw_messages()
    print_deferred()
    emu.frameadvance()
end
