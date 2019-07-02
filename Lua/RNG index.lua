-- Random Number Generator reversal script for Bizhawk
-- original algorithm by trivial171 (rng, v2, rnginverse functions)
-- please refer to this video: https://www.youtube.com/watch?v=-9YLCoK5K6o
-- everything else by notwa

local abs = math.abs
local floor = math.floor
local pow = math.pow

-- Lua 5.3 is nice and precise and doesn't coerce everything into doubles.
local precise = 0xDEADBEEF * 0x12345678 % 0x100000000 == 0x5621CA08

-- constants of the LCG:
local m = 1664525    -- 0x0019660D
local b = 1013904223 -- 0x3C6EF35F
local gcd = 4 -- of m and 2^32

local powers = {}
for i = 1, 32 do
    powers[i] = floor(pow(2, i - 1))
end
local big32 = floor(pow(2, 32))

local gamedb = {
    -- pairs of (RNG state address, display list address):
    -- Ocarina of Time (J) 1.0
    ["C892BBDA3993E66BD0D56A10ECD30B1EE612210F"] = {0x105440, 0x11F290},
    -- Ocarina of Time (U) 1.0
    ["AD69C91157F6705E8AB06C79FE08AAD47BB57BA7"] = {0x105440, 0x11F290},
    -- Ocarina of Time (J) 1.2
    ["FA5F5942B27480D60243C2D52C0E93E26B9E6B86"] = {0x105A80, 0x11F958},
    -- Ocarina of Time (U) 1.2
    ["41B3BDC48D98C48529219919015A1AF22F5057C2"] = {0x105A80, 0x11F958},
    -- Majora's Mask (J) 1.0
    ["5FB2301AACBF85278AF30DCA3E4194AD48599E36"] = {0x098550, 0x1F9E28},
    -- Majora's Mask (J) 1.1
    ["41FDB879AB422EC158B4EAFEA69087F255EA8589"] = {0x098490, 0x1FA0D8},
    -- Majora's Mask (U) 1.0
    ["D6133ACE5AFAA0882CF214CF88DABA39E266C078"] = {0x097530, 0x1F9CB8},
    -- Doubutsu no Mori (J) 1.0
    ["E106DFF7146F72415337C96DEB14F630E1580EFB"] = {0x03C590, 0x145080},
}

local function mulmod(a, b, q)
    if precise then return a * b % q end

    -- this needs to be done because old versions of Lua
    -- store everything as doubles. that means we have 52 bits
    -- to work with instead of the 64 that Lua 5.3 provides.
    local limit = 0x10000000000000
    local halflimit = 0x4000000 -- half in terms of bits
--  assert(abs(a) < limit)
--  assert(abs(b) < limit)
--  assert(abs(q) <= limit)

    local L = halflimit -- shorthand
    local a_lo = a % L
    local a_hi = floor(a / L) % L
    local b_lo = b % L
    local b_hi = floor(b / L) % L
    return (a_lo * b_lo + (a_lo * b_hi % L + a_hi * b_lo % L) % L * L) % q
end

local function powmod(b, e, m)
    -- blatantly lifted from Wikipedia and tweaked for overflows.
    if m == 1 then
        return 0
    else
        local r = 1
        b = b % m
        while e > 0 do
            if e % 2 == 1 then
                r = mulmod(r, b, m)
            end
            e = floor(e / 2)
            b = mulmod(b, b, m)
        end
        return r
    end
end

local function mul32(a, b)
    return mulmod(a, b, big32)
end

local function inv32(x)
    -- Modular inverse of x, an odd number.
    -- via https://lemire.me/blog/2017/09/18/computing-the-inverse-of-odd-integers/
--  assert(x % 2, "inv32(x): x must be odd!")
    local y = x % big32
    for i = 1, 4 do
        y = mul32(y, (2 - mul32(y, x)))
    end
    return y
end

local const = floor((m - 1) / gcd)
local const_inv = inv32(const)

local function rng(x)
    -- The xth RNG value returned by the game.
    -- Computable by geometric series formula:
    -- RNG(x) = b * (m^x - 1) / (m - 1) % q
    -- The denominator (m-1) shares a common factor of 4 with q,
    -- so we compute the numerator mod 4q.
    -- We divide by (m-1) by first dividing by 4,
    -- and then multiplying by the modular inverse of the odd number (m-1)/4.
    local temp = floor((powmod(m, x, gcd * big32) - 1) / gcd)
    return mul32(mul32(b, temp), const_inv)
end

local function v2(a)
    -- The 2-adic valuation of a; that is,
    -- the largest integer v such that 2^v divides a.
    if a == 0 then return 100 end -- a large dummy value
    local n = a
    local v = 0
    while n % 2 == 0 do
        n = floor(n / 2)
        v = v + 1
    end
    return v
end

local function rnginverse(r)
    -- Given an RNG value r, compute the unique x in range [0, 2^32)
    -- such that RNG(x) = r. Note that x is only unique under the assumption
    -- that the Linear Congruential Generator used has a period of 2^32.

    -- Recover m^x mod 4q from algebra (inverting steps in RNG function above)
    local q = big32 * gcd
    local xpow = (mul32(mul32(r, const), inv32(b)) * gcd + 1) % q

    local xguess = 0
    for _, p in ipairs(powers) do -- Guess binary digits of x one by one
        -- This technique is based on Mihai's lemma / lifting the exponent
        local lhs = v2(powmod(m, xguess + p, q) - xpow)
        local rhs = v2(powmod(m, xguess,     q) - xpow)
        if lhs > rhs then
            xguess = xguess + p
        end
    end
    return xguess
end

if m == 1664525 and b == 1013904223 then
    -- self-tests:
    assert(inv32(m - 1) == 4211439296)
    assert(rng(0) == 0)
    assert(rng(1) == 1013904223)
    assert(rng(2) == 1196435762)
    assert(rng(3) == 3519870697)
    assert(1 == rnginverse(1013904223))
    assert(2 == rnginverse(1196435762))
    assert(3 == rnginverse(3519870697))
end

-- run the remaining code when executed in Bizhawk, otherwise exit.
if rawget(_G, "bizstring") == nil then return end

local R4 = mainmemory.read_u32_be

local hash = gameinfo.getromhash()
local addrs = gamedb[hash]
if addrs == nil then
    print("unsupported ROM:")
    print(hash)
    return
end

local ind_prev = nil
local dlist_prev = 0
local ind_change = 0

while true do
    local seed = R4(addrs[1])
    local dlist = R4(addrs[2])
    local ind = rnginverse(seed)

    gui.text(8,  8, ("RNG:  0x%08X"):format(seed),       nil, "topright")
    gui.text(8, 24, ("index:  0x%08X"):format(ind),      nil, "topright")
    gui.text(8, 40, ("delta: %+11i"):format(ind_change), nil, "topright")

    if dlist ~= dlist_prev and ind_prev ~= nil then
        ind_change = ind - ind_prev
    end

    ind_prev = ind
    dlist_prev = dlist

    emu.frameadvance()
end
