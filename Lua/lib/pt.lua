local path = string.gsub(..., "[^.]+$", "")
local extra = require(path.."extra")
local opairs = extra.opairs

local pt = {}
pt.__index = pt
setmetatable(pt, pt)

local function rawstr(v)
    if v == nil then return 'nil' end
    local mt = getmetatable(v)
    local ts = mt and rawget(mt, '__tostring')
    if not ts then return tostring(v) end
    mt.__tostring = nil
    local s = tostring(v)
    mt.__tostring = ts
    return s
end

local function getaddr(t)
    return rawstr(t):sub(#type(t) + 3)
end

local function copy(t)
    -- shallow copy
    if type(t) ~= 'table' then return end
    local new = {}
    for k,v in pairs(t) do
        new[k] = v
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
    self.outer = args.alt_order and self.outer_old or self.outer
    self.noncanon = args.noncanon or false
    self.indent = args.indent or ' '
    self.queued = {}
    self.cache = {}
    self.canonicalized = {}
    self:inner('__root', t, '')
    return self.seen
end

function pt:write(...)
    self.writer(...)
end

function pt:safecanon(k)
    local s = tostring(k)
    return s:gsub('[^%w_]', '_')
end

function pt:safekey(k)
    if type(k) == 'table' then
        return 't'..getaddr(k)
    end
    local s = tostring(k)
    s = s:gsub('[\r\n]', '')
    return s:find('[^%w_]') and ('%q'):format(s) or s
end

function pt:safeval(v, indentation)
    if type(v) == 'function' then
        return 'f'..getaddr(v)
    end
    local s = tostring(v)
    if type(v) == 'number' then
        return s
    end
    -- TODO: move newline/indentation handling to another function?
    if s:find('[\r\n]') then
        s = ('\n'..s):gsub('[\r\n]', '\n'..indentation..self.indent)
    end
    --local safe = ('%q'):format(s)
    --return s == safe:sub(2, -2) and s or safe
    -- TODO: finish matching valid characters
    return s:find('[^%w_()[]{}.]') and ('%q'):format(s) or s
end

function pt:inner(k, v, indentation)
    if type(v) ~= 'table' then
        if self.skeleton then return end
        self:write(indentation, self:safekey(k), ': ')
        self:write(self:safeval(v, indentation), '\n')
        return
    end

    local addr = getaddr(v)
    self:write(indentation, self:safekey(k))

    local canon
    if not self.noncanon and type(k) ~= 'table' then
        -- TODO: canonicalize in advance (during ownage of :outer)
        canon = self.canonicalized[addr]
        if canon == nil then
            canon = self:safecanon(k)..'_t'..addr
            self.canonicalized[addr] = canon
        end
    else
        canon = 't'..addr
    end

    if #indentation > self.depth or self.skipped[addr] then
        --self.skipped[addr] = true -- TODO: extra logics
        self:write(': #', canon, '\n')
        return
    end

    if self.seen[addr] or self.queued[addr] then
        self:write(': *', canon, self.seen_elsewhere[addr] and ' #\n' or '\n')
        return
    end

    self.seen[addr] = true

    self:write(': &', canon, '\n')
    self:outer(v, indentation..self.indent)
end

function pt:outer_old(t, indentation)
    if type(t) ~= "table" then
        local s = self:safeval(t, indentation)
        self:write(indentation, s, '\n')
        return
    end

    local ours = {}
    local not_ours = {}

    for k,v in opairs(t) do
        if type(v) == 'table' then
            local addr = getaddr(v)
            if not (self.queued[addr] or self.seen[addr] or self.skipped[addr]) then
                self.queued[addr] = true
                ours[k] = v
            else
                not_ours[k] = v
            end
        else
            self:inner(k, v, indentation)
        end
    end

    for k,v in opairs(not_ours) do
        self:inner(k, v, indentation)
    end

    for k,v in opairs(ours) do
        self.queued[getaddr(v)] = nil
        self:inner(k, v, indentation)
    end

    local mt = getmetatable(t)
    if mt ~= nil then
        self:inner('__metatable', mt, indentation)
    end
end

function pt:outer(t, indentation)
    if type(t) ~= "table" then
        local s = self:safeval(t, indentation)
        self:write(indentation, s, '\n')
        return
    end

    local ours = {}

    for k,v in opairs(t, self.cache) do
        if type(v) == 'table' then
            local addr = getaddr(v)
            if not (self.queued[addr] or self.seen[addr] or self.skipped[addr]) then
                self.queued[addr] = true
                ours[k] = addr
            end
        end
    end

    local mt = getmetatable(t)
    if mt ~= nil then
        self:inner('__metatable', mt, indentation)
    end

    for k,v in opairs(t, self.cache) do
        local addr = ours[k]
        if addr then
            self.queued[addr] = nil
        end
        self:inner(k, v, indentation)
    end
end

return pt
