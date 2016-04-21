local insert = table.insert

local path = string.gsub(..., "[^.]+$", "")
local data = require(path.."data")

local overrides = {}
-- note: "self" is an instance of Preproc

local function tob_override(self, name)
    -- handle all the addressing modes for lw/sw-like instructions
    local rt = self:pop('CPU')
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
            local immediate = self:token(o):set('portion', 'upperoff')
            self:push_new('LUI', 'AT', immediate)
            if self.s[self.i] ~= nil then
                local reg = self:pop('DEREF'):set('tt', 'REG')
                if reg.tok ~= 'R0' then
                    self:push_new('ADDU', 'AT', 'AT', 'R0')
                end
            end
            base = self:token('DEREF', 'AT')
        else
            base = self:pop('DEREF')
        end
    end
    self:push_new(name, rt, offset, base)
end

for k, v in pairs(data.instructions) do
    if v[2] == 'tob' then
        overrides[k] = tob_override
    end
end

function overrides.LI(self, name)
    local rt = self:pop('CPU')
    local im = self:pop('CONST')

    -- for us, this is just semantics. for a "real" assembler,
    -- LA could add appropriate RELO LUI/ADDIU directives.
    if im.tt == 'LABELSYM' then
        self:error('use LA for labels')
    end

    if im.portion then
        -- FIXME: use appropriate instruction based on portion?
        self:push_new('ADDIU', rt, 'R0', im)
        return
    end

    im.tok = im.tok % 0x100000000
    if im.tok >= 0x10000 and im.tok <= 0xFFFF8000 then
        local rs = rt
        local immediate = self:token(im):set('portion', 'upper')
        self:push_new('LUI', rt, immediate)
        if im.tok % 0x10000 ~= 0 then
            local immediate = self:token(im):set('portion', 'lower')
            self:push_new('ORI', rt, rs, immediate)
        end
    elseif im.tok >= 0x8000 and im.tok < 0x10000 then
        local immediate = self:token(im):set('portion', 'lower')
        self:push_new('ORI', rt, 'R0', immediate)
    else
        local immediate = self:token(im):set('portion', 'lower')
        self:push_new('ADDIU', rt, 'R0', immediate)
    end
end

function overrides.LA(self, name)
    local rt = self:pop('CPU')
    local im = self:pop('CONST')

    local rs = rt
    local immediate = self:token(im):set('portion', 'upperoff')
    self:push_new('LUI', rt, immediate)
    local immediate = self:token(im):set('portion', 'lower')
    self:push_new('ADDIU', rt, rt, immediate)
end

function overrides.PUSH(self, name)
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
        local immediate = self:token(#stack*4):set('negate')
        self:push_new('ADDIU', 'SP', 'SP', immediate)
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
        local immediate = #stack * 4
        self:push_new('ADDIU', 'SP', 'SP', immediate)
    end
end
overrides.POP = overrides.PUSH
overrides.JPOP = overrides.PUSH

function overrides.NAND(self, name)
    local rd = self:pop('CPU')
    local rs = self:pop('CPU')
    local rt = self:pop('CPU')
    self:push_new('AND', rd, rs, rt)
    local rs = rd
    local rt = 'R0'
    self:push_new('NOR', rd, rs, rt)
end

function overrides.NANDI(self, name)
    local rt = self:pop('CPU')
    local rs = self:pop('CPU')
    local immediate = self:pop('CONST')
    self:push_new('ANDI', rt, rs, immediate)
    local rd = rt
    local rs = rt
    local rt = 'R0'
    self:push_new('NOR', rd, rs, rt)
end

function overrides.NORI(self, name)
    local rt = self:pop('CPU')
    local rs = self:pop('CPU')
    local immediate = self:pop('CONST')
    self:push_new('ORI', rt, rs, immediate)
    local rd = rt
    local rs = rt
    local rt = 'R0'
    self:push_new('NOR', rd, rs, rt)
end

function overrides.ROL(self, name)
    -- FIXME
    local rd, rs, rt
    local left = self:pop('CPU')
    rt = self:pop('CPU')
    local immediate = self:pop('CONST')
    error('Internal Error: unimplemented')
end

function overrides.ROR(self, name)
    -- FIXME
    local right = self:pop('CPU')
    local rt = self:pop('CPU')
    local immediate = self:pop('CONST')
    error('Internal Error: unimplemented')
end

function overrides.JR(self, name)
    local rs = self:peek() and self:pop('CPU') or 'RA'
    self:push_new('JR', rs)
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

function overrides.BEQI(self, name)
    local branch = branch_basics[name]
    local reg = self:pop('CPU')
    local immediate = self:pop('CONST')
    local offset = self:pop('REL'):set('signed')

    if reg == 'AT' then
        self:error('register cannot be AT in this pseudo-instruction')
    end

    self:push_new('ADDIU', 'AT', 'R0', immediate)

    self:push_new(branch, reg, 'AT', offset)
end
overrides.BNEI = overrides.BEQI
overrides.BEQIL = overrides.BEQI
overrides.BNEIL = overrides.BEQI

function overrides.BLTI(self, name)
    local branch = branch_basics[name]
    local reg = self:pop('CPU')
    local immediate = self:pop('CONST')
    local offset = self:pop('REL'):set('signed')

    if reg == 'AT' then
        self:error('register cannot be AT in this pseudo-instruction')
    end

    self:push_new('SLTI', 'AT', reg, immediate)

    self:push_new(branch, 'R0', 'AT', offset)
end
overrides.BGEI = overrides.BLTI
overrides.BLTIL = overrides.BLTI
overrides.BGEIL = overrides.BLTI

function overrides.BLEI(self, name)
    -- TODO: this can probably be optimized
    local branch = branch_basics[name]
    local reg = self:pop('CPU')
    local immediate = self:pop('CONST')
    local offset = self:pop('REL'):set('signed')

    if reg == 'AT' then
        self:error('register cannot be AT in this pseudo-instruction')
    end

    self:push_new('ADDIU', 'AT', 'R0', immediate)

    local beq_offset
    if name == 'BLEI' then
        beq_offset = offset
    else
        -- FIXME: this probably isn't correct for branch-likely instructions
        beq_offset = 2 -- branch to delay slot of the next branch
    end
    self:push_new('BEQ', reg, 'R0', beq_offset)

    self:push_new('SLT', 'AT', reg, immediate)

    self:push_new(branch, 'AT', 'R0', offset)
end
overrides.BGTI = overrides.BLEI
overrides.BLEIL = overrides.BLEI
overrides.BGTIL = overrides.BLEI

return overrides
