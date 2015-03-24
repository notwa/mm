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
    ["D3ECB253776CD847A5AA63D859D8C89A2F37B364"] = "O US11",
    ["41B3BDC48D98C48529219919015A1AF22F5057C2"] = "O US12",
    ["B82710BA2BD3B4C6EE8AA1A7E9ACF787DFC72E9B"] = "O USGC",
    ["328A1F1BEBA30CE5E178F031662019EB32C5F3B5"] = "O EU10",
    ["CFBB98D392E4A9D39DA8285D10CBEF3974C2F012"] = "O EU11",
    ["0227D7C0074F2D0AC935631990DA8EC5914597B4"] = "O EUGC",
    ["C892BBDA3993E66BD0D56A10ECD30B1EE612210F"] = "O JP10",
    ["DBFC81F655187DC6FEFD93FA6798FACE770D579D"] = "O JP11",
    ["FA5F5942B27480D60243C2D52C0E93E26B9E6B86"] = "O JP12",
    ["0769C84615422D60F16925CD859593CDFA597F84"] = "O JPGC",

    -- Ocarina of Time: Master Quest
    ["8B5D13AAC69BFBF989861CFDC50B1D840945FC1D"] = "O USGC MQ",
    ["F46239439F59A2A594EF83CF68EF65043B1BFFE2"] = "O EUGC MQ",
    ["50BEBEDAD9E0F10746A52B07239E47FA6C284D03"] = "O EUDB MQ",
    ["DD14E143C4275861FE93EA79D0C02E36AE8C6C2F"] = "O JPGC MQ",
}

local basics = {
    ["M US10"] = {
        link   = 0x1EF670,
        global = 0x3E6B20,
        actor  = 0x3FFDB0,
        LLsize = 0x10,
    },
    ["M USDE"] = {
        link   = 0x1EEE80,
        global = 0x3E63B0,
        actor  = 0x3FF680,
        LLsize = 0x30,
    },
    ["M USGC"] = {
        link   = 0x1ED830,
        global = 0x381260,
        actor  = 0x39A4F0,
        LLsize = 0x10,
    },
    ["M EU10"] = {
        link   = 0x1E6B50,
        global = 0x3DDFC0,
        actor  = 0x3F7250,
        LLsize = 0x10,
    },
    ["M EU11"] = {
        link   = 0x1E6EF0,
        global = 0x3DE360,
        actor  = 0x3F75F0,
        LLsize = 0x10,
    },
    ["M EUDB"] = {
        link   = 0x23F790,
        global = 0x448700,
        actor  = 0x4619D0,
        LLsize = 0x30,
    },
    ["M EUGC"] = {
        link   = 0x1E5480,
        global = 0x378EB0,
        actor  = 0x392140,
        LLsize = 0x10,
    },
    ["M JP10"] = {
        link   = 0x1EF460,
        global = 0x3E6CF0,
        actor  = 0x3FFFA0,
        LLsize = 0x30,
    },
    ["M JP11"] = {
        link   = 0x1EF710,
        global = 0x3E6FB0,
        actor  = 0x400260,
        LLsize = 0x30,
    },
    ["M JPGC"] = {
        link   = 0x1ED820,
        global = 0x381250,
        actor  = 0x39A4E0,
        LLsize = 0x10,
    },

    ["O US10"] = {
        link   = 0x11A5D0,
        global = 0x1C84A0,
        actor  = 0x1DAA30,
        LLsize = 0x30,
    },
    ["O US11"] = {
        link   = 0x11A7B0,
        global = 0x1C8660,
        actor  = 0x1DABF0,
        LLsize = 0x30,
    },
    ["O US12"] = {
        link   = 0x11AC80,
        global = 0x1C8D60,
        actor  = 0x1DB2F0,
        LLsize = 0x30,
    },
    ["O USGC"] = {
        link   = 0x11B148,
        global = 0x1C9660,
        actor  = 0x1DBBB0,
        LLsize = 0x10,
    },
    ["O EU10"] = {
        link   = 0x1183D0,
        global = 0x1C64E0,
        actor  = 0x1D8A70,
        LLsize = 0x30,
    },
    ["O EU11"] = {
        link   = 0x118410,
        global = 0x1C6520,
        actor  = 0x1D8AB0,
        LLsize = 0x30,
    },
    ["O EUGC"] = {
        link   = 0x118958,
        global = 0x1C6E60,
        actor  = 0x1D93B0,
        LLsize = 0x10,
    },
    ["O JPGC"] = {
        link   = 0x11B168,
        global = 0x1C9660,
        actor  = 0x1DBBB0,
        LLsize = 0x10,
    },
    ["O USGC MQ"] = {
        link   = 0x11B128,
        global = 0x1C9620,
        actor  = 0x1DBB70,
        LLsize = 0x10,
    },
    ["O EUGC MQ"] = {
        link   = 0x118938,
        global = 0x1C6E20,
        actor  = 0x1D9370,
        LLsize = 0x10,
    },
    ["O EUDB MQ"] = {
        link   = 0x15E660,
        global = 0x212020,
        actor  = 0x2245B0,
        LLsize = 0x30,
    },
    ["O JPGC MQ"] = {
        link   = 0x11B148,
        global = 0x1C9660,
        actor  = 0x1DBBB0,
        LLsize = 0x10,
    },
}

local same = {
    ["O JP10"] = "O US10",
    ["O JP11"] = "O US11",
    ["O JP12"] = "O US12",
    --["O JPGC MQ"] = "O USGC", -- maybe?
}

--while version == nil do
--    emu.yield() -- wait until a known ROM is loaded (doesn't work)
    hash = gameinfo.getromhash()
    version = versions[hash]
--end

local v = version:sub(1, 2)
oot = v == "O "
mm  = v == "M "

local rv = same[version] or version

local b = basics[rv]
function AL(a, s) return A(b.link   + a, s) end
function AG(a, s) return A(b.global + a, s) end
function AA(a, s) return A(b.actor  + a, s) end

addrs = require(here..rv)

local common = require(here..v.."common")

setmetatable(addrs, {__index=common})

return addrs
