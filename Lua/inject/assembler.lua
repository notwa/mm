-- i've lost control of my life

-- instructions: https://github.com/mikeryan/n64dev/tree/master/docs/n64ops
-- CajeASM style assembly; refer to the manual included with CajeASM.
-- lexer and parser are somewhat based on http://chunkbake.luaforge.net/

local Class = Class or function(inherit)
    local class = {}
    local mt_obj = {__index = class}
    local mt_class = {
        __call = function(self, ...)
            local obj = setmetatable({}, mt_obj)
            obj:init(...)
            return obj
        end,
        __index = inherit,
    }

    return setmetatable(class, mt_class)
end

-- TODO: maybe support reg# style too
local registers = {
    [0]=
    'R0', 'AT', 'V0', 'V1', 'A0', 'A1', 'A2', 'A3',
    'T0', 'T1', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7',
    'S0', 'S1', 'S2', 'S3', 'S4', 'S5', 'S6', 'S7',
    'T8', 'T9', 'K0', 'K1', 'GP', 'SP', 'S8', 'RA',
}

local fpu_registers = {
    [0]=
    'F0',  'F1',  'F2',  'F3',  'F4',  'F5',  'F6',  'F7',
    'F8',  'F9',  'F10', 'F11', 'F12', 'F13', 'F14', 'F15',
    'F16', 'F17', 'F18', 'F19', 'F20', 'F21', 'F22', 'F23',
    'F24', 'F25', 'F26', 'F27', 'F28', 'F29', 'F30', 'F31',
}

local all_instructions = {
    'ADD', 'ADDI', 'ADDIU', 'ADDU',
    'AND', 'ANDI',
    'BC1F', 'BC1FL',
    'BC1T', 'BC1TL',
    'BEQ', 'BEQL',
    'BGEZ', 'BGEZAL', 'BGEZALL', 'BGEZL',
    'BGTZ', 'BGTZL',
    'BLEZ', 'BLEZL',
    'BLTZ', 'BLTZAL', 'BLTZALL', 'BLTZL',
    'BNE', 'BNEL',
    'BREAK',
    'CACHE',
    'CFC1',
    'CTC1',
    'DADD', 'DADDI', 'DADDIU', 'DADDU',
    'DDIV', 'DDIVU',
    'DIV', 'DIVU',
    'DMFC1', 'DMTC1',
    'DMULT', 'DMULTU',
    'DSLL', 'DSLL32', 'DSLLV',
    'DSRA', 'DSRA32', 'DSRAV',
    'DSRL', 'DSRL32', 'DSRLV',
    'DSUB', 'DSUBU',
    'ERET',
    'J',
    'JAL', 'JALR',
    'JR',
    'LB', 'LBU',
    'LD',
    'LDC1', 'LDC2',
    'LDL', 'LDR',
    'LH',
    'LHU',
    'LL',
    'LLD',
    'LUI',
    'LW',
    'LWC1',
    'LWL', 'LWR',
    'LWU',
    'MFC0',
    'MFC1',
    'MFHI',
    'MFLO',
    'MTC0', 'MTC1',
    'MTHI', 'MTLO',
    'MULT', 'MULTU',
    'NOR',
    'OR', 'ORI',
    'SB',
    'SC',
    'SCD',
    'SD',
    'SDC1', 'SDC2',
    'SDL', 'SDR',
    'SH',
    'SLL', 'SLLV',
    'SLT', 'SLTI', 'SLTIU', 'SLTU',
    'SRA', 'SRAV',
    'SRL', 'SRLV',
    'SUB', 'SUBU',
    'SW',
    'SWC1',
    'SWL', 'SWR',
    'SYNC',
    'SYSCALL',
    'TEQ', 'TEQI',
    'TGE', 'TGEI', 'TGEIU', 'TGEU',
    'TLBP', 'TLBR', 'TLBWI', 'TLBWR',
    'TLT', 'TLTI', 'TLTIU', 'TLTU',
    'TNE', 'TNEI',
    'XOR', 'XORI',

    'ABS.D', 'ABS.S',
    'ADD.D', 'ADD.S',
    'CEIL.L.D', 'CEIL.L.S',
    'CEIL.W.D', 'CEIL.W.S',
    'CVT.D.L', 'CVT.D.S', 'CVT.D.W',
    'CVT.L.D', 'CVT.L.S',
    'CVT.S.D', 'CVT.S.L', 'CVT.S.W',
    'CVT.W.D', 'CVT.W.S',
    'DIV.D', 'DIV.S',
    'FLOOR.L.D', 'FLOOR.L.S',
    'FLOOR.W.D', 'FLOOR.W.S',
    'MOV.F', 'MOV.S',
    'MUL.F', 'MUL.S',
    'NEG.F', 'NEG.S',
    'ROUND.L.D', 'ROUND.L.S',
    'ROUND.W.D', 'ROUND.W.S',
    'SQRT.D', 'SQRT.S',
    'SUB.D', 'SUB.S',
    'TRUNC.L.S', 'TRUNC.W.D',

    'C.EQ.D', 'C.EQ.S',
    'C.F.D', 'C.F.S',
    'C.LE.D', 'C.LE.S',
    'C.LT.D', 'C.LT.S',
    'C.NGE.D', 'C.NGE.S',
    'C.NGL.D', 'C.NGL.S',
    'C.NGLE.D', 'C.NGLE.S',
    'C.NGT.D', 'C.NGT.S',
    'C.OLE.D', 'C.OLE.S',
    'C.OLT.D', 'C.OLT.S',
    'C.SEQ.D', 'C.SEQ.S',
    'C.SF.D', 'C.SF.S',
    'C.UEQ.D', 'C.UEQ.S',
    'C.ULE.D', 'C.ULE.S',
    'C.ULT.D', 'C.ULT.S',
    'C.UN.D', 'C.UN.S',

    -- pseudo-instructions
    'B',
    'BAL',
    'BEQI',
    'BNEI',
    'BGE', 'BGEI',
    'BLE', 'BLEI',
    'BLT', 'BLTI',
    'BGT', 'BGTI',
    'CL',
    'LI',
    'MOV',
    'NOP',
    'SUBI', 'SUBIU',
}

local all_directives = {
    'ALIGN', 'SKIP',
    'ASCII', 'ASCIIZ',
    'BYTE', 'HALFWORD', 'WORD', 'FLOAT',
    --'HEX', -- excluded here due to different syntax
    'INC', 'INCASM', 'INCLUDE',
    'INCBIN',
    'ORG',
}

local all_tokens = {
    'DEF',
    'DEFSYM',
    'DEREF',
    'DIR',
    'EOF',
    'EOL',
    'INSTR',
    'LABEL',
    'LABELSYM',
    'NUM',
    'REG',
    'SEP',
}

local all_registers = {}
for k, v in pairs(registers) do
    all_registers[k] = v
end
for k, v in pairs(fpu_registers) do
    all_registers[k + 32] = v
end

-- set up reverse table lookups
local function revtable(t)
    for k, v in pairs(t) do
        t[v] = k
    end
end

revtable(registers)
revtable(fpu_registers)
revtable(all_registers)
revtable(all_instructions)
revtable(all_tokens)

local argtypes = {
    bto = 'base rt offset',
    sti = 'rs rt immediate',
    std = 'rs rt rd', -- ending with 5 unset bits and a const
    st  = 'rs rt', -- ending with 10 unset bits and a const
    tds = 'rs rd rs/sa', -- starting with 5 unset bits, ending with a const
    s   = 'rs', -- followed by 15 unset bits and a const
    sto = 'rs rt offset',
    stc = 'rs rt code', -- followed by a const
    so  = 'rs offset', -- with a const inbetween
    sync= 'stype', -- starting with 15 unset bits, ending with a const
    indx= 'index',

    lui = 'rt immediate', -- starting with 5 unset bits
    mf  = 'rd', -- 10 unset bits on left, 5 on right, ending with a const
    jalr= 'rs rd', -- 5 unset bits inbetween, 5 on right, ending with a const
    code= 'code', -- ending with a const

    movf= 'rd fs', -- starting with const, ending with 11 unset bits
    bfo = 'base fs offset',

    tsdf= 'ft fs fd', -- starting with a const of 16, ending with a const
    tsdd= 'ft fs fd', -- starting with a const of 17, ending with a const
}

local at = argtypes -- temporary shorthand
local instruction_handlers = {
    J       = { 2, at.indx},
    JAL     = { 3, at.indx},

    JALR    = { 0, at.jalr, 9},

    MTHI    = { 0, at.s,   17},
    MTLO    = { 0, at.s,   19},
    JR      = { 0, at.s,    8},

    BREAK   = { 0, at.code,13},
    SYSCALL = { 0, at.code,12},

    SYNC    = { 0, at.sync,15},

    --

    LB      = {32, at.bto},
    LBU     = {36, at.bto},
    LD      = {55, at.bto},
    LDL     = {26, at.bto},
    LDR     = {27, at.bto},
    LH      = {33, at.bto},
    LHU     = {37, at.bto},
    LL      = {48, at.bto},
    LLD     = {52, at.bto},
    LW      = {35, at.bto},
    LWL     = {34, at.bto},
    LWR     = {38, at.bto},
    LWU     = {39, at.bto},
    SB      = {40, at.bto},
    SC      = {56, at.bto},
    SCD     = {60, at.bto},
    SD      = {63, at.bto},
    SDL     = {44, at.bto},
    SDR     = {45, at.bto},
    SH      = {41, at.bto},
    SW      = {43, at.bto},
    SWL     = {42, at.bto},
    SWR     = {46, at.bto},

    LUI     = {15, at.lui},

    MFHI    = { 0, at.mf,  16},
    MFLO    = { 0, at.mf,  18},

    ADDI    = { 8, at.sti},
    ADDIU   = { 9, at.sti},
    ANDI    = {12, at.sti},
    DADDI   = {24, at.sti},
    DADDIU  = {25, at.sti},
    ORI     = {13, at.sti},
    SLTI    = {10, at.sti},
    SLTIU   = {11, at.sti},
    XORI    = {14, at.sti},

    ADD     = { 0, at.std, 32},
    ADDU    = { 0, at.std, 33},
    AND     = { 0, at.std, 36},
    DADD    = { 0, at.std, 44},
    DADDU   = { 0, at.std, 45},
    DSLLV   = { 0, at.std, 20},
    DSUB    = { 0, at.std, 46},
    DSUBU   = { 0, at.std, 47},
    NOR     = { 0, at.std, 39},
    OR      = { 0, at.std, 37},
    SLLV    = { 0, at.std,  4},
    SLT     = { 0, at.std, 42},
    SLTU    = { 0, at.std, 43},
    SRAV    = { 0, at.std,  7},
    SRLV    = { 0, at.std,  6},
    SUB     = { 0, at.std, 34},
    SUBU    = { 0, at.std, 35},
    XOR     = { 0, at.std, 38},

    DDIV    = { 0, at.st,  30},
    DDIVU   = { 0, at.st,  31},
    DIV     = { 0, at.st,  26},
    DIVU    = { 0, at.st,  27},
    DMULT   = { 0, at.st,  28},
    DMULTU  = { 0, at.st,  29},
    MULT    = { 0, at.st,  24},
    MULTU   = { 0, at.st,  25},

    DSLL    = { 0, at.tds, 56},
    DSLL32  = { 0, at.tds, 60},
    DSRA    = { 0, at.tds, 59},
    DSRA32  = { 0, at.tds, 63},
    DSRAV   = { 0, at.tds, 23},
    DSRL    = { 0, at.tds, 58},
    DSRL32  = { 0, at.tds, 62},
    DSRLV   = { 0, at.tds, 22},
    SLL     = { 0, at.tds,  0},
    SRA     = { 0, at.tds,  3},
    SRL     = { 0, at.tds,  2},

    BEQ     = { 4, at.sto},
    BEQL    = {20, at.sto},
    BNE     = { 5, at.sto},
    BNEL    = {21, at.sto},

    BGEZ    = { 1, at.so,   1},
    BGEZAL  = { 1, at.so,  17},
    BGEZALL = { 1, at.so,  19},
    BGEZL   = { 1, at.so,   3},
    BGTZ    = { 7, at.so,   0},
    BGTZL   = {23, at.so,   0},
    BLEZ    = { 6, at.so,   0},
    BLEZL   = {22, at.so,   0},
    BLTZ    = { 1, at.so,   0},
    BLTZAL  = { 1, at.so,  16},
    BLTZALL = { 1, at.so,  18},
    BLTZL   = { 1, at.so,   2},

    TEQ     = { 0, at.stc, 52},
    TGE     = { 0, at.stc, 48},
    TGEU    = { 0, at.stc, 49},
    TLT     = { 0, at.stc, 50},
    TLTU    = { 0, at.stc, 51},
    TNE     = { 0, at.stc, 54},

    ADD_D   = {17, at.tsdd, 0},
    ADD_S   = {17, at.tsdf, 0},
    DIV_D   = {17, at.tsdd, 3},
    DIV_S   = {17, at.tsdf, 3},
    MUL_D   = {17, at.tsdd, 2},
    MUL_S   = {17, at.tsdf, 2},
    SUB_D   = {17, at.tsdd, 1},
    SUB_S   = {17, at.tsdf, 1},

    CFC1    = {17, at.movf, 2},
    CTC1    = {17, at.movf, 6},
    DMFC1   = {17, at.movf, 1},
    DMTC1   = {17, at.movf, 5},
    MFC0    = {16, at.movf, 0},
    MFC1    = {16, at.movf, 0},
    MTC0    = {17, at.movf, 4},
    MTC1    = {17, at.movf, 4},

    LDC1    = {53, at.bfo},
    LWC1    = {49, at.bfo},
    SDC1    = {61, at.bfo},
    SWC1    = {57, at.bfo},

    -- pseudo-instructions
    NOP     = { 0, at.code, 0},
}
at = nil

local Lexer = Class()
function Lexer:init(asm)
    self.asm = asm
    self.pos = 1
    self.line = 1
    self.EOF = -1
    self:nextc()
end

local Dumper = Class()
function Dumper:init(writer)
    self.writer = writer
    self.defines = {}
    self.labels = {}
    self.lines = {}
end

local Parser = Class()
function Parser:init(writer)
    self.dumper = Dumper(writer)
end

function Lexer:error(msg)
    error(string.format('%s:%d: Error: %s', 'file.asm', self.line, msg), 2)
end

function Lexer:nextc()
    if self.pos > #self.asm then
        self.ord = self.EOF
        self.chr = ''
        self.chrchr = ''
        return
    end

    if self.chr == '\n' then
        self.line = self.line + 1
    end

    self.ord = string.byte(self.asm, self.pos)
    self.pos = self.pos + 1

    -- handle newlines; translate CRLF to LF
    if self.ord == 13 then
        if self.pos <= #self.asm and string.byte(self.asm, self.pos) == 10 then
            self.pos = self.pos + 1
        end
        self.ord = 10
    end

    self.chr = string.char(self.ord)
    if self.pos <= #self.asm then
        self.ord2 = string.byte(self.asm, self.pos)
        self.chr2 = string.char(self.ord2)
        self.chrchr = string.char(self.ord, self.ord2)
    else
        self.chrchr = self.chr
    end
end

function Lexer:skip_to_EOL()
    while self.chr ~= '\n' and self.ord ~= self.EOF do
        self:nextc()
    end
end

function Lexer:save_next()
    self.buff = self.buff..self.chr
    self:nextc()
end

function Lexer:read_chars(pattern)
    while string.find(self.chr, pattern) do
        self:save_next()
    end
end

function Lexer:read_number()
    self.buff = ''
    self:nextc()
    self:read_chars('%d')
    local num = tonumber(self.buff)
    if not num then self:error('invalid number') end
    return num
end

function Lexer:read_hex()
    self.buff = ''
    if self.chr ~= '$' then self:nextc() end
    self:nextc()
    self:read_chars('%x')
    local num = tonumber(self.buff, 16)
    if not num then self:error('invalid hex number') end
    return num
end

function Lexer:read_binary()
    self.buff = ''
    self:nextc()
    self:read_chars('[01]')
    local num = tonumber(self.buff, 2)
    if not num then self:error('invalid binary number') end
    return num
end

function Lexer:skip_block_comment()
    self:nextc()
    self:nextc()
    while true do
        if self.ord == self.EOF then
            self:error('incomplete block comment')
        elseif self.chrchr == '*/' then
            self:nextc()
            self:nextc()
            break
        else
            self:nextc()
        end
    end
end

function Lexer:lex()
    while true do
        if self.chr == '\n' then
            self:nextc()
            return 'EOL', '\n'
        elseif self.ord == self.EOF then
            return 'EOF', self.EOF
        elseif self.chr == ';' then
            self:skip_to_EOL()
        elseif self.chrchr == '//' then
            self:skip_to_EOL()
        elseif self.chrchr == '/*' then
            self:skip_block_comment()
        elseif self.chr:find('%s') then
            self:nextc()
        elseif self.chr == '$' then
            return 'NUM', self:read_hex()
        elseif self.chr == '%' then
            return 'NUM', self:read_binary()
        elseif self.chr:find('%d') then
            -- TODO: check if cajaasm accepts 0X0
            if self.chr2 == 'x' or self.chr2 == 'X' then
                return 'NUM', self:read_hex()
            end
            return 'NUM', self:read_number()
        elseif self.chr == ',' then
            self:nextc()
            return 'SEP', ','
        elseif self.chr == '[' then
            self.buff = ''
            self:nextc()
            self:read_chars('[%w_]')
            if self.chr ~= ']' then
                self:error('invalid define name')
            end
            self:nextc()
            if self.chr ~= ':' then
                self:error('define requires a colon')
            end
            self:nextc()
            return 'DEF', self.buff
        elseif self.chr == '(' then
            self.buff = ''
            self:nextc()
            self:read_chars('[%w_]')
            if self.chr ~= ')' then
                self:error('invalid register name')
            end
            self:nextc()
            local up = self.buff:upper()
            if not all_registers[up] then
                self:error('not a register')
            end
            return 'DEREF', up
        elseif self.chr == '.' then
            self.buff = ''
            self:read_chars('[%w]')
            local up = self.buff:upper()
            if not all_directives[up] then
                self:error('not a directive')
            end
            if up == 'INC' or up == 'INCASM' or up == 'INCLUDE' then
                return 'DIR', 'UP'
            end
            return 'DIR', up
        elseif self.chr == '@' then
            self.buff = ''
            self:nextc()
            self:read_chars('[%w_]')
            return 'DEFSYM', self.buff
        elseif self.chr:find('[%a_]') then
            self.buff = ''
            -- now that we know we're looking at an identifier,
            -- we can start matching numbers and dots too.
            self:read_chars('[%w_.]')
            if self.chr == ':' then
                if self.buff:find('%.') then
                    self:error('labels cannot contain dots')
                end
                self:nextc()
                return 'LABEL', self.buff
            end
            local up = self.buff:upper()
            if up == 'HEX' then
                return 'DIR', up
            elseif all_registers[up] then
                return 'REG', up
            elseif all_instructions[up] then
                return 'INSTR', up:gsub('%.', '_')
            else
                if self.buff:find('%.') then
                    self:error('labels cannot contain dots')
                end
                return 'LABELSYM', self.buff
            end
        elseif self.chr == ']' then
            self:error('unmatched closing bracket')
        elseif self.chr == ')' then
            self:error('unmatched closing parenthesis')
        else
            self:error('unknown character or control character')
        end
    end
end

function Parser:error(msg)
    error(string.format('%s:%d: Error: %s', 'file.asm', self.line, msg), 2)
end

function Parser:advance()
    self.tt, self.tok = self.lexer:lex()
    self.line = self.lexer.line
    return self.tt, self.tok
end

function Parser:is_EOL()
    return self.tt == 'EOL' or self.tt == 'EOF'
end

function Parser:expect_EOL()
    if self:is_EOL() then
        self:advance()
        return
    end
    self:error('expected end of line')
end

function Parser:optional_comma()
    if self.tt == 'SEP' and self.tok == ',' then
        self:advance()
        return true
    end
end

function Parser:number()
    if self.tt ~= 'NUM' then
        self:error('expected number')
    end
    local value = self.tok
    self:advance()
    return value
end

function Parser:directive()
    local name = self.tok
    self:advance()
    if name == 'ORG' then
        self.dumper:add_directive(name, self:number())
    elseif name == 'ALIGN' or name == 'SKIP' then
        local size = self:number()
        if self:optional_comma() then
            self.dumper:add_directive(name, size, self:number())
        else
            self.dumper:add_directive(name, size)
        end
        self:expect_EOL()
    elseif name == 'BYTE' or name == 'HALFWORD' or name == 'WORD' then
        self.dumper:add_directive(name, self:number())
        while not self:is_EOL() do
            self:advance()
            self:optional_comma()
            self.dumper:add_directive(name, self:number())
        end
        self:expect_EOL()
    elseif name == 'HEX' then
        self:error('unimplemented')
    elseif name == 'INC' or name == 'INCBIN' then
        self:error('unimplemented')
    elseif name == 'FLOAT' or name == 'ASCII' or name == 'ASCIIZ' then
        self:error('unimplemented')
    else
        self:error('unknown directive')
    end
end

function Parser:register(t)
    t = t or registers
    if self.tt ~= 'REG' then
        if self.tt == 'NUM' and self.tok == '0' then
            -- i don't think cajeasm actually does this
            self.tt = 'REG'
            self.tok = 'R0'
        else
            self:error('expected register')
        end
    end
    local reg = self.tok
    if not t[reg] then
        self:error('wrong type of register')
    end
    self:advance()
    return reg
end

function Parser:deref()
    if self.tt ~= 'DEREF' then
        self:error('expected register to dereference')
    end
    local reg = self.tok
    self:advance()
    return reg
end

function Parser:const(relative)
    if self.tt ~= 'NUM' and self.tt ~= 'DEFSYM' and self.tt ~= 'LABELSYM' then
        self:error('expected constant')
    end
    if relative and self.tt == 'LABELSYM' then
        self.tt = 'LABELREL'
    end
    local t = {self.tt, self.tok}
    self:advance()
    return t
end

function Parser:instruction()
    local name = self.tok
    self:advance()
    local h = instruction_handlers[name]

    if h == nil then
        self:error('undefined instruction')
    elseif h[2] == argtypes.bto then
        -- OP rt, offset(base)
        local rt = self:register()
        self:optional_comma()
        local offset = {'LOWER', self:const()}
        local base = self:deref()
        self.dumper:add_instruction_5_5_16(h[1], base, rt, offset)
    elseif h[2] == argtypes.bfo then
        -- OP ft, offset(base)
        local ft = self:register(fpu_registers)
        self:optional_comma()
        local offset = {'LOWER', self:const()}
        local base = self:deref()
        self.dumper:add_instruction_5_5_16(h[1], base, ft, offset)
    elseif h[2] == argtypes.sti then
        -- OP rt, rs, immediate
        local rt = self:register()
        self:optional_comma()
        local rs = self:register()
        self:optional_comma()
        local immediate = {'LOWER', self:const()}
        self.dumper:add_instruction_5_5_16(h[1], rs, rt, immediate)
    elseif h[2] == argtypes.std then
        -- OP rd, rs, rt
        local rd = self:register()
        self:optional_comma()
        local rs = self:register()
        self:optional_comma()
        local rt = self:register()
        local const = h[3] or self:error('internal error: expected const')
        self.dumper:add_instruction_5_5_5_11(h[1], rs, rt, rd, const)
    elseif h[2] == argtypes.st then
        -- OP rs, rt
        local rs = self:register()
        self:optional_comma()
        local rt = self:register()
        local const = h[3] or self:error('internal error: expected const')
        self.dumper:add_instruction_5_5_16(h[1], rs, rt, const)
    elseif h[2] == argtypes.tds then
        local rd = self:register()
        self:optional_comma()
        local rt = self:register()
        self:optional_comma()
        local rs
        if name == 'DSRAV' or name == 'DSRLV' then
            -- OP rd, rt, rs
            rs = self:register()
        else
            -- OP rd, rt, sa
            rs = self:const()
        end
        local const = h[3] or self:error('internal error: expected const')
        self.dumper:add_instruction_5_5_5_5_6(h[1], 0, rt, rd, rs, const)
    elseif h[2] == argtypes.s then
        -- OP rs
        local rs = self:register()
        local const = h[3] or self:error('internal error: expected const')
        self.dumper:add_instruction_5_5_16(h[1], rs, 0, const)
    elseif h[2] == argtypes.sto then
        -- OP rs, rt, offset
        local rs = self:register()
        self:optional_comma()
        local rt = self:register()
        self:optional_comma()
        local offset = self:const('relative')
        self.dumper:add_instruction_5_5_16(h[1], rs, rt, offset)
    elseif h[2] == argtypes.stc then
        -- OP TEQ rs, rt
        local rs = self:register()
        self:optional_comma()
        local rt = self:register()
        local const = h[3] or self:error('internal error: expected const')
        -- FIXME: there's supposed to be 'code' before const
        -- but i dunno what it's supposed to be
        -- so i'm leaving it as zero here
        self.dumper:add_instruction_5_5_16(h[1], rs, rt, const)
    elseif h[2] == argtypes.so then
        -- OP rs, offset
        local rs = self:register()
        self:optional_comma()
        local offset = self:const('relative')
        local const = h[3] or self:error('internal error: expected const')
        self.dumper:add_instruction_5_5_16(h[1], rs, const, offset)
    elseif h[2] == argtypes.sync then
        -- OP
        local const = h[3] or self:error('internal error: expected const')
        self.dumper:add_instruction_26(h[1], const)
    elseif h[2] == argtypes.indx then
        -- OP target
        local target = {'INDEX', self:const()}
        self.dumper:add_instruction_26(h[1], target)
    elseif h[2] == argtypes.lui then
        -- OP rt, immediate
        local rt = self:register()
        self:optional_comma()
        local immediate = {'UPPER', self:const()}
        self.dumper:add_instruction_5_5_16(h[1], 0, rt, immediate)
    elseif h[2] == argtypes.mf then
        -- OP rd
        local rd = self:register()
        local const = h[3] or self:error('internal error: expected const')
        self.dumper:add_instruction_5_5_5_5_6(h[1], 0, 0, rd, 0, const)
    elseif h[2] == argtypes.jalr then
        -- OP rs, rd
        local rs = self:register()
        self:optional_comma()
        local rd = self:register()
        local const = h[3] or self:error('internal error: expected const')
        self.dumper:add_instruction_5_5_5_5_6(h[1], rs, 0, rd, 0, const)
        local rd = self:register()
    elseif h[2] == argtypes.code then
        -- OP
        local const = h[3] or self:error('internal error: expected const')
        self.dumper:add_instruction_26(h[1], const)
    elseif h[2] == argtypes.movf then
        local rt = self:register()
        self:optional_comma()
        local rd = nil
        if name == 'MFC0' or name == 'MTC0' then
            -- OP rt, rd
            rd = self:register()
        else
            -- OP rt, fs
            rd = self:register(fpu_registers)
        end
        local const = h[3] or self:error('internal error: expected const')
        self.dumper:add_instruction_5_5_5_5_6(h[1], const, rt, rd, 0, 0)
    elseif h[2] == argtypes.tsdf then
        -- OP fd, fs, ft
        local fd = self:register(fpu_registers)
        self:optional_comma()
        local fs = self:register(fpu_registers)
        self:optional_comma()
        local ft = self:register(fpu_registers)
        local const = h[3] or self:error('internal error: expected const')
        self.dumper:add_instruction_5_5_5_5_6(h[1], 16, ft, fs, fd, const)
    elseif h[2] == argtypes.tsdd then
        local fd = self:register(fpu_registers)
        self:optional_comma()
        local fs = self:register(fpu_registers)
        self:optional_comma()
        local ft = self:register(fpu_registers)
        local const = h[3] or self:error('internal error: expected const')
        self.dumper:add_instruction_5_5_5_5_6(h[1], 17, ft, fs, fd, const)
    else
        self:error('TODO')
    end
    self:expect_EOL()
end

function Parser:parse(asm)
    self.asm = asm
    self.lexer = Lexer(asm)

    self:advance()
    while self.tt ~= 'EOF' do
        if self.tt == 'EOL' then
            -- empty line
            self:advance()
        elseif self.tt == 'DEF' then
            local name = self.tok
            self:advance()
            self.dumper:add_define(name, self:number())
        elseif self.tt == 'DIR' then
            self:directive()
        elseif self.tt == 'LABEL' then
            self.dumper:add_label(self.tok)
            self:advance()
        elseif self.tt == 'INSTR' then
            self:instruction()
        else
            self:error('unexpected token (unknown instruction?)')
        end
    end

    return self.dumper:dump()
end

function Dumper:error(msg)
    -- TODO: sometimes internal error, sometimes not.
    --       also, we should pass line numbers down to add_instruction.
    error(string.format('Dumping Error: %s', msg), 2)
end

function Dumper:push(t)
    --print(t.data)
    table.insert(self.lines, t)
end

function Dumper:add_instruction_26(i, a)
    local t = {}
    t.sizes = {26}
    t.data = {i, a}
    self:push(t)
end

function Dumper:add_instruction_5_5_16(i, a, b, c)
    local t = {}
    t.sizes = {5, 5, 16}
    t.data = {i, a, b, c}
    self:push(t)
end

function Dumper:add_instruction_5_5_5_11(i, a, b, c, d)
    local t = {}
    t.sizes = {5, 5, 5, 11}
    t.data = {i, a, b, c, d}
    self:push(t)
end

function Dumper:add_instruction_5_5_5_5_6(i, a, b, c, d, e)
    local t = {}
    t.sizes = {5, 5, 5, 5, 6}
    t.data = {i, a, b, c, d, e}
    self:push(t)
end

function Dumper:add_define(name, number)
    self.defines[name] = number
end

function Dumper:add_label(name)
    self.labels[name] = #self.lines + 1
end

function Dumper:add_directive(...)
    self:error('unimplemented directive')
end

function Dumper:print(uw, lw)
    self.writer(('%04X%04X'):format(uw, lw))
end

function Dumper:desym(tok)
    if type(tok[2]) == 'number' then
        return tok[2]
    elseif all_registers[tok] then
        return registers[tok] or fpu_registers[tok]
    elseif tok[1] == 'LABELSYM' then
        --print('(label)', tok[2])
        return self.labels[tok[2]]*4
    elseif tok[1] == 'LABELREL' then
        local rel = self.labels[tok[2]] - 2 - self.line
        if rel > 0x8000 or rel <= -0x8000 then
            self:error('branch too far')
        end
        return (0x10000 + rel) % 0x10000
    elseif tok[1] == 'DEFSYM' then
        --print('(define)')
        local val = self.defines[tok[2]]
        if val == nil then
            self:error('unknown define')
        end
        return val
    end
    --print(tok)
    self:error('failed to desym')
end

function Dumper:toval(tok)
    if tok == nil then
        self:error('nil value')
    elseif type(tok) == 'number' then
        return tok
    elseif all_registers[tok] then
        return registers[tok] or fpu_registers[tok]
    end
    if type(tok) == 'table' then
        if #tok ~= 2 then
            --print('toval', tok)
            self:error('invalid token')
        end
        if tok[1] == 'UPPER' then
            local val = self:desym(tok[2])
            while val >= 0x10000 do
                val = val/2
            end
            return val
        elseif tok[1] == 'LOWER' then
            local val = self:desym(tok[2]) % 0x10000
            return val
        elseif tok[1] == 'INDEX' then
            local val
            if type(tok[2]) == 'table' and tok[2][1] == 'LABELSYM' then
                -- don't multiply by 4 twice
                val = self:desym(tok[2])
            else
                val = self:desym(tok[2])*4
            end
            --print('(index)', val)
            return val
        else
            return self:desym(tok)
        end
    end
    --print('toval', tok)
    self:error('invalid value')
end

function Dumper:validate(n, bits)
    local max = 2^bits
    if n == nil then
        self:error('value is nil')
    end
    if n > max or n < 0 then
        --print(("n %08X"):format(math.abs(n)))
        self:error('value out of range')
    end
end

function Dumper:valvar(tok, bits)
    local val = self:toval(tok)
    self:validate(val, bits)
    return val
end

function Dumper:dump()
    for i, t in ipairs(self.lines) do
        self.line = i
        local uw = 0
        local lw = 0
        local val = nil

        local i = t.data[1]
        uw = uw + i*0x400

        if #t.sizes == 1 then
            if t.sizes[1] == 26 then
                val = self:valvar(t.data[2], 26)
                uw = uw + math.floor(val/0x10000)
                lw = lw + val % 0x10000
            else
                self:error('bad 1-size')
            end
        elseif #t.sizes == 3 then
            if t.sizes[1] == 5 and t.sizes[2] == 5 and t.sizes[3] == 16 then
                val = self:valvar(t.data[2], 5)
                uw = uw + val*0x20
                val = self:valvar(t.data[3], 5)
                uw = uw + val
                val = self:valvar(t.data[4], 16)
                lw = lw + val
            else
                self:error('bad 3-size')
            end
        elseif #t.sizes == 4 then
            if t.sizes[1] == 5 and t.sizes[2] == 5 and t.sizes[3] == 5 and t.sizes[4] == 11 then
                val = self:valvar(t.data[2], 5)
                uw = uw + val*0x20
                val = self:valvar(t.data[3], 5)
                uw = uw + val
                val = self:valvar(t.data[4], 5)
                lw = lw + val*0x800
                val = self:valvar(t.data[5], 11)
                lw = lw + val
            else
                self:error('bad 4-size')
            end
        elseif #t.sizes == 5 then
            if t.sizes[1] == 5 and t.sizes[2] == 5 and t.sizes[3] == 5 and t.sizes[4] == 5 and t.sizes[5] == 6 then
                val = self:valvar(t.data[2], 5)
                uw = uw + val*0x20
                val = self:valvar(t.data[3], 5)
                uw = uw + val
                val = self:valvar(t.data[4], 5)
                lw = lw + val*0x800
                val = self:valvar(t.data[5], 5)
                lw = lw + val*0x40
                val = self:valvar(t.data[6], 6)
                lw = lw + val
            else
                self:error('bad 5-size')
            end
        else
            self:error('unknown n-size')
        end

        self:print(uw, lw)
    end
end

function assemble(fn, writer)
    -- assemble a MIPS R4300i assembly file
    -- returns error message on error, or nil on success
    writer = writer or io.write

    local asm = ''
    local f = io.open(fn, 'r')
    if not f then
        error('could not read assembly file', 1)
    end
    asm = f:read('*a')
    f:close()

    function main()
        local p = Parser(writer)
        return p:parse(asm)
    end

    local ok, err = pcall(main)
    return err
end
