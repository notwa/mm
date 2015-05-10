local basics = require "addrs.basics"
local versions = require "addrs.versions"

local same = {
    ["O JP10"] = "O US10",
    ["O JP11"] = "O US11",
    ["O JP12"] = "O US12",
    --["O JPGC MQ"] = "O USGC", -- maybe?
}

hash = gameinfo.getromhash() -- TODO: send as argument

version = versions[hash] or _version_override

if version == nil then
    print('ERROR: unknown rom')
    return
end

local v = version:sub(1, 2)
oot = v == "O "
mm  = v == "M "

local rv = same[version] or version

local b = basics[rv]
function AL(a, s) return A(b.link + a, s) end
function AG(a, s)
    if rv == 'M JP10' or rv == 'M JP11' then
        if a >= 0x17000 then -- approximate
            a = a - 0x20
        end
    end
    return A(b.global + a, s)
end
function AA(a, s) return A(b.actor + a, s) end

addrs = require("addrs."..rv)

local common = require("addrs."..v.."common")

setmetatable(addrs, {__index=common})

return addrs
