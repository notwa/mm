package.path = package.path..";./?/init.lua"

local assemble = require "lips"
local cereal = require "serialize"
local argparse = require "argparse"

local function inject(args)
    args.offset = args.offset or 0

    local f = io.open(args.output, 'r+b')
    if not f then
        print("file not found:", args.output)
        return
    end

    local state = {}
    for _, import in ipairs(args.import) do
        local new_state = cereal.deserialize(import)
        for k, v in pairs(new_state) do
            state[k] = v
        end
    end

    local function write(pos, line)
        assert(#line == 2, "that ain't const")
        if args.extra_rom and args.extra_ram and pos >= args.extra_ram then
            pos = pos - args.extra_ram + args.extra_rom
        elseif pos >= args.offset then
            pos = pos - args.offset
        end
        if pos >= 1024*1024*1024 then
            print("you probably don't want to do this:")
            print(("%08X"):format(pos), line)
            return
        end
        f:seek('set', pos)

        -- TODO: write hex dump format of written bytes
        --print(("%08X    %s"):format(pos, line))

        f:write(string.char(tonumber(line, 16)))
    end

    assemble(args.input, write, {unsafe=true, offset=args.offset, labels=state})

    if args.export then
        cereal.serialize(args.export, state)
    end

    f:close()
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

local ap = argparse("patch", "patch a binary file with assembly")

ap:argument("input", "input assembly file")
ap:argument("output", "output binary file")
ap:option("-o --offset", "offset to pass to lips", "0"):convert(parsenum)
ap:option("-i --import", "import state file(s) containing labels"):count("*")
ap:option("-e --export", "export state file containing labels")
--ap:option("-s --state", "--import and --export to this file")
ap:option("--extra-rom", "dumb stuff"):convert(parsenum)
ap:option("--extra-ram", "dumb stuff"):convert(parsenum)

local inject_args = ap:parse()

inject(inject_args)
