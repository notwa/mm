local format = string.format
local insert = table.insert

local path = string.gsub(..., "[^.]+$", "")
local Token = require(path.."Token")

local Iter = {}
function Iter:__call()
    return self:next(1)
end

local TokenIter = {}
function TokenIter:init(tokens)
    assert(tokens ~= nil)
    self.tokens = tokens
    self:reset()
end

TokenIter.arg_types = {
    NUM = true,
    REG = true,
    VARSYM = true,
    LABELSYM = true,
    RELLABELSYM = true,
}

function TokenIter:error(msg, got)
    if got ~= nil then
        msg = msg..', got '..tostring(got)
    end
    error(format('%s:%d: Error: %s', self.fn, self.line, msg), 2)
end

function TokenIter:reset()
    self.i = 0
    self.tt = nil
    self.tok = nil
    self.fn = nil
    self.line = nil
    self.ended = false
end

function TokenIter:advance(n)
    n = n or 0
    if self.ended then
        error('Internal Error: attempted to advance iterator past end', 2 + n)
    end

    self.i = self.i + 1
    self.t = self.tokens[self.i]
    if self.t == nil then
        self.tt = nil
        self.tok = nil
        self.fn = nil
        self.line = nil
        self.ended = true
    else
        self.tt = self.t.tt
        self.tok = self.t.tok
        self.fn = self.t.fn
        self.line = self.t.line
    end
end

function TokenIter:next(n)
    n = n or 0
    self:advance(n + 1)
    if self.t then return self.t end
end

function TokenIter:peek()
    return self.tokens[self.i + 1]
end

-- now begins the parsing stuff

function TokenIter:token(t, val)
    -- note: call Token directly if you want to specify fn and line manually
    if type(t) == 'table' then
        t.fn = self.fn
        t.line = self.line
        local token = Token(t)
        return token
    else
        local token = Token(self.fn, self.line, t, val)
        return token
    end
end

function TokenIter:is_EOL()
    return self.tt == 'EOL' or self.tt == 'EOF'
end

function TokenIter:expect_EOL()
    if self:is_EOL() then
        return
    end
    self:error('expected end of line', self.tt)
end

function TokenIter:eat_comma()
    if self.tt == 'SEP' and self.tok == ',' then
        self:advance()
        return true
    end
end

function TokenIter:number()
    if self.tt ~= 'NUM' then
        self:error('expected number', self.tt)
    end
    local t = self.t
    self:advance()
    return self:token(t)
end

function TokenIter:string()
    if self.tt ~= 'STRING' then
        self:error('expected string', self.tt)
    end
    local t = self.t
    self:advance()
    return self:token(t)
end

function TokenIter:register(registers)
    registers = registers or data.registers
    if self.tt ~= 'REG' then
        self:error('expected register', self.tt)
    end
    local t = self.t
    if not registers[t.tok] then
        self:error('wrong type of register', t.tok)
    end
    self:advance()
    return self:token(t)
end

function TokenIter:deref()
    if self.tt ~= 'OPEN' then
        self:error('expected opening parenthesis for dereferencing', self.tt)
    end
    self:advance()
    if self.tt ~= 'REG' then
        self:error('expected register to dereference', self.tt)
    end
    local t = self.t
    self:advance()
    if self.tt ~= 'CLOSE' then
        self:error('expected closing parenthesis for dereferencing', self.tt)
    end
    self:advance()
    return self:token(t):set('tt', 'DEREF')
end

function TokenIter:const(relative, no_label)
    local good = {
        NUM = true,
        EXPR = true,
        VARSYM = true,
        LABELSYM = true,
    }
    if not good[self.tt] then
        self:error('expected constant', self.tt)
    end
    if no_label and self.tt == 'LABELSYM' then
        self:error('labels are not allowed here', self.tt)
    end
    local t = self:token(self.t)
    self:advance()
    return t
end

function TokenIter:special()
    if self.tt ~= 'SPECIAL' then
        self:error('expected special name to call', self.tt)
    end
    local name = self.tok
    self:advance()
    if self.tt ~= 'OPEN' then
        self:error('expected opening parenthesis for special call', self.tt)
    end

    local args = {}
    while true do
        local arg = self:advance()
        if not self.arg_types[arg.tt] then
            self:error('invalid argument type', arg.tt)
        else
            self:advance()
        end
        if self.tt == 'SEP' then
            insert(args, arg)
        elseif self.tt == 'CLOSE' then
            insert(args, arg)
            break
        else
            self:error('unexpected token in argument list', self.tt)
        end
    end

    return name, args
end

function TokenIter:basic_special()
    local name, args = self:special()

    local portion
    if name == 'hi' then
        portion = 'upperoff'
    elseif name == 'up' then
        portion = 'upper'
    elseif name == 'lo' then
        portion = 'lower'
    else
        self:error('unknown special', name)
    end

    if #args ~= 1 then
        self:error(name..' expected one argument', #args)
    end

    local t = self:token(args[1]):set('portion', portion)
    return t
end

-- TODO: move this boilerplate elsewhere

local MetaBlah = {
    __index = TokenIter,
    __call = TokenIter.next,
}

local ClassBlah = {}
function ClassBlah:__call(...)
    local obj = setmetatable({}, MetaBlah)
    return obj, obj:init(...)
end

return setmetatable(TokenIter, ClassBlah)
