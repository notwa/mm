local here = select("1", ...):match(".+%.") or ""

A = require "boilerplate"

versions = { -- sha1 hashes of .z64s
    -- Majora's Mask
    ["D6133ACE5AFAA0882CF214CF88DABA39E266C078"] = "M US10",
    ["2F0744F2422B0421697A74B305CB1EF27041AB11"] = "M USDE",
    ["9743AA026E9269B339EB0E3044CD5830A440C1FD"] = "M USGC",
    ["C04599CDAFEE1C84A7AF9A71DF68F139179ADA84"] = "M EU10",
    ["BB4E4757D10727C7584C59C1F2E5F44196E9C293"] = "M EU11",
    ["B38B71D2961DFFB523020A67F4807A4B704E347A"] = "M EUDB",
    ["A849A65E56D57D4DD98B550524150F898DF90A9F"] = "M EUGC",
    ["5FB2301AACBF85278AF30DCA3E4194AD48599E36"] = "M JP10",
    ["41FDB879AB422EC158B4EAFEA69087F255EA8589"] = "M JP11",
    ["1438FD501E3E5B25461770AF88C02AB1E41D3A7E"] = "M JPGC",

    -- Ocarina of Time
    ["AD69C91157F6705E8AB06C79FE08AAD47BB57BA7"] = "O US10",
    -- this is supposedly the same ROM, but i don't have it offhand to verify
    ["79A4F053D34018E59279E6D4B83C7DACCD985C87"] = "O US10",
}

local basics = {
    ["M US10"] = {
        link   = 0x1EF670,
        global = 0x3E6B20,
        actor  = 0x3FFDB0,
    },
    ["M USDE"] = {
        link   = 0x1EEE80,
        global = 0x3E63B0,
        actor  = 0x3FF680,
    },
    ["M USGC"] = {
        link   = 0x1ED830,
        global = 0x381260,
        actor  = 0x39A4F0,
    },
    ["M EU10"] = {
        link   = 0x1E6B50,
        global = 0x3DDFC0,
        actor  = 0x3F7250,
    },
    ["M EU11"] = {
        link   = 0x1E6EF0,
        global = 0x3DE360,
        actor  = 0x3F75F0,
    },
    ["M EUDB"] = {
        link   = 0x23F790,
        global = 0x448700,
        actor  = 0x4619D0,
    },
    ["M EUGC"] = {
        link   = 0x1E5480,
        global = 0x378EB0,
        actor  = 0x392140,
    },
    ["M JP10"] = {
        link   = 0x1EF460,
        global = 0x3E6CF0,
        actor  = 0x3FFFA0,
    },
    ["M JP11"] = {
        link   = 0x1EF710,
        global = 0x3E6FB0,
        actor  = 0x400260,
    },
    ["M JPGC"] = {
        link   = 0x1ED820,
        global = 0x381250,
        actor  = 0x39A4E0,
    },
    ["O US10"] = {
        link   = 0x11A5D0,
        global = 0x1C84A0,
        actor  = 0x1DAA30,
    },
}

--while version == nil do
--    emu.yield() -- wait until a known ROM is loaded (doesn't work)
    hash = gameinfo.getromhash()
    version = versions[hash]
--end

local v = version:sub(1, 2)
oot = v == "O "
mm  = v == "M "

local b = basics[version]
function AL(a, s) return A(b.link   + a, s) end
function AG(a, s) return A(b.global + a, s) end
function AA(a, s) return A(b.actor  + a, s) end

addrs = require(here..version)

local common = require(here..v.."common")

setmetatable(addrs, {__index=common})

return addrs
