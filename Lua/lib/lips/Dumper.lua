local insert = table.insert
local floor = math.floor

local data = require "lips.data"

local function bitrange(x, lower, upper)
    return floor(x/2^lower) % 2^(upper - lower + 1)
end

local Dumper = require("lips.Class")()
function Dumper:init(writer, fn, options)
    self.writer = writer
    self.fn = fn or '(string)'
    self.options = options or {}
    self.labels = {}
    self.commands = {}
    self.pos = options.offset or 0
    self.lastcommand = nil
end

function Dumper:error(msg)
    error(format('%s:%d: Error: %s', self.fn, self.line, msg), 2)
end

function Dumper:advance(by)
    self.pos = self.pos + by
end

function Dumper:push_instruction(t)
    t.kind = 'instruction'
    insert(self.commands, t)
    self:advance(4)
end

function Dumper:add_instruction_j(line, o, T)
    self:push_instruction{line=line, o, T}
end

function Dumper:add_instruction_i(line, o, s, t, i)
    self:push_instruction{line=line, o, s, t, i}
end

function Dumper:add_instruction_r(line, o, s, t, d, f, c)
    self:push_instruction{line=line, o, s, t, d, f, c}
end

function Dumper:add_label(name)
    self.labels[name] = self.pos
end

function Dumper:add_bytes(line, ...)
    local use_last = self.lastcommand and self.lastcommand.kind == 'bytes'
    local t
    if use_last then
        t = self.lastcommand
    else
        t = {}
        t.kind = 'bytes'
        t.size = 0
    end
    t.line = line
    for _, b in ipairs{...} do
        t.size = t.size + 1
        t[t.size] = b
    end
    if not use_last then
        insert(self.commands, t)
    end
    self:advance(t.size)
end

function Dumper:add_directive(line, name, a, b)
    local t = {}
    t.line = line
    if name == 'BYTE' then
        self:add_bytes(line, a % 0x100)
    elseif name == 'HALFWORD' then
        local b0 = bitrange(a, 0, 7)
        local b1 = bitrange(a, 8, 15)
        self:add_bytes(line, b1, b0)
    elseif name == 'WORD' then
        local b0 = bitrange(a, 0, 7)
        local b1 = bitrange(a, 8, 15)
        local b2 = bitrange(a, 16, 23)
        local b3 = bitrange(a, 24, 31)
        self:add_bytes(line, b3, b2, b1, b0)
    elseif name == 'ORG' then
        t.kind = 'goto'
        t.addr = a
        insert(self.commands, t)
        self.pos = a % 0x80000000
        self:advance(0)
    elseif name == 'ALIGN' then
        t.kind = 'ahead'
        local align = a*2
        if align == 0 then
            align = 4
        elseif align < 0 then
            self:error('negative alignment')
        end
        local temp = self.pos + align - 1
        t.skip = temp - (temp % align) - self.pos
        t.fill = t.fill or 0
        insert(self.commands, t)
        self:advance(t.skip)
    elseif name == 'SKIP' then
        t.kind = 'ahead'
        t.skip = a
        t.fill = b
        insert(self.commands, t)
        self:advance(t.skip)
    else
        self:error('unimplemented directive')
    end
end

function Dumper:desym(tok)
    -- FIXME: errors can give wrong filename, also off by one
    if type(tok[2]) == 'number' then
        return tok[2]
    elseif tok[1] == 'LABELSYM' then
        local label = self.labels[tok[2]]
        if label == nil then
            self:error('undefined label')
        end
        return label
    elseif tok[1] == 'LABELREL' then
        local label = self.labels[tok[2]]
        if label == nil then
            self:error('undefined label')
        end
        label = label % 0x80000000
        local pos = self.pos % 0x80000000
        local rel = floor(label/4) - 1 - floor(pos/4)
        if rel > 0x8000 or rel <= -0x8000 then
            self:error('branch too far')
        end
        return rel % 0x10000
    end
    self:error('failed to desym') -- internal error?
end

function Dumper:toval(tok)
    if tok == nil then
        self:error('nil value')
    elseif type(tok) == 'number' then
        return tok
    elseif data.all_registers[tok] then
        return data.registers[tok] or data.fpu_registers[tok] or data.sys_registers[tok]
    end
    if type(tok) == 'table' then
        if #tok ~= 2 then
            self:error('invalid token')
        end
        if tok[1] == 'UPPER' then
            local val = self:desym(tok[2])
            return bitrange(val, 16, 31)
        elseif tok[1] == 'LOWER' then
            local val = self:desym(tok[2])
            return bitrange(val, 0, 15)
        elseif tok[1] == 'UPPEROFF' then
            local val = self:desym(tok[2])
            local upper = bitrange(val, 16, 31)
            local lower = bitrange(val, 0, 15)
            if lower >= 0x8000 then
                -- accommodate for offsets being signed
                upper = (upper + 1) % 0x10000
            end
            return upper
        elseif tok[1] == 'SIGNED' then
            local val = self:desym(tok[2])
            if val >= 0x10000 or val < -0x8000 then
                self:error('value out of range')
            end
            return val % 0x10000
        elseif tok[1] == 'NEGATE' then
            local val = -self:desym(tok[2])
            if val >= 0x10000 or val < -0x8000 then
                self:error('value out of range')
            end
            return val % 0x10000
        elseif tok[1] == 'INDEX' then
            local val = self:desym(tok[2]) % 0x80000000
            val = floor(val/4)
            return val
        else
            return self:desym(tok)
        end
    end
    self:error('invalid value') -- internal error?
end

function Dumper:validate(n, bits)
    local max = 2^bits
    if n == nil then
        self:error('value is nil') -- internal error?
    end
    if n > max or n < 0 then
        self:error('value out of range')
    end
end

function Dumper:valvar(tok, bits)
    local val = self:toval(tok)
    self:validate(val, bits)
    return val
end

function Dumper:write(t)
    for _, b in ipairs(t) do
        local s = ('%02X'):format(b)
        self.writer(self.pos, s)
        self.pos = self.pos + 1
    end
end

function Dumper:dump_instruction(t)
    local uw = 0
    local lw = 0

    local o = t[1]
    uw = uw + o*0x400

    if #t == 2 then
        local val = self:valvar(t[2], 26)
        uw = uw + bitrange(val, 16, 25)
        lw = lw + bitrange(val, 0, 15)
    elseif #t == 4 then
        uw = uw + self:valvar(t[2], 5)*0x20
        uw = uw + self:valvar(t[3], 5)
        lw = lw + self:valvar(t[4], 16)
    elseif #t == 6 then
        uw = uw + self:valvar(t[2], 5)*0x20
        uw = uw + self:valvar(t[3], 5)
        lw = lw + self:valvar(t[4], 5)*0x800
        lw = lw + self:valvar(t[5], 5)*0x40
        lw = lw + self:valvar(t[6], 6)
    else
        error('Internal Error: unknown n-size', 1)
    end

    return uw, lw
end

function Dumper:dump()
    self.pos = self.options.offset or 0
    for i, t in ipairs(self.commands) do
        if t.line == nil then
            error('Internal Error: no line number available')
        end
        self.line = t.line
        if t.kind == 'instruction' then
            local uw, lw = self:dump_instruction(t)
            local b0 = bitrange(lw, 0, 7)
            local b1 = bitrange(lw, 8, 15)
            local b2 = bitrange(uw, 0, 7)
            local b3 = bitrange(uw, 8, 15)
            self:write{b3, b2, b1, b0}
        elseif t.kind == 'bytes' then
            self:write(t)
        elseif t.kind == 'goto' then
            self.pos = t.addr
        elseif t.kind == 'ahead' then
            if t.fill then
                for i=1, t.skip do
                    self:write{t.fill}
                end
            else
                self.pos = self.pos + t.skip
            end
        else
            error('Internal Error: unknown command', 1)
        end
    end
end

return Dumper
