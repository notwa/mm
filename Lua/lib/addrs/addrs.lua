local basics = require "addrs.basics"
local versions = require "addrs.versions"

local same = {
    ["O JP10"] = "O US10",
    ["O JP11"] = "O US11",
    ["O JP12"] = "O US12",
    --["O JPGC MQ"] = "O USGC", -- maybe?
}

rawset(_G, 'Actor', function() end)

return function(hash)
    local version = versions[hash] or VERSION_OVERRIDE
    if version == nil then
        error('unknown rom')
        return
    end
    local v = version:sub(1, 2)
    local rv = same[version] or version

    local b = basics[rv]
    local function AL(a, s) return A(b.link + a, s) end
    local function AG(a, s)
        if rv == 'M JP10' or rv == 'M JP11' then
            if a >= 0x17000 then -- approximate
                a = a - 0x20
            end
        end
        return A(b.global + a, s)
    end
    local function AA(a, s)
        if rv == 'O EUDB MQ' then
            if a >= 0x130 then -- approximate
                a = a + 0x10
            end
        end
        return A(b.actor + a, s)
    end

    local subdir = version:sub(1, 1)
    local rvs = rv:sub(3)

    rawset(_G, 'AL', AL)
    rawset(_G, 'AG', AG)
    rawset(_G, 'AA', AA)

    local addrs = require("addrs."..subdir.."."..rvs)
    addrs.version = version
    addrs.oot = v == "O "
    addrs.mm  = v == "M "
    local common = require("addrs."..subdir..".common")
    return setmetatable(addrs, {__index=common})
end
