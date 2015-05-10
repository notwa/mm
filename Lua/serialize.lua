-- it's simple, dumb, unsafe, incomplete, and it gets the damn job done

local type = type
local pairs = opairs or pairs
local tostring = tostring
local open = io.open
local strfmt = string.format
local strrep = string.rep

function kill_bom(s)
    if #s >= 3 and s:byte(1)==0xEF and s:byte(2)==0xBB and s:byte(3)==0xBF then
        return s:sub(4)
    end
    return s
end

function sanitize(v)
    return type(v) == 'string' and strfmt('%q', v) or tostring(v)
end

function _serialize(value, writer, level)
    level = level or 1
    if type(value) == 'table' then
        local indent = strrep('\t', level)
        writer('{\n')
        for key,value in pairs(value) do
            local sane = sanitize(key)
            local keyval = sane == '"'..key..'"' and key or '['..sane..']'
            writer(indent..keyval..' = ')
            _serialize(value, writer, level + 1)
            writer(',\n')
        end
        writer(strrep('\t', level - 1)..'}')
    else
        writer(sanitize(value))
    end
end

function _deserialize(script)
    local f = loadstring(kill_bom(script))
    if f ~= nil then
        return f()
    else
        print('WARNING: no function to deserialize with')
        return nil
    end
end

function serialize(path, value)
    local file = open(path, 'w')
    if not file then return end
    file:write("return ")
    _serialize(value, function(...)
        file:write(...)
    end)
    file:write("\n")
    file:close()
end

function deserialize(path)
    local file = open(path, 'r')
    if not file then return end
    local script = file:read('*a')
    local value = _deserialize(script)
    file:close()
    return value
end
