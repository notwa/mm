local insert = table.insert

local path = string.gsub(..., "[^.]+$", "")
local data = require(path.."data")
local overrides = require(path.."overrides")
local Statement = require(path.."Statement")
local Reader = require(path.."Reader")

local Expander = Reader:extend()
function Expander:init(options)
    self.options = options or {}
end

function Expander:statement(...)
    local s = Statement(self.fn, self.line, ...)
    return s
end

function Expander:push(s)
    s:validate()
    insert(self.statements, s)
end

function Expander:push_new(...)
    self:push(self:statement(...))
end

function Expander:pop(kind)
    local ret
    if kind == nil then
        ret = self.s[self.i]
    elseif kind == 'CPU' then
        ret = self:register(data.registers)
    elseif kind == 'DEREF' then
        ret = self:deref()
    elseif kind == 'CONST' then
        ret = self:const()
    elseif kind == 'END' then
        if self.s[self.i] ~= nil then
            self:error('expected EOL; too many arguments')
        end
        return -- don't increment self.i past end of arguments
    else
        error('Internal Error: unknown kind, got '..tostring(kind))
    end
    self.i = self.i + 1
    return ret
end

function Expander:expand(statements)
    -- third pass: expand pseudo-instructions and register arguments
    self.statements = {}
    for i, s in ipairs(statements) do
        self.s = s
        self.fn = s.fn
        self.line = s.line
        if s.type:sub(1, 1) == '!' then
            self:push(s)
        else
            local name = s.type
            local h = data.instructions[name]
            if h == nil then
                error('Internal Error: unknown instruction')
            end

            if data.one_register_variants[name] then
                self.i = 1
                local a = self:register(data.all_registers)
                local b = s[2]
                if b == nil or b.tt ~= 'REG' then
                    insert(s, 2, self:token(a))
                end
            elseif data.two_register_variants[name] then
                self.i = 1
                local a = self:register(data.all_registers)
                local b = self:register(data.all_registers)
                local c = s[3]
                if c == nil or c.tt ~= 'REG' then
                    insert(s, 2, self:token(a))
                end
            end

            if overrides[name] then
                self.i = 1
                overrides[name](self, name)
                self:pop('END')
            else
                self:push(s)
            end
        end
    end

    return self.statements
end

return Expander
