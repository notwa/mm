local insert = table.insert

local path = string.gsub(..., "[^.]+$", "")
local data = require(path.."data")

local overrides = {}
-- note: "self" is an instance of Preproc

local function tob_override(self, name)
    -- handle all the addressing modes for lw/sw-like instructions
    local dest = self:pop('CPU')
    local offset, base
    if self:peek('DEREF') then
        offset = 0
        base = self:pop('DEREF')
    else -- NUM or LABELSYM
        local o = self:pop('CONST')
        if self:peek('NUM') then
            local temp, err = self:pop('CONST'):compute()
            if err then
                self:error(err, temp)
            end
            o:set('offset', temp)
        end
        offset = self:token(o)
        if not o.portion then
            offset:set('portion', 'lower')
        end
        -- attempt to use the fewest possible instructions for this offset
        if not o.portion and (o.tt == 'LABELSYM' or o.tok >= 0x80000000) then
            local temp = self:token(o):set('portion', 'upperoff')
            self:push_new('LUI', 'AT', temp)
            if self.s[self.i] ~= nil then
                local reg = self:pop('DEREF'):set('tt', 'REG')
                if reg.tok ~= 'R0' then
                    self:push_new('ADDU', 'AT', 'AT', reg)
                end
            end
            base = self:token('DEREF', 'AT')
        else
            base = self:pop('DEREF')
        end
    end
    self:push_new(name, dest, offset, base)
end

for k, v in pairs(data.instructions) do
    if v[2] == 'tob' then
        overrides[k] = tob_override
    end
end

function overrides:LI(name)
    local dest = self:pop('CPU')
    local im = self:pop('CONST')

    -- for us, this is just semantics. for a "real" assembler,
    -- LA could add appropriate RELO LUI/ADDIU directives.
    if im.tt == 'LABELSYM' then
        self:error('use LA for labels')
    end

    if im.portion then
        -- FIXME: use appropriate instruction based on portion?
        self:push_new('ADDIU', dest, 'R0', im)
        return
    end

    im.tok = im.tok % 0x100000000
    if im.tok >= 0x10000 and im.tok <= 0xFFFF8000 then
        local temp = self:token(im):set('portion', 'upper')
        self:push_new('LUI', dest, temp)
        if im.tok % 0x10000 ~= 0 then
            local temp = self:token(im):set('portion', 'lower')
            self:push_new('ORI', dest, dest, temp)
        end
    elseif im.tok >= 0x8000 and im.tok < 0x10000 then
        local temp = self:token(im):set('portion', 'lower')
        self:push_new('ORI', dest, 'R0', temp)
    else
        local temp = self:token(im):set('portion', 'lower')
        self:push_new('ADDIU', dest, 'R0', temp)
    end
end

function overrides:LA(name)
    local dest = self:pop('CPU')
    local im = self:pop('CONST')

    local im = self:token(im):set('portion', 'upperoff')
    self:push_new('LUI', dest, im)
    local im = self:token(im):set('portion', 'lower')
    self:push_new('ADDIU', dest, dest, im)
end

function overrides:PUSH(name)
    local w = name == 'PUSH' and 'SW' or 'LW'
    local stack = {}
    for _, t in ipairs(self.s) do
        if t.tt == 'NUM' then
            if t.tok < 0 then
                self:error("can't push a negative number of spaces", t.tok)
            end
            for i=1, t.tok do
                insert(stack, '')
            end
            self:pop()
        else
            insert(stack, self:pop('CPU'))
        end
    end
    if #stack == 0 then
        self:error(name..' requires at least one argument')
    end
    if name == 'PUSH' then
        local im = self:token(#stack*4):set('negate')
        self:push_new('ADDIU', 'SP', 'SP', im)
    end
    for i, r in ipairs(stack) do
        if r ~= '' then
            local offset = (i - 1)*4
            self:push_new(w, r, offset, self:token('DEREF', 'SP'))
        end
    end
    if name == 'JPOP' then
        self:push_new('JR', 'RA')
    end
    if name == 'POP' or name == 'JPOP' then
        local im = #stack * 4
        self:push_new('ADDIU', 'SP', 'SP', im)
    end
end
overrides.POP = overrides.PUSH
overrides.JPOP = overrides.PUSH

function overrides:NAND(name)
    local dest = self:pop('CPU')
    local src = self:pop('CPU')
    local target = self:pop('CPU')
    self:push_new('AND', dest, src, target)
    self:push_new('NOR', dest, dest, 'R0') -- NOT
end

function overrides:NANDI(name)
    local dest = self:pop('CPU')
    local src = self:pop('CPU')
    local im = self:pop('CONST')
    self:push_new('ANDI', dest, src, im)
    self:push_new('NOR', dest, dest, 'R0') -- NOT
end

function overrides:NORI(name)
    local dest = self:pop('CPU')
    local src = self:pop('CPU')
    local im = self:pop('CONST')
    self:push_new('ORI', dest, src, im)
    self:push_new('NOR', dest, dest, 'R0') -- NOT
end

function overrides:ROL(name)
    local first = name == 'ROL' and 'SLL' or 'SRL'
    local second = name == 'ROL' and 'SRL' or 'SLL'
    local dest = self:pop('CPU')
    local src = self:pop('CPU')
    local im = self:pop('CONST')
    if dest == 'AT' or src == 'AT' then
        self:error('registers cannot be AT in this pseudo-instruction')
    end

    self:push_new(first, dest, src, im)
    local temp, err = im:compute()
    if err then
        self:error(err, temp)
    end
    self:push_new(second, 'AT', src, 32 - temp)
    self:push_new('OR', dest, dest, 'AT')
end
overrides.ROR = overrides.ROL

function overrides:ABS(name)
    local dest = self:pop('CPU')
    local src = self:pop('CPU')
    self:push_new('SRA', 'AT', src, 31)
    self:push_new('XOR', dest, src, 'AT')
    self:push_new('SUBU', dest, dest, 'AT')
end

function overrides:CL(name)
    self:expect{'REG'} -- assert there's at least one argument
    for i=1, #self.s do
        local reg = self:pop('CPU')
        self:push_new('CL', reg)
    end
end

function overrides:JR(name)
    local src = self:peek() and self:pop('CPU') or 'RA'
    self:push_new('JR', src)
end

local branch_basics = {
    BEQI = 'BEQ',
    BGEI = 'BEQ',
    BGTI = 'BEQ',
    BLEI = 'BNE',
    BLTI = 'BNE',
    BNEI = 'BNE',
    BEQIL = 'BEQL',
    BGEIL = 'BEQL',
    BGTIL = 'BEQL',
    BLEIL = 'BNEL',
    BLTIL = 'BNEL',
    BNEIL = 'BNEL',
}

function overrides:BEQI(name)
    local branch = branch_basics[name]
    local reg = self:pop('CPU')
    local im = self:pop('CONST')
    local offset = self:pop('CONST')

    if reg == 'AT' then
        self:error('register cannot be AT in this pseudo-instruction')
    end

    self:push_new('ADDIU', 'AT', 'R0', im)

    self:push_new(branch, reg, 'AT', offset)
end
overrides.BNEI = overrides.BEQI
overrides.BEQIL = overrides.BEQI
overrides.BNEIL = overrides.BEQI

function overrides:BLTI(name)
    local branch = branch_basics[name]
    local reg = self:pop('CPU')
    local im = self:pop('CONST')
    local offset = self:pop('CONST')

    if reg == 'AT' then
        self:error('register cannot be AT in this pseudo-instruction')
    end

    self:push_new('SLTI', 'AT', reg, im)

    self:push_new(branch, 'R0', 'AT', offset)
end
overrides.BGEI = overrides.BLTI
overrides.BLTIL = overrides.BLTI
overrides.BGEIL = overrides.BLTI

function overrides:BLEI(name)
    -- TODO: this can probably be optimized
    if name:sub(#name) == 'L' then
        self:error('unimplemented pseudo-instruction', name)
    end
    local branch = branch_basics[name]
    local reg = self:pop('CPU')
    local im = self:pop('CONST')
    local offset = self:pop('CONST')

    if reg == 'AT' then
        self:error('register cannot be AT in this pseudo-instruction')
    end

    self:push_new('ADDIU', 'AT', 'R0', im)

    local beq_offset
    if name == 'BLEI' or name =='BLEIL' then
        beq_offset = offset
    else
        -- branch to delay slot of the next branch
        beq_offset = self:token('NUM', 2):set('fixed')
    end
    self:push_new('BEQ', reg, 'AT', beq_offset)

    self:push_new('SLT', 'AT', reg, 'AT')

    self:push_new(branch, 'AT', 'R0', offset)
end
overrides.BGTI = overrides.BLEI
overrides.BLEIL = overrides.BLEI
overrides.BGTIL = overrides.BLEI

return overrides
