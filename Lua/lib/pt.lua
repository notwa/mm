local extra = require 'extra'
local opairs = extra.opairs

local pt = {}
pt.__index = pt
setmetatable(pt, pt)

function rawstr(v)
    if v == nil then return 'nil' end
    local mt = getmetatable(v)
    local ts = mt and rawget(mt, '__tostring')
    if not ts then return tostring(v) end
    mt.__tostring = nil
    local s = tostring(v)
    mt.__tostring = ts
    return s
end

function getaddr(t)
    return rawstr(t):sub(#type(t) + 3)
end

function copy(t)
    -- shallow copy
    if type(t) ~= 'table' then return end
    local new = {}
    for key, value in pairs(t) do
        new[key] = value
    end
    return new
end

function pt.__call(pt, args)
    -- print a table as semi-valid YAML
    -- with references to prevent recursion/duplication
    local t = args.table or args[1]
    local self = {}
    setmetatable(self, pt)
    self.seen = copy(args.seen) or {}
    self.skipped = copy(args.skipped) or {}
    self.seen_elsewhere = args.seen or {}
    self.depth = args.depth or 16
    self.writer = args.writer or io.write
    self.skeleton = args.skeleton or false
    self.queued = {}
    self:inner('__root__', t, '')
    return self.seen
end

function pt:write(...)
    self.writer(...)
end

function pt.safekey(k)
    if type(k) == 'table' then
        return 't'..getaddr(k)
    end
    local s = tostring(k)
    s = s:gsub('[\r\n]', '')
    return s:find('[^%w_]') and ('%q'):format(s) or s
end

function pt.safeval(v, indent)
    if type(v) == 'function' then
        return 'f'..getaddr(v)
    end
    local s = tostring(v)
    if type(v) == 'number' then
        return s
    end
    s = s:find('[\r\n]') and ('\n'..s):gsub('[\r\n]', '\n'..indent..' ') or s
    --local safe = ('%q'):format(s)
    --return s == safe:sub(2, -2) and s or safe
    -- TODO: finish matching valid characters
    return s:find('[^%w_()[]{}.]') and ('%q'):format(s) or s
end

function pt:inner(k, v, indent)
    if type(v) ~= 'table' then
        if self.skeleton then return end
        self:write(indent, pt.safekey(k), ': ')
        self:write(pt.safeval(v, indent), '\n')
        return
    end

    local addr = getaddr(v)
    self:write(indent, pt.safekey(k))

    if #indent > self.depth or self.skipped[addr] then
        --self.skipped[addr] = true -- TODO: extra logics
        self:write(': #t', addr, '\n')
        return
    end

    if self.seen[addr] or self.queued[addr] then
        self:write(': *t', addr, self.seen_elsewhere[addr] and ' #\n' or '\n')
        return
    end

    self.seen[addr] = true

    self:write(': &t', addr, '\n')
    self:outer(v, indent..' ')
end

function pt:outer(t, indent)
    if type(t) ~= "table" then
        self:write(indent, pt.safeval(t, indent), '\n')
        return
    end

    local ours = {}
    local not_ours = {}

    for k,v in opairs(t) do
        if type(v) == 'table' then
            local addr = getaddr(v)
            if not self.queued[addr] and not self.seen[addr] and not self.skipped[addr] then
                self.queued[addr] = true
                ours[k] = v
            else
                not_ours[k] = v
            end
        else
            self:inner(k, v, indent)
        end
    end

    for k,v in opairs(not_ours) do
        self:inner(k, v, indent)
    end

    for k,v in opairs(ours) do
        self.queued[getaddr(v)] = nil
        self:inner(k, v, indent)
    end

    local mt = getmetatable(t)
    if mt ~= nil then
        self:inner('__metatable', mt, indent)
    end
end

return pt
