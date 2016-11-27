local insert = table.insert

local path = string.gsub(..., "[^.]+$", "")
local Base = require(path.."Base")
local Token = require(path.."Token")
local Lexer = require(path.."Lexer")
local Collector = require(path.."Collector")
local Preproc = require(path.."Preproc")
local Expander = require(path.."Expander")
local Dumper = require(path.."Dumper")

local Parser = Base:extend()
function Parser:init(writer, fn, options)
    self.writer = writer
    self.fn = fn or '(string)'
    self.main_fn = self.fn
    self.options = options or {}
end

function Parser:tokenize(asm)
    local lexer = Lexer(asm, self.main_fn, self.options)
    local tokens = {}

    local loop = true
    while loop do
        lexer:lex(function(tt, tok, fn, line)
            assert(tt, 'Internal Error: missing token')
            local t = Token(fn, line, tt, tok)
            insert(tokens, t)
            -- don't break if this is an included file's EOF
            if tt == 'EOF' and fn == self.main_fn then
                loop = false
            end
        end)
    end

    -- the lexer guarantees an EOL and EOF for a blank file
    assert(#tokens > 0, 'Internal Error: no tokens after preprocessing')

    local collector = Collector(self.options)
    return collector:collect(tokens, self.main_fn)
end

function Parser:dump()
    for i, s in ipairs(self.statements) do
        print(s.line, s.type, s:dump())
    end
end

function Parser:parse(asm)
    self.statements = self:tokenize(asm)
    if self.options.debug_token then self:dump() end

    self.statements = Preproc(self.options):process(self.statements)
    if self.options.debug_pre then self:dump() end

    self.statements = Expander(self.options):expand(self.statements)
    if self.options.debug_post then self:dump() end

    local dumper = Dumper(self.writer, self.options)
    self.statements = dumper:load(self.statements)
    if self.options.debug_asm then self:dump() end

    if self.options.labels then
        dumper:export_labels(self.options.labels)
    end
    return dumper:dump()
end

return Parser
