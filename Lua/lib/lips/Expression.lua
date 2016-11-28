local insert = table.insert

local path = string.gsub(..., "[^.]+$", "")
local Base = require(path.."Base")

local Expression = Base:extend()
function Expression:init(variables)
    self.variables = variables or {}
end

Expression.precedence = {
    -- python-ish precedence
    [","]   = -1,
    ["or"]  =  0,
    ["||"]  =  0,
    ["xor"] =  1,
    ["and"] =  2,
    ["&&"]  =  2,
    ["unary not"] = 3,
    ["=="]  =  5,
    ["!="]  =  5,
    ["<"]   =  5,
    [">"]   =  5,
    ["<="]  =  5,
    [">="]  =  5,
    ["|"]   = 10,
    ["^"]   = 11,
    ["&"]   = 12,
    ["<<"]  = 13,
    [">>"]  = 13,
    ["+"]   = 20,
    ["-"]   = 20,
    ["*"]   = 21,
    ["/"]   = 21,
    ["//"]  = 21,
    ["%"]   = 21,
    ["%%"]  = 21,
    ["unary !"] = 30,
    ["unary ~"] = 30,
    ["unary +"] = 30,
    ["unary -"] = 30,
    -- note: precedence of 40 is hardcoded for right-left association
    -- TODO: also hardcode unary handling on right-hand side of operator
    ["**"]      = 40,
}

Expression.unary_ops = {
    ["not"] = function(a) return a == 0 end,
    ["!"]   = function(a) return a == 0 end,
--  ["~"]   = function(a) return F(~I(a)) end,
    ["+"]   = function(a) return a end,
    ["-"]   = function(a) return -a end,
}

Expression.binary_ops = {
    [","]   = function(a, b) return b end,
    ["or"]  = function(a, b) return a or b end,
    ["||"]  = function(a, b) return a or b end,
    ["xor"] = function(a, b) return (a or b) and not (a and b) end,
    ["and"] = function(a, b) return a and b end,
    ["&&"]  = function(a, b) return a and b end,
    ["=="]  = function(a, b) return a == b end,
    ["!="]  = function(a, b) return a ~= b end,
    ["<"]   = function(a, b) return a < b end,
    [">"]   = function(a, b) return a > b end,
    ["<="]  = function(a, b) return a <= b end,
    [">="]  = function(a, b) return a >= b end,
--  ["|"]   = function(a, b) return F(I(a)  | I(b)) end,
--  ["^"]   = function(a, b) return F(I(a)  ^ I(b)) end,
--  ["&"]   = function(a, b) return F(I(a)  & I(b)) end,
--  ["<<"]  = function(a, b) return F(I(a) << I(b)) end,
--  [">>"]  = function(a, b) return F(I(a) >> I(b)) end,
    ["+"]   = function(a, b) return a + b end,
    ["-"]   = function(a, b) return a - b end,
    ["*"]   = function(a, b) return a * b end,
    ["/"]   = function(a, b) return a / b end,
--  ["//"]  = function(a, b) return trunc(a / trunc(b)) end,
--  ["%"]   = function(a, b) return fmod(a, b) end,
--  ["%%"]  = function(a, b) return trunc(fmod(a, trunc(b))) end,
    ["**"]  = function(a, b) return a^b end,
}

local operators = {}
local operators_maxlen = 0
do
    -- reorder operators so we can match the longest strings first
    for k, v in pairs(Expression.precedence) do
        if operators[#k] == nil then
            operators[#k] = {}
        end
        local op = k:find('^unary ') and k:sub(#'unary ' + 1) or k
        insert(operators[#k], op)
        if #k > operators_maxlen then
            operators_maxlen = #k
        end
    end
end

local function match_operator(str)
    -- returns the operator at the beginning of a string, or nil
    for i=operators_maxlen, 1, -1 do
        if operators[i] ~= nil then
            local substr = str:sub(1, i)
            for _, op in ipairs(operators[i]) do
                if substr == op then
                    return substr
                end
            end
        end
    end
end

function Expression:lex1(str, tokens)
    local pos = 1
    local rest = str
    local function consume(n)
        pos = pos + n
        rest = rest:sub(n + 1)
    end

    local considered = ''
    local function consider(pattern)
        local start, stop = rest:find('^'..pattern)
        if start == nil then
            considered = ''
            return false
        end
        considered = rest:sub(start, stop)
        return true
    end

    local function consider_operator()
        local op = match_operator(rest)
        if op == nil then
            considered = ''
            return false
        end
        considered = op
        return true
    end

    while pos <= #str do
        local old_pos = pos
        local here = " (#"..tostring(pos)..")"
        if consider(' +') then
            consume(#considered)
        elseif consider('[0-9.]') then
            local num
            if consider('((0|[1-9][0-9]*)%.[0-9]*|%.[0-9]+)(e0|e[1-9][0-9]*)?') then
                num = tonumber(considered)
            elseif consider('(0|[1-9][0-9]*)e(0|[1-9][0-9]*)') then
                num = tonumber(considered)
            elseif consider('[0-1]+b') then
                num = tonumber(considered, 2)
            elseif consider('0x[0-9A-Fa-f]+') then
                num = tonumber(considered, 16)
            elseif consider('0[0-9]+') then
                if considered:match('[89]') then
                    return "bad octal number: "..considered..here
                end
                num = tonumber(considered, 8)
            elseif consider('[0-9]*') then
                num = tonumber(considered)
            end
            if num == nil then
                return "invalid number"..here
            end
            insert(tokens, {type='number', value=num})
            consume(#considered)
        elseif consider('[(]') then
            insert(tokens, {type='opening', value=considered})
            consume(#considered)
        elseif consider('[)]') then
            insert(tokens, {type='closing', value=considered})
            consume(#considered)
        elseif consider_operator() then
            insert(tokens, {type='operator', value=considered})
            consume(#considered)
        elseif consider('%w+') then
            local num = self.variables[considered]
            if num == nil then
                return 'undefined variable "'..considered..'"'
            end
            insert(tokens, {type='number', value=num})
            consume(#considered)
        else
            local chr = rest:sub(1, 1)
            return "unexpected character '"..chr.."'"..here
        end
        if pos == old_pos then
            error("Internal Error: expression parser is stuck")
        end
    end
end

function Expression:lex2(tokens)
    -- detect unary operators
    -- TODO: this is probably not the best way to do this
    local was_numeric = false
    local was_closing = false
    for i, t in ipairs(tokens) do
        if t.type == "operator" and not was_numeric and not was_closing then
            t.type = "unary";
        end
        was_numeric = t.type == 'number'
        was_closing = t.type == 'closing'
    end
end

function Expression:lex(str)
    local tokens = {}
    err = self:lex1(str, tokens)
    if err then return tokens, err end
    err = self:lex2(tokens)
    return tokens, err
end

function Expression:shunt(tokens)
    -- shunting yard algorithm
    local shunted = {}
    local stack = {}

    local operator_types = {
        unary = true,
        operator = true,
    }

    for _, t in ipairs(tokens) do
        if t.type == 'number' then
            insert(shunted, t)
        elseif t.type == 'opening' then
            insert(stack, t)
        elseif t.type == 'closing' then
            while #stack > 0 and stack[#stack].type ~= 'opening' do
                insert(shunted, stack[#stack])
                stack[#stack] = nil
            end
            if #stack == 0 then return shunted, 'missing opening parenthesis' end
            stack[#stack] = nil
        elseif t.type == 'operator' or t.type == 'unary' then
            local fullname = t.type == 'unary' and 'unary '..t.value or t.value
            local pre = self.precedence[fullname]
            if pre == nil then return shunted, 'unknown operator' end
            if pre == 40 then pre = pre + 1 end -- right-associative hack
            while #stack > 0 do
                local tail = stack[#stack]
                if not operator_types[tail.type] then break end
                local dpre = pre - self.precedence[tail.value]
                if dpre > 0 then break end
                insert(shunted, tail)
                stack[#stack] = nil
            end
            insert(stack, t)
        else
            error('Internal Error: unknown type of expression token')
        end
    end

    while #stack > 0 do
        local t = stack[#stack]
        if t.type == 'opening' then return shunted, 'missing closing parenthesis' end
        insert(shunted, t)
        stack[#stack] = nil
    end

    return shunted, nil
end

function Expression:parse(str)
    local tokens, err = self:lex(str)
    if err then return tokens, err end
    tokens, err = self:shunt(tokens)
    --for i, v in ipairs(tokens) do print(i, v.type, v.value) end
    return tokens, err
end

function Expression:eval(tokens_or_str)
    local tokens, err
    if type(tokens_or_str) == 'string' then
        tokens, err = self:parse(tokens_or_str)
        if err then return 0, err end
    elseif type(tokens_or_str) == 'table' then
        tokens = tokens_or_str
    else
        return 0, "eval(): argument is neither token table nor string"
    end

    local stack = {}
    local popped
    local function pop()
        if #stack == 0 then return true end
        popped = stack[#stack]
        stack[#stack] = nil
        return false
    end

    for i, t in ipairs(tokens) do
        if t.type == 'number' then
            insert(stack, t.value)
        elseif t.type == 'unary' then
            if pop() then return 0, "missing arguments for unary" end
            local f = self.unary_ops[t.value]
            if f == nil then return 0, "unknown unary" end
            insert(stack, f(popped))
        elseif t.type == 'operator' then
            if pop() then return 0, "missing arguments for operator" end
            local b = popped
            if pop() then return 0, "missing arguments for operator" end
            local a = popped
            local f = self.binary_ops[t.value]
            if f == nil then return 0, "unknown operator" end
            insert(stack, f(a, b))
        else
            return 0, "eval(): unknown token"
        end
    end

    if #stack > 1 then return 0, "too many arguments" end
    if #stack == 0 then return 0, "no arguments" end

    return stack[1], nil
end

return Expression
