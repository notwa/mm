require "lib.setup"
require "boilerplate"
require "addrs"
require "messages"
require "classes"

local mm_ignore = {
    -- TODO: use list of bytes/bits rather than full strings
    -- every time a scene (un)loads
    ['92,7=0 (weg)'] = true,
    ['92,7=1 (weg)'] = true,
    -- night transition available
    ['05,2=0 (inf)'] = true,
    ['05,2=1 (inf)'] = true,
    -- daily postman crap
    ['27,6=0 (weg)'] = true,
    ['27,7=0 (weg)'] = true,
    ['28,0=0 (weg)'] = true,
    ['28,1=0 (weg)'] = true,
    ['28,2=0 (weg)'] = true,
    ['27,6=1 (weg)'] = true,
    ['27,7=1 (weg)'] = true,
    ['28,0=1 (weg)'] = true,
    ['28,1=1 (weg)'] = true,
    ['28,2=1 (weg)'] = true,
}

local weg,inf,eci,igi,it_,ei_
local fms
if mm then
    weg = FlagMonitor('weg', addrs.week_event_reg, mm_ignore)
    inf = FlagMonitor('inf', addrs.event_inf, mm_ignore)
    --mmb = FlagMonitor('mmb', addrs.mask_mask_bit) -- 100% known, no point
    weg:load('data/_weg.lua')
    inf:load('data/_inf.lua')
    fms = {weg, inf}
elseif oot then
    eci = FlagMonitor('eci', addrs.event_chk_inf)
    igi = FlagMonitor('igi', addrs.item_get_inf)
    it_ = FlagMonitor('it ', addrs.inf_table)
    ei_ = FlagMonitor('ei ', addrs.event_inf)
    eci:load('data/_eci.lua')
    igi:load('data/_igi.lua')
    it_:load('data/_it.lua')
    ei_:load('data/_ei.lua')
    fms = {eci, igi, it_, ei_}
    for i, fm in ipairs(fms) do fm.oot = true end
end

local function ef_wipe()
    for _, fm in ipairs(fms) do fm:wipe() end
end

local function ef_unk()
    for _, fm in ipairs(fms) do fm:set_unknowns() end
end

while mm or oot do
    for i, fm in ipairs(fms) do
        fm:diff()
        fm:save()
    end
    print_deferred()
    draw_messages()
    emu.frameadvance()
end
