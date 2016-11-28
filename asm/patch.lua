#!/usr/bin/env luajit
--require "test.strict"
local assemble = require "lips.init"
local cereal = require "serialize"
local argparse = require "argparse"

local function lament(...)
    io.stdout:write(...)
    io.stdout:write('\n')
end

local function parsenum(s)
    if type(s) == 'number' then
        return s
    end
    if s:sub(1, 2) == '0x' or s:sub(1, 1) == '$' then
        return tonumber(s, 16)
    elseif s:sub(1, 2) == '0o' or s:sub(1, 1) == '0' then
        return tonumber(s, 8)
    elseif s:sub(1, 2) == '0b' or s:sub(1, 1) == '%' then
        return tonumber(s, 2)
    else
        return tonumber(s)
    end
end

local function make_verbose_writer()
    -- TODO: further optimize
    local buff = {}
    local function write(i)
        local a = buff[i+0] or nil
        local b = buff[i+1] or nil
        local c = buff[i+2] or nil
        local d = buff[i+3] or nil
        if a or b or c or d then
            a = a and ("%02X"):format(a) or '--'
            b = b and ("%02X"):format(b) or '--'
            c = c and ("%02X"):format(c) or '--'
            d = d and ("%02X"):format(d) or '--'
            print(('%08X    %s'):format(i, a..b..c..d))
        end
    end

    local max = -1
    local maxp = -1
    return function(pos, b)
        if pos then
            buff[pos] = b
            if pos > max then
                max = pos
            end
            if pos < 0x80000000 and pos > maxp then
                maxp = pos
            end
        elseif max >= 0 then
            for i=0, maxp, 4 do
                write(i)
            end
            for i=0x80000000, max, 4 do
                write(i)
            end
        end
    end
end

local function inject(args)
    local offset = args.offset and parsenum(args.offset) or 0
    local origin = args.origin and parsenum(args.origin) or 0
    local base   =   args.base and parsenum(args.base)   or 0x80000000

    local f
    if args.output then
        f = io.open(args.output, 'r+b')
        if not f then
            lament("file not found: ", args.output)
            return
        end
    end

    local state = {}
    for _, import in ipairs(args.import) do
        local new_state = cereal.deserialize(import)
        for k, v in pairs(new_state) do
            state[k] = v
        end
    end

    local function write(pos, b)
        if pos >= offset then
            pos = pos - offset
        end
        if pos >= 1024*1024*1024 then
            lament(("oops:   %08X    %02X"):format(pos, b))
            return
        end

        if f then
            f:seek('set', pos)
            f:write(string.char(b))
        else
            print(("%08X %02X"):format(pos, b))
        end
    end

    local options = {
        unsafe = true,
        labels = state,
        debug_token = args.dump_token,
        debug_pre   = args.dump_pre,
        debug_post  = args.dump_post,
        debug_asm   = args.dump_asm,
    }
    if args.offset then
        if args.origin or args.base then
            error('--offset is mutually exclusive from --origin, --base')
        end
        options.offset = offset
    else
        options.origin = origin
        options.base = base
    end

    if f then
        assemble(args.input, write, options)
    else
        local vb = make_verbose_writer()
        assemble(args.input, vb, options)
        vb()
    end

    if args.export then
        cereal.serialize(args.export, state)
    end

    if f then
        f:close()
    end
end

local ap = argparse("patch", "patch a binary file with assembly")

-- TODO: option to dump hex or gs codes when no output is given
ap:argument("input",        "input assembly file")
ap:argument("output",       "output binary file"):args('?')
ap:option("-o --offset",    "(deprecated) offset to pass to lips", nil)
ap:option("-O --origin",    "origin to pass to lips", nil)
ap:option("-b --base",      "base to pass to lips", nil)
ap:option("-i --import",    "import state file(s) containing labels"):count("*")
ap:option("-e --export",    "export state file containing labels")
ap:flag("--dump-token",     "(debug) dump statements to stdout after lexing")
ap:flag("--dump-pre",       "(debug) dump statements to stdout after preprocessing")
ap:flag("--dump-post",      "(debug) dump statements to stdout after expanding")
ap:flag("--dump-asm",       "(debug) dump statements to stdout after assembling")
--ap:option("-s --state", "--import and --export to this file")
-- TODO: use -D defines instead

local inject_args = ap:parse()

inject(inject_args)
