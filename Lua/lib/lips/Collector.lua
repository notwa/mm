local insert = table.insert

local path = string.gsub(..., "[^.]+$", "")
local Base = require(path.."Base")
local Token = require(path.."Token")
local TokenIter = require(path.."TokenIter")
local Statement = require(path.."Statement")

local Collector = Base:extend()
function Collector:init(options)
    self.options = options or {}
end

function Collector:statement(...)
    local I = self.iter
    local s = Statement(I.fn, I.line, ...)
    return s
end

function Collector:push_data(datum, size)
    local I = self.iter
    --[[ pseudo-example:
    Statement{type='!DATA',
        {tt='BYTES', tok={0, 1, 2}},
        {tt='HALFWORDS', tok={3, 4, 5}},
        {tt='WORDS', tok={6, 7, 8}},
        {tt='LABEL', tok='myLabel'},
    }
    --]]

    -- FIXME: optimize the hell out of this garbage, preferably in the lexer
    -- TODO: consider not scrunching data statements, just their tokens
    -- TODO: concatenate strings; use !BIN instead of !DATA

    if type(datum) == 'number' then
        datum = I:token(datum)
    end

    local last_statement = self.statements[#self.statements]
    local s
    if last_statement and last_statement.type == '!DATA' then
        s = last_statement
    else
        s = self:statement('!DATA')
        insert(self.statements, s)
    end

    if size ~= 'BYTE' and size ~= 'HALFWORD' and size ~= 'WORD' then
        error('Internal Error: unknown data size argument')
    end

    if datum.tt == 'LABELSYM' then
        if size == 'WORD' then
            -- labels will be assembled to words
            insert(s, datum)
            return
        else
            I:error('labels are too large to be used in this directive')
        end
    elseif datum.tt == 'VARSYM' then
        insert(s, datum:set('size', size))
        return
    elseif datum.tt ~= 'NUM' then
        I:error('unsupported data type', datum.tt)
    end

    local sizes = size..'S'

    local last_token = s[#s]
    local t
    if last_token and last_token.tt == sizes then
        t = last_token
    else
        t = I:token(sizes, {})
        insert(s, t)
        s:validate()
    end
    insert(t.tok, datum.tok)
end

function Collector:directive(name)
    local I = self.iter
    local function add(kind, ...)
        insert(self.statements, self:statement('!'..kind, ...))
    end

    if name == 'ORG' or name == 'BASE' then
        add(name, I:const(nil, 'no labels'))
    elseif name == 'PUSH' or name == 'POP' then
        add(name, I:const())
        while not I:is_EOL() do
            I:eat_comma()
            add(name, I:const())
        end
    elseif name == 'ALIGN' or name == 'SKIP' then
        if I:is_EOL() and name == 'ALIGN' then
            add(name)
        else
            local size = I:const(nil, 'no label')
            if I:is_EOL() then
                add(name, size)
            else
                I:eat_comma()
                add(name, size, I:const(nil, 'no label'))
            end
        end
    elseif name == 'BIN' then
        -- FIXME: not a real directive, just a workaround
        add(name, I:string())
    elseif name == 'BYTE' or name == 'HALFWORD' or name == 'WORD' then
        self:push_data(I:const(), name)
        while not I:is_EOL() do
            I:eat_comma()
            self:push_data(I:const(), name)
        end
    elseif name == 'HEX' then
        if I.tt ~= 'OPEN' then
            I:error('expected opening brace for hex directive', I.tt)
        end
        I:next()

        while I.tt ~= 'CLOSE' do
            if I.tt == 'EOL' then
                I:next()
            else
                self:push_data(I:const(), 'BYTE')
            end
        end
        I:next()
    elseif name == 'INC' or name == 'INCBIN' then
        -- noop, handled by lexer
        I:string()
    elseif name == 'ASCII' or name == 'ASCIIZ' then
        local bytes = I:string()
        for i, number in ipairs(bytes.tok) do
            self:push_data(number, 'BYTE')
        end
        if name == 'ASCIIZ' then
            self:push_data(0, 'BYTE')
        end
    elseif name == 'FLOAT' then
        I:error('unimplemented directive', name)
    else
        I:error('unknown directive', name)
    end

    I:expect_EOL()
end

function Collector:instruction(name)
    local I = self.iter
    local s = self:statement(name)
    insert(self.statements, s)

    while I.tt ~= 'EOL' do
        local t = I.t
        if I.tt == 'OPEN' then
            insert(s, I:deref())
        elseif I.tt == 'UNARY' then
            local peek = assert(I:peek())
            if peek.tt == 'VARSYM' then
                local negate = t.tok == -1
                t = I:next()
                t = Token(t):set('negate', negate)
                insert(s, t)
                I:next()
            elseif peek.tt == 'EOL' or peek.tt == 'SEP' then
                local tok = t.tok == 1 and '+' or t.tok == -1 and '-'
                t = Token(I.fn, I.line, 'RELLABELSYM', tok)
                insert(s, t)
                I:next()
            else
                I:error('unexpected token after unary operator', peek.tt)
            end
        elseif I.tt == 'SPECIAL' then
            t = I:basic_special()
            insert(s, t)
            I:next()
        elseif I.tt == 'SEP' then
            I:error('extraneous comma')
        elseif not I.arg_types[I.tt] then
            I:error('unexpected argument type in instruction', I.tt)
        else
            insert(s, t)
            I:next()
        end
        I:eat_comma()
    end

    I:expect_EOL()
    s:validate()
end

function Collector:collect(tokens, fn)
    self.iter = TokenIter(tokens)
    local I = self.iter

    self.statements = {}

    -- this works, but probably shouldn't be in this function specifically
    if self.options.origin then
        local s = Statement('(options)', 0, '!ORG', self.options.origin)
        insert(self.statements, s)
    end
    if self.options.base then
        local s = Statement('(options)', 0, '!BASE', self.options.base)
        insert(self.statements, s)
    end

    for t in I do
        if t.tt == 'EOF' then
            -- noop
        elseif t.tt == 'EOL' then
            -- noop; empty line
        elseif t.tt == 'LABEL' or t.tt == 'RELLABEL' then
            insert(self.statements, self:statement('!LABEL', t))
        elseif t.tt == 'VAR' then
            local t2 = I:next()
            I:next()
            local s = self:statement('!VAR', t, t2)
            insert(self.statements, s)
            I:expect_EOL()
        elseif t.tt == 'DIR' then
            I:next()
            self:directive(t.tok)
        elseif t.tt == 'INSTR' then
            I:next()
            self:instruction(t.tok)
        else
            I:error('expected starting token for statement', t.tt)
        end
    end

    return self.statements
end

return Collector
