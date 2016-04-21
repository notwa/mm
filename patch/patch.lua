package.path = package.path..";./?/init.lua"

local assemble = require "lips"
local cereal = require "serialize"
local argparse = require "argparse"

local function lament(...)
    io.stdout:write(...)
    io.stdout:write('\n')
end

local function parsenum(s)
    if s:sub(1, 2) == '0x' then
        return tonumber(s, 16)
    elseif s:sub(1, 1) == '0' then
        return tonumber(s, 8)
    else
        return tonumber(s)
    end
end

local function inject(args)
    local offset = args.offset and parsenum(args.offset) or 0
    local origin = args.origin and parsenum(args.origin) or 0
    local base   =   args.base and parsenum(args.base)   or 0x80000000

    local f = io.open(args.output, 'r+b')
    if not f then
        lament("file not found:", args.output)
        return
    end

    local state = {}
    for _, import in ipairs(args.import) do
        local new_state = cereal.deserialize(import)
        for k, v in pairs(new_state) do
            state[k] = v
        end
    end

    local function write(pos, b)
        if args.extra_rom and args.extra_ram and pos >= args.extra_ram then
            pos = pos - args.extra_ram + args.extra_rom
        elseif pos >= offset then
            pos = pos - offset
        end
        if pos >= 1024*1024*1024 then
            lament("you probably don't want to do this:")
            lament(("%08X    %02X"):format(pos, b))
            return
        end
        f:seek('set', pos)

        f:write(string.char(b))
    end

    local options = {
        unsafe = true,
        labels = state,
        debug_token = args.dump_token,
        debug_pre   = args.dump_pre,
        debug_dump  = args.dump_asm,
    }
    if args.offset then
        if args.origin or args.base then
            error('--offset is mutually exclusive from --origin, --base')
        end
        options.offset = offset
    else
        options.origin = origin
        if args.origin or args.base then
            options.base = base
        else
            options.base = 0
        end
    end

    assemble(args.input, write, options)

    if args.export then
        cereal.serialize(args.export, state)
    end

    f:close()
end

local ap = argparse("patch", "patch a binary file with assembly")

-- TODO: option to dump hex or gs codes when no output is given
ap:argument("input",        "input assembly file")
ap:argument("output",       "output binary file")
ap:option("-o --offset",    "(deprecated) offset to pass to lips", nil)
ap:option("-O --origin",    "origin to pass to lips", nil):convert(parsenum)
ap:option("-b --base",      "base to pass to lips", nil):convert(parsenum)
ap:option("-i --import",    "import state file(s) containing labels"):count("*")
ap:option("-e --export",    "export state file containing labels")
ap:flag("--dump-token",     "(debug) dump statements to stdout after lexing")
ap:flag("--dump-pre",       "(debug) dump statements to stdout after preprocessing")
ap:flag("--dump-asm",       "(debug) dump statements to stdout after assembling")
--ap:option("-s --state", "--import and --export to this file")
-- TODO: replace this with a lua table import of associated addresses
ap:option("--extra-rom",    "dumb stuff"):convert(parsenum)
ap:option("--extra-ram",    "dumb stuff"):convert(parsenum)

local inject_args = ap:parse()

inject(inject_args)
