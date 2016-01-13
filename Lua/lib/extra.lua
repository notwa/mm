local function strpad(num, count, pad)
    num = tostring(num)
    return (pad:rep(count)..num):sub(#num)
end

local function add_zeros(num, count)
    return strpad(num, count - 1, '0')
end

local function mixed_sorter(a, b)
    a = type(a) == 'number' and add_zeros(a, 16) or tostring(a)
    b = type(b) == 'number' and add_zeros(b, 16) or tostring(b)
    return a < b
end

-- loosely based on http://lua-users.org/wiki/SortedIteration
-- the original didn't make use of closures for who knows why
local function order_keys(t)
    local oi = {}
    for key in pairs(t) do
        table.insert(oi, key)
    end
    table.sort(oi, mixed_sorter)
    return oi
end

local function opairs(t, cache)
    local oi = cache and cache[t] or order_keys(t)
    if cache then
        cache[t] = oi
    end
    local i = 0
    return function()
        i = i + 1
        local key = oi[i]
        if key then return key, t[key] end
    end
end

return {
    strpad = strpad,
    add_zeros = add_zeros,
    mixed_sorter = mixed_sorter,
    order_keys = order_keys,
    opairs = opairs,
}
