local mt = getmetatable(_G)
if mt == nil then
    mt = {}
    setmetatable(_G, mt)
end

function mt.__newindex(t, n, v)
    if n == '_TEMP_BIZHAWK_RULES_' then
        rawset(t, n, v)
        return
    end
    error("cannot assign undeclared global '" .. tostring(n) .. "'", 2)
end

function mt.__index(t, n)
    if n == '_TEMP_BIZHAWK_RULES_' then
        return
    end
    error("cannot use undeclared global '" .. tostring(n) .. "'", 2)
end
