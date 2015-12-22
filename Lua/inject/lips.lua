-- lips.lua

local assembler = {
    _DESCRIPTION = 'Assembles MIPS assembly files for the R4300i CPU.',
    _URL = 'https://github.com/notwa/lips/',
    _LICENSE = [[
        Copyright (C) 2015 Connor Olding

        This program is licensed under the terms of the MIT License, and
        is distributed without any warranty.  You should have received a
        copy of the license along with this program; see the file LICENSE.
    ]],
}

local floor = math.floor

local Class = function(inherit)
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

local function bitrange(x, lower, upper)
    return floor(x/2^lower) % 2^(upper - lower + 1)
end

local function readfile(fn)
    local f = io.open(fn, 'r')
    if not f then
        error('could not open assembly file for reading: '..tostring(fn), 2)
    end
    local asm = f:read('*a')
    f:close()
    return asm
end

local registers = {
    [0]=
    'R0', 'AT', 'V0', 'V1', 'A0', 'A1', 'A2', 'A3',
    'T0', 'T1', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7',
    'S0', 'S1', 'S2', 'S3', 'S4', 'S5', 'S6', 'S7',
    'T8', 'T9', 'K0', 'K1', 'GP', 'SP', 'FP', 'RA',
}

local fpu_registers = {
    [0]=
    'F0',  'F1',  'F2',  'F3',  'F4',  'F5',  'F6',  'F7',
    'F8',  'F9',  'F10', 'F11', 'F12', 'F13', 'F14', 'F15',
    'F16', 'F17', 'F18', 'F19', 'F20', 'F21', 'F22', 'F23',
    'F24', 'F25', 'F26', 'F27', 'F28', 'F29', 'F30', 'F31',
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
revtable(all_directives)

registers['ZERO'] = 0
all_registers['ZERO'] = 0
registers['S8'] = 30
all_registers['S8'] = 30

for i=0, 31 do
    local r = 'REG'..tostring(i)
    registers[r] = i
    all_registers[r] = i
end

local fmt_single = 16
local fmt_double = 17
local fmt_word = 20
local fmt_long = 21

local instructions = {
    --[[
    data guide:
    --INSTRUCTION_NAME = {opcode, infmt, outfmt, const, fmtconst},
    underscores are translated to dots later.
    opcode: the first 6 bits of the instruction.
    infmt: the input format; one character per argument.
    outfmt: the output format: R-, I-, and J-types are inferred by length.
    const: (optional) the number to replace 'C' with in outfmt.
    fmtconst: (optional) the number to replace 'F' with in outfmt.

    input format guide:
        such and such: expects a...
        d:  register for rd
        s:  register for rs
        t:  register for rt
        D:  floating point register for fd
        S:  floating point register for fs
        T:  floating point register for ft
        o:  constant for offset
        b:  register to dereference for base
        r:  relative constant or label for offset
        I:  constant or label for index (long jump)
        i:  immediate (must fit in a halfword; cannot be a label)
        k:  immediate to negate (must fit in a halfword; cannot be a label)
        K:  signed immediate (-0x8000 <= immediate < 0x10000; cannot be a label)

    output format guide:
        such and such: writes ... at this position
        0:  zero (sometimes used to refer to R0)
        d:  rd
        s:  rs
        t:  rt
        D:  fd
        S:  fs
        T:  ft
        o:  offset
        b:  base
        i:  immediate (infmt 'i' and 'k' both write to here)
        I:  index
        C:  constant (given in argument immediately after)
        F:  format constant (given in argument after constant)
    --]]

    J       = {2, 'I', 'I'},
    JAL     = {3, 'I', 'I'},

    JALR    = {0, 'sd', 's0d0C', 9},

    MTHI    = {0, 's', 's000C', 17},
    MTLO    = {0, 's', 's000C', 19},
    JR      = {0, 's', 's000C',  8},

    BREAK   = {0, '', '0000C', 13},
    SYSCALL = {0, '', '0000C', 12},

    SYNC    = {0, '', '0000C', 15},

    LB      = {32, 'tob', 'bto'},
    LBU     = {36, 'tob', 'bto'},
    LD      = {55, 'tob', 'bto'},
    LDL     = {26, 'tob', 'bto'},
    LDR     = {27, 'tob', 'bto'},
    LH      = {33, 'tob', 'bto'},
    LHU     = {37, 'tob', 'bto'},
    LL      = {48, 'tob', 'bto'},
    LLD     = {52, 'tob', 'bto'},
    LW      = {35, 'tob', 'bto'},
    LWL     = {34, 'tob', 'bto'},
    LWR     = {38, 'tob', 'bto'},
    LWU     = {39, 'tob', 'bto'},
    SB      = {40, 'tob', 'bto'},
    SC      = {56, 'tob', 'bto'},
    SCD     = {60, 'tob', 'bto'},
    SD      = {63, 'tob', 'bto'},
    SDL     = {44, 'tob', 'bto'},
    SDR     = {45, 'tob', 'bto'},
    SH      = {41, 'tob', 'bto'},
    SW      = {43, 'tob', 'bto'},
    SWL     = {42, 'tob', 'bto'},
    SWR     = {46, 'tob', 'bto'},

    LUI     = {15, 'ti', '0ti'},

    MFHI    = {0, 'd', '00d0C', 16},
    MFLO    = {0, 'd', '00d0C', 18},

    ADDI    = { 8, 'tsK', 'sti'},
    ADDIU   = { 9, 'tsK', 'sti'},
    ANDI    = {12, 'tsK', 'sti'},
    DADDI   = {24, 'tsK', 'sti'},
    DADDIU  = {25, 'tsK', 'sti'},
    ORI     = {13, 'tsi', 'sti'},
    SLTI    = {10, 'tsi', 'sti'},
    SLTIU   = {11, 'tsi', 'sti'},
    XORI    = {14, 'tsi', 'sti'},

    ADD     = {0, 'dst', 'std0C', 32},
    ADDU    = {0, 'dst', 'std0C', 33},
    AND     = {0, 'dst', 'std0C', 36},
    DADD    = {0, 'dst', 'std0C', 44},
    DADDU   = {0, 'dst', 'std0C', 45},
    DSLLV   = {0, 'dst', 'std0C', 20},
    DSUB    = {0, 'dst', 'std0C', 46},
    DSUBU   = {0, 'dst', 'std0C', 47},
    NOR     = {0, 'dst', 'std0C', 39},
    OR      = {0, 'dst', 'std0C', 37},
    SLLV    = {0, 'dst', 'std0C',  4},
    SLT     = {0, 'dst', 'std0C', 42},
    SLTU    = {0, 'dst', 'std0C', 43},
    SRAV    = {0, 'dst', 'std0C',  7},
    SRLV    = {0, 'dst', 'std0C',  6},
    SUB     = {0, 'dst', 'std0C', 34},
    SUBU    = {0, 'dst', 'std0C', 35},
    XOR     = {0, 'dst', 'std0C', 38},

    DDIV    = {0, 'st', 'st00C', 30},
    DDIVU   = {0, 'st', 'st00C', 31},
    DIV     = {0, 'st', 'st00C', 26},
    DIVU    = {0, 'st', 'st00C', 27},
    DMULT   = {0, 'st', 'st00C', 28},
    DMULTU  = {0, 'st', 'st00C', 29},
    MULT    = {0, 'st', 'st00C', 24},
    MULTU   = {0, 'st', 'st00C', 25},

    DSLL    = {0, 'dti', '0tdiC', 56},
    DSLL32  = {0, 'dti', '0tdiC', 60},
    DSRA    = {0, 'dti', '0tdiC', 59},
    DSRA32  = {0, 'dti', '0tdiC', 63},
    DSRAV   = {0, 'dts', '0tdsC', 23},
    DSRL    = {0, 'dti', '0tdiC', 58},
    DSRL32  = {0, 'dti', '0tdiC', 62},
    DSRLV   = {0, 'dts', '0tdsC', 22},
    SLL     = {0, 'dti', '0tdiC',  0},
    SRA     = {0, 'dti', '0tdiC',  3},
    SRL     = {0, 'dti', '0tdiC',  2},

    BEQ     = { 4, 'str', 'sto'},
    BEQL    = {20, 'str', 'sto'},
    BNE     = { 5, 'str', 'sto'},
    BNEL    = {21, 'str', 'sto'},

    BGEZ    = { 1, 'sr', 'sCo',  1},
    BGEZAL  = { 1, 'sr', 'sCo', 17},
    BGEZALL = { 1, 'sr', 'sCo', 19},
    BGEZL   = { 1, 'sr', 'sCo',  3},
    BGTZ    = { 7, 'sr', 'sCo',  0},
    BGTZL   = {23, 'sr', 'sCo',  0},
    BLEZ    = { 6, 'sr', 'sCo',  0},
    BLEZL   = {22, 'sr', 'sCo',  0},
    BLTZ    = { 1, 'sr', 'sCo',  0},
    BLTZAL  = { 1, 'sr', 'sCo', 16},
    BLTZALL = { 1, 'sr', 'sCo', 18},
    BLTZL   = { 1, 'sr', 'sCo',  2},

    TEQ     = {0, 'st', 'st00C', 52},
    TGE     = {0, 'st', 'st00C', 48},
    TGEU    = {0, 'st', 'st00C', 49},
    TLT     = {0, 'st', 'st00C', 50},
    TLTU    = {0, 'st', 'st00C', 51},
    TNE     = {0, 'st', 'st00C', 54},

    ADD_D   = {17, 'DST', 'FTSDC', 0, fmt_double},
    ADD_S   = {17, 'DST', 'FTSDC', 0, fmt_single},
    DIV_D   = {17, 'DST', 'FTSDC', 3, fmt_double},
    DIV_S   = {17, 'DST', 'FTSDC', 3, fmt_single},
    MUL_D   = {17, 'DST', 'FTSDC', 2, fmt_double},
    MUL_S   = {17, 'DST', 'FTSDC', 2, fmt_single},
    SUB_D   = {17, 'DST', 'FTSDC', 1, fmt_double},
    SUB_S   = {17, 'DST', 'FTSDC', 1, fmt_single},

    CFC1    = {17, 'tS', 'CtS00', 2},
    CTC1    = {17, 'tS', 'CtS00', 6},
    DMFC1   = {17, 'tS', 'CtS00', 1},
    DMTC1   = {17, 'tS', 'CtS00', 5},
    MFC0    = {16, 'tS', 'CtS00', 0},
    MFC1    = {17, 'tS', 'CtS00', 0},
    MTC0    = {16, 'tS', 'CtS00', 4},
    MTC1    = {17, 'tS', 'CtS00', 4},

    LDC1    = {53, 'Tob', 'bTo'},
    LWC1    = {49, 'Tob', 'bTo'},
    SDC1    = {61, 'Tob', 'bTo'},
    SWC1    = {57, 'Tob', 'bTo'},

    C_EQ_D  = {17, 'ST', 'FTS0C', 50, fmt_double},
    C_EQ_S  = {17, 'ST', 'FTS0C', 50, fmt_single},
    C_F_D   = {17, 'ST', 'FTS0C', 48, fmt_double},
    C_F_S   = {17, 'ST', 'FTS0C', 48, fmt_single},
    C_LE_D  = {17, 'ST', 'FTS0C', 62, fmt_double},
    C_LE_S  = {17, 'ST', 'FTS0C', 62, fmt_single},
    C_LT_D  = {17, 'ST', 'FTS0C', 60, fmt_double},
    C_LT_S  = {17, 'ST', 'FTS0C', 60, fmt_single},
    C_NGE_D = {17, 'ST', 'FTS0C', 61, fmt_double},
    C_NGE_S = {17, 'ST', 'FTS0C', 61, fmt_single},
    C_NGL_D = {17, 'ST', 'FTS0C', 59, fmt_double},
    C_NGL_S = {17, 'ST', 'FTS0C', 59, fmt_single},
    C_NGLE_D= {17, 'ST', 'FTS0C', 57, fmt_double},
    C_NGLE_S= {17, 'ST', 'FTS0C', 57, fmt_single},
    C_NGT_D = {17, 'ST', 'FTS0C', 63, fmt_double},
    C_NGT_S = {17, 'ST', 'FTS0C', 63, fmt_single},
    C_OLE_D = {17, 'ST', 'FTS0C', 54, fmt_double},
    C_OLE_S = {17, 'ST', 'FTS0C', 54, fmt_single},
    C_OLT_D = {17, 'ST', 'FTS0C', 52, fmt_double},
    C_OLT_S = {17, 'ST', 'FTS0C', 52, fmt_single},
    C_SEQ_D = {17, 'ST', 'FTS0C', 58, fmt_double},
    C_SEQ_S = {17, 'ST', 'FTS0C', 58, fmt_single},
    C_SF_D  = {17, 'ST', 'FTS0C', 56, fmt_double},
    C_SF_S  = {17, 'ST', 'FTS0C', 56, fmt_single},
    C_UEQ_D = {17, 'ST', 'FTS0C', 51, fmt_double},
    C_UEQ_S = {17, 'ST', 'FTS0C', 51, fmt_single},
    C_ULE_D = {17, 'ST', 'FTS0C', 55, fmt_double},
    C_ULE_S = {17, 'ST', 'FTS0C', 55, fmt_single},
    C_ULT_D = {17, 'ST', 'FTS0C', 53, fmt_double},
    C_ULT_S = {17, 'ST', 'FTS0C', 53, fmt_single},
    C_UN_D  = {17, 'ST', 'FTS0C', 49, fmt_double},
    C_UN_S  = {17, 'ST', 'FTS0C', 49, fmt_single},

    CVT_D_L = {17, 'DS', 'F0SDC', 33, fmt_long},
    CVT_D_S = {17, 'DS', 'F0SDC', 33, fmt_single},
    CVT_D_W = {17, 'DS', 'F0SDC', 33, fmt_word},
    CVT_L_D = {17, 'DS', 'F0SDC', 37, fmt_double},
    CVT_L_S = {17, 'DS', 'F0SDC', 37, fmt_single},
    CVT_S_D = {17, 'DS', 'F0SDC', 32, fmt_double},
    CVT_S_L = {17, 'DS', 'F0SDC', 32, fmt_long},
    CVT_S_W = {17, 'DS', 'F0SDC', 32, fmt_word},
    CVT_W_D = {17, 'DS', 'F0SDC', 36, fmt_double},
    CVT_W_S = {17, 'DS', 'F0SDC', 36, fmt_single},

    ABS_D   = {17, 'DS', 'F0SDC',  5, fmt_double},
    ABS_S   = {17, 'DS', 'F0SDC',  5, fmt_single},
    CEIL_L_D= {17, 'DS', 'F0SDC', 10, fmt_double},
    CEIL_L_S= {17, 'DS', 'F0SDC', 10, fmt_single},
    CEIL_W_D= {17, 'DS', 'F0SDC', 14, fmt_double},
    CEIL_W_S= {17, 'DS', 'F0SDC', 14, fmt_single},
    FLOOR_L_D={17, 'DS', 'F0SDC', 11, fmt_double},
    FLOOR_L_S={17, 'DS', 'F0SDC', 11, fmt_single},
    FLOOR_W_D={17, 'DS', 'F0SDC', 15, fmt_double},
    FLOOR_W_S={17, 'DS', 'F0SDC', 15, fmt_single},
    MOV_D   = {17, 'DS', 'F0SDC',  6, fmt_double},
    MOV_S   = {17, 'DS', 'F0SDC',  6, fmt_single},
    NEG_D   = {17, 'DS', 'F0SDC',  7, fmt_double},
    NEG_S   = {17, 'DS', 'F0SDC',  7, fmt_single},
    ROUND_L_D={17, 'DS', 'F0SDC',  8, fmt_double},
    ROUND_L_S={17, 'DS', 'F0SDC',  8, fmt_single},
    ROUND_W_D={17, 'DS', 'F0SDC', 12, fmt_double},
    ROUND_W_S={17, 'DS', 'F0SDC', 12, fmt_single},
    SQRT_D  = {17, 'DS', 'F0SDC',  4, fmt_double},
    SQRT_S  = {17, 'DS', 'F0SDC',  4, fmt_single},
    TRUNC_L_D={17, 'DS', 'F0SDC',  9, fmt_double},
    TRUNC_L_S={17, 'DS', 'F0SDC',  9, fmt_single},
    TRUNC_W_D={17, 'DS', 'F0SDC', 13, fmt_double},
    TRUNC_W_S={17, 'DS', 'F0SDC', 13, fmt_double},

    TEQI    = {1, 'si', 'sCi', 12},
    TGEI    = {1, 'si', 'sCi',  8},
    TGEIU   = {1, 'si', 'sCi',  9},
    TLTI    = {1, 'si', 'sCi', 10},
    TLTIU   = {1, 'si', 'sCi', 11},
    TNEI    = {1, 'si', 'sCi', 14},

    -- immediate limited to 3 bits?
    CACHE   = {47, 'iob', 'bio'},

    -- misuses 'F' to write the initial bit
    ERET    = {16, '', 'F000C', 24, 16},
    TLBP    = {16, '', 'F000C',  8, 16},
    TLBR    = {16, '', 'F000C',  1, 16},
    TLBWI   = {16, '', 'F000C',  2, 16},
    TLBWR   = {16, '', 'F000C',  6, 16},

    -- only one condition code on the R4300i?
    BC1F    = {17, 'r', 'FCo', 0, 8},
    BC1FL   = {17, 'r', 'FCo', 2, 8},
    BC1T    = {17, 'r', 'FCo', 1, 8},
    BC1TL   = {17, 'r', 'FCo', 3, 8},

    -- pseudo-instructions
    B       = {4, 'r', '00o'},          -- BEQ R0, R0, offset
    BAL     = {1, 'r', '0Co', 17},      -- BGEZAL R0, offset
    CL      = {0, 'd', '00d0C', 32},    -- ADD RD, R0, R0
    MOV     = {0, 'dt', '0td0C', 32},   -- ADD RD, R0, RT
    MOVE    = {0, 'dt', '0td0C', 32},   -- ADD RD, R0, RT
    NEG     = {0, 'dt', '0td0C', 34},   -- SUB RD, R0, RT
    NOP     = {0, '', '0'},             -- SLL R0, R0, 0
    NOT     = {0, 'ds', 's0d0C', 39},   -- NOR RD, RS, R0
    SUBI    = {8, 'tsk', 'sti'},        -- ADDI RT, RS, -immediate
    SUBIU   = {9, 'tsk', 'sti'},        -- ADDIU RT, RS, -immediate

    -- ...that expand to multiple instructions
    LI      = 'LI', -- only one instruction for values < 0x10000
    LA      = 'LA',

    -- variable arguments
    PUSH    = 'PUSH',
    POP     = 'POP',
    JPOP    = 'JPOP',

    ABS     = {}, -- BGEZ NOP SUB?
    MUL     = {}, -- MULT MFLO
    --DIV     = {}, -- 3 arguments
    REM     = {}, -- 3 arguments

    NAND    = 'NAND', -- AND, NOT
    NANDI   = 'NANDI', -- ANDI, NOT
    NORI    = 'NORI', -- ORI, NOT
    ROL     = 'ROL', -- SLL, SRL, OR
    ROR     = 'ROR', -- SRL, SLL, OR

    SEQ     = {},
    SEQI    = {},
    SEQIU   = {},
    SEQU    = {},
    SGE     = {},
    SGEI    = {},
    SGEIU   = {},
    SGEU    = {},
    SGT     = {},
    SGTI    = {},
    SGTIU   = {},
    SGTU    = {},
    SLE     = {},
    SLEI    = {},
    SLEIU   = {},
    SLEU    = {},
    SNE     = {},
    SNEI    = {},
    SNEIU   = {},
    SNEU    = {},

    BEQI    = {},
    BNEI    = {},
    BGE     = {},
    BGEI    = {},
    BLE     = {},
    BLEI    = {},
    BLT     = {},
    BLTI    = {},
    BGT     = {},
    BGTI    = {},
}

local all_instructions = {}
local i = 1
for k, v in pairs(instructions) do
    all_instructions[k:gsub('_', '.')] = i
    i = i + 1
end
revtable(all_instructions)

local Lexer = Class()
function Lexer:init(asm, fn, options)
    self.asm = asm
    self.fn = fn or '(string)'
    self.options = options or {}
    self.pos = 1
    self.line = 1
    self.EOF = -1
    self:nextc()
end

local Dumper = Class()
function Dumper:init(writer, fn, options)
    self.writer = writer
    self.fn = fn or '(string)'
    self.options = options or {}
    self.labels = {}
    self.commands = {}
    self.pos = options.offset or 0
    self.lastcommand = nil
end

local Parser = Class()
function Parser:init(writer, fn, options)
    self.fn = fn or '(string)'
    self.main_fn = self.fn
    self.options = options or {}
    self.dumper = Dumper(writer, fn, options)
    self.defines = {}
end

function Lexer:error(msg)
    error(string.format('%s:%d: Error: %s', self.fn, self.line, msg), 2)
end

function Lexer:nextc()
    if self.pos > #self.asm then
        self.ord = self.EOF
        self.ord2 = self.EOF
        self.chr = ''
        self.chr2 = ''
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
        self.ord2 = self.EOF
        self.chr2 = ''
        self.chrchr = self.chr
    end
end

function Lexer:skip_to_EOL()
    while self.chr ~= '\n' and self.ord ~= self.EOF do
        self:nextc()
    end
end

function Lexer:read_chars(pattern)
    local buff = ''
    while string.find(self.chr, pattern) do
        buff = buff..self.chr
        self:nextc()
    end
    return buff
end

function Lexer:read_decimal()
    local buff = self:read_chars('%d')
    local num = tonumber(buff)
    if not num then self:error('invalid decimal number') end
    return num
end

function Lexer:read_hex()
    local buff = self:read_chars('%x')
    local num = tonumber(buff, 16)
    if not num then self:error('invalid hex number') end
    return num
end

function Lexer:read_octal()
    local buff = self:read_chars('[0-7]')
    local num = tonumber(buff)
    if not num then self:error('invalid octal number') end
    return num
end

function Lexer:read_binary()
    local buff = self:read_chars('[01]')
    local num = tonumber(buff, 2)
    if not num then self:error('invalid binary number') end
    return num
end

function Lexer:read_number()
    if self.chr == '%' then
        self:nextc()
        return self:read_binary()
    elseif self.chr == '$' then
        self:nextc()
        return self:read_hex()
    elseif self.chr:find('%d') then
        if self.chr2 == 'x' or self.chr2 == 'X' then
            self:nextc()
            self:nextc()
            return self:read_hex()
        elseif self.chr == '0' and self.chr2:find('%d') then
            self:nextc()
            return self:read_octal()
        else
            return self:read_decimal()
        end
    elseif self.chr == '#' then
        self:nextc()
        return self:read_decimal()
    end
end

function Lexer:lex_hex(yield)
    local hexmatch = '[0-9A-Fa-f]'
    local entered = false
    while true do
        if self.chr == '\n' then
            self:nextc()
            yield('EOL', '\n')
        elseif self.ord == self.EOF then
            self:error('unexpected EOF; incomplete hex directive')
        elseif self.chr == ';' then
            self:skip_to_EOL()
        elseif self.chrchr == '//' then
            self:skip_to_EOL()
        elseif self.chrchr == '/*' then
            self:nextc()
            self:nextc()
            self:lex_block_comment(yield)
        elseif self.chr:find('%s') then
            self:nextc()
        elseif self.chr == '{' then
            if entered then
                self:error('unexpected opening brace')
            end
            self:nextc()
            entered = true
        elseif self.chr == '}' then
            if not entered then
                self:error('expected opening brace')
            end
            self:nextc()
            break
        elseif self.chr == ',' then
            self:error('commas are not allowed in HEX directives')
        elseif self.chr:find(hexmatch) and self.chr2:find(hexmatch) then
            local num = tonumber(self.chrchr, 16)
            self:nextc()
            self:nextc()
            if self.chr:find(hexmatch) then
                self:error('too many hex digits to be a single byte')
            end
            yield('DIR', 'BYTE')
            yield('NUM', num)
        elseif self.chr:find(hexmatch) then
            self:error('expected two hex digits to make a byte')
        else
            if entered then
                self:error('expected bytes given in hex or closing brace')
            else
                self:error('expected opening brace')
            end
        end
    end
end

function Lexer:lex_block_comment(yield)
    while true do
        if self.chr == '\n' then
            self:nextc()
            yield('EOL', '\n')
        elseif self.ord == self.EOF then
            self:error('unexpected EOF; incomplete block comment')
        elseif self.chrchr == '*/' then
            self:nextc()
            self:nextc()
            break
        else
            self:nextc()
        end
    end
end

function Lexer:lex_string(yield)
    -- TODO: support escaping
    if self.chr ~= '"' then
        self:error("expected opening double quote")
    end
    self:nextc()
    local buff = self:read_chars('[^"\n]')
    if self.chr ~= '"' then
        self:error("expected closing double quote")
    end
    self:nextc()
    yield('STRING', buff)
end

function Lexer:lex_include(_yield)
    self:read_chars('%s')
    local fn
    self:lex_string(function(tt, tok)
        fn = tok
    end)
    if self.options.path then
        fn = self.options.path..fn
    end
    local sublexer = Lexer(readfile(fn), fn, self.options)
    sublexer:lex(_yield)
end

function Lexer:lex(_yield)
    local function yield(tt, tok)
        return _yield(tt, tok, self.fn, self.line)
    end
    while true do
        if self.chr == '\n' then
            self:nextc()
            yield('EOL', '\n')
        elseif self.ord == self.EOF then
            yield('EOF', self.EOF)
            break
        elseif self.chr == ';' then
            self:skip_to_EOL()
        elseif self.chrchr == '//' then
            self:skip_to_EOL()
        elseif self.chrchr == '/*' then
            self:nextc()
            self:nextc()
            self:lex_block_comment(yield)
        elseif self.chr:find('%s') then
            self:nextc()
        elseif self.chr == ',' then
            self:nextc()
            yield('SEP', ',')
        elseif self.chr == '[' then
            self:nextc()
            local buff = self:read_chars('[%w_]')
            if self.chr ~= ']' then
                self:error('invalid define name')
            end
            self:nextc()
            if self.chr ~= ':' then
                self:error('define requires a colon')
            end
            self:nextc()
            yield('DEF', buff)
        elseif self.chr == '(' then
            self:nextc()
            local buff = self:read_chars('[%w_]')
            if self.chr ~= ')' then
                self:error('invalid register name')
            end
            self:nextc()
            local up = buff:upper()
            if not all_registers[up] then
                self:error('not a register')
            end
            yield('DEREF', up)
        elseif self.chr == '.' then
            self:nextc()
            local buff = self:read_chars('[%w]')
            local up = buff:upper()
            if not all_directives[up] then
                self:error('not a directive')
            end
            if up == 'INC' or up == 'INCASM' or up == 'INCLUDE' then
                yield('DIR', 'INC')
                self:lex_include(_yield)
            else
                yield('DIR', up)
            end
        elseif self.chr == '@' then
            self:nextc()
            local buff = self:read_chars('[%w_]')
            yield('DEFSYM', buff)
        elseif self.chr:find('[%a_]') then
            local buff = self:read_chars('[%w_.]')
            local up = buff:upper()
            if self.chr == ':' then
                if buff:find('%.') then
                    self:error('labels cannot contain dots')
                end
                self:nextc()
                yield('LABEL', buff)
            elseif up == 'HEX' then
                self:lex_hex(yield)
            elseif all_registers[up] then
                yield('REG', up)
            elseif all_instructions[up] then
                yield('INSTR', up:gsub('%.', '_'))
            else
                if buff:find('%.') then
                    self:error('labels cannot contain dots')
                end
                yield('LABELSYM', buff)
            end
        elseif self.chr == ']' then
            self:error('unmatched closing bracket')
        elseif self.chr == ')' then
            self:error('unmatched closing parenthesis')
        elseif self.chr == '-' then
            self:nextc()
            local n = self:read_number()
            if n then
                yield('NUM', -n)
            else
                self:error('expected number after minus sign')
            end
        else
            local n = self:read_number()
            if n then
                yield('NUM', n)
            else
                self:error('unknown character or control character')
            end
        end
    end
end

function Parser:error(msg)
    error(string.format('%s:%d: Error: %s', self.fn, self.line, msg), 2)
end

function Parser:advance()
    self.i = self.i + 1
    local t = self.tokens[self.i]
    self.tt = t.tt
    self.tok = t.tok
    self.fn = t.fn
    self.line = t.line
    return t.tt, t.tok
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
    local line = self.line
    if name == 'ORG' then
        self.dumper:add_directive(line, name, self:number())
    elseif name == 'ALIGN' or name == 'SKIP' then
        if self:is_EOL() and name == 'ALIGN' then
            self.dumper:add_directive(line, name, 0)
        else
            local size = self:number()
            if self:is_EOL() then
                self.dumper:add_directive(line, name, size)
            else
                self:optional_comma()
                self.dumper:add_directive(line, name, size, self:number())
            end
            self:expect_EOL()
        end
    elseif name == 'BYTE' or name == 'HALFWORD' or name == 'WORD' then
        self.dumper:add_directive(line, name, self:number())
        while not self:is_EOL() do
            self:advance()
            self:optional_comma()
            self.dumper:add_directive(line, name, self:number())
        end
        self:expect_EOL()
    elseif name == 'HEX' then
        self:error('unimplemented')
    elseif name == 'INC' then
        -- noop
    elseif name == 'INCBIN' then
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

function Parser:const(relative, no_label)
    if self.tt ~= 'NUM' and self.tt ~= 'LABELSYM' then
        self:error('expected constant')
    end
    if no_label and self.tt == 'LABELSYM' then
        self:error('labels are not allowed here')
    end
    if relative and self.tt == 'LABELSYM' then
        self.tt = 'LABELREL'
    end
    local t = {self.tt, self.tok}
    self:advance()
    return t
end

function Parser:format_in(informat)
    local args = {}
    for i=1,#informat do
        local c = informat:sub(i, i)
        local c2 = informat:sub(i + 1, i + 1)
        if c == 'd' and not args.rd then
            args.rd = self:register()
        elseif c == 's' and not args.rs then
            args.rs = self:register()
        elseif c == 't' and not args.rt then
            args.rt = self:register()
        elseif c == 'D' and not args.fd then
            args.fd = self:register(fpu_registers)
        elseif c == 'S' and not args.fs then
            args.fs = self:register(fpu_registers)
        elseif c == 'T' and not args.ft then
            args.ft = self:register(fpu_registers)
        elseif c == 'o' and not args.offset then
            args.offset = {'SIGNED', self:const()}
        elseif c == 'r' and not args.offset then
            args.offset = {'SIGNED', self:const('relative')}
        elseif c == 'i' and not args.immediate then
            args.immediate = self:const(nil, 'no label')
        elseif c == 'I' and not args.index then
            args.index = {'INDEX', self:const()}
        elseif c == 'k' and not args.immediate then
            args.immediate = {'NEGATE', self:const(nil, 'no label')}
        elseif c == 'K' and not args.immediate then
            args.immediate = {'SIGNED', self:const(nil, 'no label')}
        elseif c == 'b' and not args.base then
            args.base = self:deref()
        else
            error('Internal Error: invalid input formatting string', 1)
        end
        if c2:find('[dstDSTorIikK]') then
            self:optional_comma()
        end
    end
    return args
end

function Parser:format_out(outformat, first, args, const, formatconst)
    local lookup = {
        [1]=self.dumper.add_instruction_j,
        [3]=self.dumper.add_instruction_i,
        [5]=self.dumper.add_instruction_r,
    }
    out = {}
    for i=1,#outformat do
        local c = outformat:sub(i, i)
        if c == 'd' then
            out[#out+1] = args.rd
        elseif c == 's' then
            out[#out+1] = args.rs
        elseif c == 't' then
            out[#out+1] = args.rt
        elseif c == 'D' then
            out[#out+1] = args.fd
        elseif c == 'S' then
            out[#out+1] = args.fs
        elseif c == 'T' then
            out[#out+1] = args.ft
        elseif c == 'o' then
            out[#out+1] = args.offset
        elseif c == 'i' then
            out[#out+1] = args.immediate
        elseif c == 'I' then
            out[#out+1] = args.index
        elseif c == 'b' then
            out[#out+1] = args.base
        elseif c == '0' then
            out[#out+1] = 0
        elseif c == 'C' then
            out[#out+1] = const
        elseif c == 'F' then
            out[#out+1] = formatconst
        end
    end
    local f = lookup[#outformat]
    if f == nil then
        error('Internal Error: invalid output formatting string', 1)
    end
    f(self.dumper, self.line, first, out[1], out[2], out[3], out[4], out[5])
end

function Parser:instruction()
    local name = self.tok
    local h = instructions[name]
    self:advance()

    -- FIXME: errors thrown here probably have the wrong line number (+1)

    if h == nil then
        self:error('undefined instruction')
    elseif h == 'LI' then
        local lui = instructions['LUI']
        local ori = instructions['ORI']
        local addiu = instructions['ADDIU']
        local args = {}
        args.rt = self:register()
        self:optional_comma()
        local im = self:const()

        if im[1] == 'LABELSYM' then
            self:error('use LA for labels')
        end

        im[2] = im[2] % 0x100000000
        if im[2] >= 0x10000 and im[2] <= 0xFFFF8000 then
            args.rs = args.rt
            args.immediate = {'UPPER', im}
            self:format_out(lui[3], lui[1], args, lui[4], lui[5])
            if im[2] % 0x10000 ~= 0 then
                args.immediate = {'LOWER', im}
                self:format_out(ori[3], ori[1], args, ori[4], ori[5])
            end
        elseif im[2] >= 0x8000 and im[2] < 0x10000 then
            args.rs = 'R0'
            args.immediate = {'LOWER', im}
            self:format_out(ori[3], ori[1], args, ori[4], ori[5])
        else
            args.rs = 'R0'
            args.immediate = {'LOWER', im}
            self:format_out(addiu[3], addiu[1], args, addiu[4], addiu[5])
        end
    elseif h == 'LA' then
        local lui = instructions['LUI']
        local addiu = instructions['ADDIU']
        local args = {}
        args.rt = self:register()
        self:optional_comma()
        local im = self:const()

        -- for us, this is just semantics. for a "real" assembler,
        -- LA could add appropriate RELO LUI/ADDIU directives.
        -- for that reason, we should always use the respective instructions.
        if im[1] ~= 'LABELSYM' then
            self:error('use LI for immediates')
        end

        args.rs = args.rt
        args.immediate = {'UPPEROFF', im}
        self:format_out(lui[3], lui[1], args, lui[4], lui[5])
        args.immediate = {'LOWER', im}
        self:format_out(addiu[3], addiu[1], args, addiu[4], addiu[5])
    elseif h == 'PUSH' or h == 'POP' or h == 'JPOP' then
        local addi = instructions['ADDI']
        local w = instructions[h == 'PUSH' and 'SW' or 'LW']
        local jr = instructions['JR']
        local stack = {}
        while not self:is_EOL() do
            if self.tt == 'NUM' then
                if self.tok < 0 then
                    self:error("can't push a negative number of spaces")
                end
                for i=1,self.tok do
                    table.insert(stack, '')
                end
                self:advance()
            else
                table.insert(stack, self:register())
            end
            if not self:is_EOL() then
                self:optional_comma()
            end
        end
        if #stack == 0 then
            self:error(h..' requires at least one argument')
        end
        local args = {}
        if h == 'PUSH' then
            args.rt = 'SP'
            args.rs = 'SP'
            args.immediate = {'NEGATE', {'NUM', #stack*4}}
            self:format_out(addi[3], addi[1], args, addi[4], addi[5])
        end
        args.base = 'SP'
        for i, r in ipairs(stack) do
            args.rt = r
            if r ~= '' then
                args.offset = {'NUM', (i - 1)*4}
                self:format_out(w[3], w[1], args, w[4], w[5])
            end
        end
        if h == 'JPOP' then
            args.rs = 'RA'
            self:format_out(jr[3], jr[1], args, jr[4], jr[5])
        end
        if h == 'POP' or h == 'JPOP' then
            args.rt = 'SP'
            args.rs = 'SP'
            args.immediate = {'NUM', #stack*4}
            self:format_out(addi[3], addi[1], args, addi[4], addi[5])
        end
    elseif h == 'NAND' then
        local and_ = instructions['AND']
        local nor = instructions['NOR']
        local args = {}
        args.rd = self:register()
        self:optional_comma()
        args.rs = self:register()
        self:optional_comma()
        args.rt = self:register()
        self:format_out(and_[3], and_[1], args, and_[4], and_[5])
        args.rs = args.rd
        args.rt = 'R0'
        self:format_out(nor[3], nor[1], args, nor[4], nor[5])
    elseif h == 'NANDI' then
        local andi = instructions['ANDI']
        local nor = instructions['NOR']
        local args = {}
        args.rt = self:register()
        self:optional_comma()
        args.rs = self:register()
        self:optional_comma()
        args.immediate = self:const()
        self:format_out(andi[3], andi[1], args, andi[4], andi[5])
        args.rd = args.rt
        args.rs = args.rt
        args.rt = 'R0'
        self:format_out(nor[3], nor[1], args, nor[4], nor[5])
    elseif h == 'NORI' then
        local ori = instructions['ORI']
        local nor = instructions['NOR']
        local args = {}
        args.rt = self:register()
        self:optional_comma()
        args.rs = self:register()
        self:optional_comma()
        args.immediate = self:const()
        self:format_out(ori[3], ori[1], args, ori[4], ori[5])
        args.rd = args.rt
        args.rs = args.rt
        args.rt = 'R0'
        self:format_out(nor[3], nor[1], args, nor[4], nor[5])
    elseif h == 'ROL' then
        local sll = instructions['SLL']
        local srl = instructions['SRL']
        local or_ = instructions['OR']
        local args = {}
        local left = self:register()
        self:optional_comma()
        args.rt = self:register()
        self:optional_comma()
        args.immediate = self:const()
        args.rd = left
        if args.rd == 'AT' or args.rt == 'AT' then
            self:error('registers cannot be AT in this pseudo-instruction')
        end
        if args.rd == args.rt and args.rd ~= 'R0' then
            self:error('registers cannot be the same')
        end
        self:format_out(sll[3], sll[1], args, sll[4], sll[5])
        args.rd = 'AT'
        args.immediate = {'NUM', 32 - args.immediate[2]}
        self:format_out(srl[3], srl[1], args, srl[4], srl[5])
        args.rd = left
        args.rs = left
        args.rt = 'AT'
        self:format_out(or_[3], or_[1], args, or_[4], or_[5])
    elseif h == 'ROR' then
        local sll = instructions['SLL']
        local srl = instructions['SRL']
        local or_ = instructions['OR']
        local args = {}
        local right = self:register()
        self:optional_comma()
        args.rt = self:register()
        self:optional_comma()
        args.immediate = self:const()
        args.rd = right
        if args.rt == 'AT' or args.rd == 'AT' then
            self:error('registers cannot be AT in a pseudo-instruction that uses AT')
        end
        if args.rd == args.rt and args.rd ~= 'R0' then
            self:error('registers cannot be the same')
        end
        self:format_out(srl[3], srl[1], args, srl[4], srl[5])
        args.rd = 'AT'
        args.immediate = {'NUM', 32 - args.immediate[2]}
        self:format_out(sll[3], sll[1], args, sll[4], sll[5])
        args.rd = right
        args.rs = right
        args.rt = 'AT'
        self:format_out(or_[3], or_[1], args, or_[4], or_[5])
    elseif name == 'JR' then
        local args = {}
        if self:is_EOL() then
            args.rs = 'RA'
        else
            args.rs = self:register()
        end
        self:format_out(h[3], h[1], args, h[4], h[5])
    elseif h[2] == 'tob' then -- or h[2] == 'Tob' then
        local lui = instructions['LUI']
        local args = {}
        args.rt = self:register()
        self:optional_comma()
        local o = self:const()
        local is_label = o[1] == 'LABELSYM'
        if self:is_EOL() then
            local lui_args = {}
            lui_args.immediate = {'UPPEROFF', o}
            lui_args.rt = 'AT'
            self:format_out(lui[3], lui[1], lui_args, lui[4], lui[5])
            args.offset = {'LOWER', o}
            args.base = 'AT'
        else
            if is_label then
                self:error('labels cannot be used as offsets')
            end
            args.offset = {'SIGNED', o}
            self:optional_comma()
            args.base = self:deref()
        end
        self:format_out(h[3], h[1], args, h[4], h[5])
    elseif h[2] ~= nil then
        args = self:format_in(h[2])
        self:format_out(h[3], h[1], args, h[4], h[5])
    else
        self:error('unimplemented instruction')
    end
    self:expect_EOL()
end

function Parser:tokenize(asm)
    self.tokens = {}
    self.i = 0

    local routine = coroutine.create(function()
        local lexer = Lexer(asm, self.main_fn, self.options)
        lexer:lex(coroutine.yield)
    end)

    local function lex()
        local t = {}
        local ok, a, b, c, d = coroutine.resume(routine)
        if not ok then
            a = a or 'Internal Error: lexer coroutine has stopped'
            error(a)
        end
        t.tt = a
        t.tok = b
        t.fn = c
        t.line = d
        table.insert(self.tokens, t)
        return t.tt, t.tok, t.fn, t.line
    end

    -- first pass: collect tokens and constants.
    -- can't do more because instruction size can depend on a constant's size
    -- and labels depend on instruction size.
    -- note however, instruction size does not depend on label size.
    -- this would cause a recursive problem to solve,
    -- which is too much for our simple assembler.
    while true do
        local tt, tok, fn, line = lex()
        self.fn = fn
        self.line = line
        if tt == 'DEF' then
            local tt2, tok2 = lex()
            if tt2 ~= 'NUM' then
                self:error('expected number for define')
            end
            self.defines[tok] = tok2
        elseif tt == 'EOL' then
            -- noop
        elseif tt == 'EOF' then
            if fn == self.main_fn then
                break
            end
        elseif tt == nil then
            error('Internal Error: missing token', 1)
        end
    end

    -- resolve defines
    for i, t in ipairs(self.tokens) do
        self.fn = t.fn
        self.line = t.line
        if t.tt == 'DEFSYM' then
            t.tt = 'NUM'
            t.tok = self.defines[t.tok]
            if t.tok == nil then
                self:error('undefined define') -- uhhh nice wording
            end
        end
    end
end

function Parser:parse(asm)
    self:tokenize(asm)
    self:advance()
    while true do
        if self.tt == 'EOF' then
            if self.fn == self.main_fn then
                break
            end
            self:advance()
        elseif self.tt == 'EOL' then
            -- empty line
            self:advance()
        elseif self.tt == 'DEF' then
            self:advance()
            self:advance()
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
    error(string.format('%s:%d: Error: %s', self.fn, self.line, msg), 2)
end

function Dumper:advance(by)
    self.pos = self.pos + by
end

function Dumper:push_instruction(t)
    t.kind = 'instruction'
    table.insert(self.commands, t)
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
    local bs = {...}
    local t
    local use_last = self.lastcommand and self.lastcommand.kind == 'bytes'
    if use_last then
        t = self.lastcommand
    else
        t = {}
        t.kind = 'bytes'
        t.size = 0
    end
    t.line = line
    for _, b in ipairs(bs) do
        t.size = t.size + 1
        t[t.size] = b
    end
    if not use_last then
        table.insert(self.commands, t)
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
        table.insert(self.commands, t)
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
        table.insert(self.commands, t)
        self:advance(t.skip)
    elseif name == 'SKIP' then
        t.kind = 'ahead'
        t.skip = a
        t.fill = b
        table.insert(self.commands, t)
        self:advance(t.skip)
    else
        self:error('unimplemented directive')
    end
end

function Dumper:desym(tok)
    if type(tok[2]) == 'number' then
        return tok[2]
    elseif all_registers[tok] then
        return registers[tok] or fpu_registers[tok]
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
        local rel = floor(label/4) - 1 - floor(self.pos/4)
        if rel > 0x8000 or rel <= -0x8000 then
            self:error('branch too far')
        end
        return rel % 0x10000
    end
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
    self:error('invalid value')
end

function Dumper:validate(n, bits)
    local max = 2^bits
    if n == nil then
        self:error('value is nil')
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
            uw, lw = self:dump_instruction(t)
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

function assembler.assemble(fn_or_asm, writer, options)
    -- assemble MIPS R4300i assembly code.
    -- if fn_or_asm contains a newline; treat as assembly, otherwise load file.
    -- returns error message on error, or nil on success.
    fn_or_asm = tostring(fn_or_asm)
    writer = writer or io.write
    options = options or {}

    function main()
        local fn = nil
        local asm
        if fn_or_asm:find('[\r\n]') then
            asm = fn_or_asm
        else
            fn = fn_or_asm
            asm = readfile(fn)
            options.path = fn:match(".*/")
        end

        local parser = Parser(writer, fn, options)
        return parser:parse(asm)
    end

    if options.unsafe then
        return main()
    else
        local ok, err = pcall(main)
        return err
    end
end

return setmetatable(assembler, {
    __call = function(self, ...)
        return self.assemble(...)
    end,
})
