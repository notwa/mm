local writers = {}

function writers.make_word()
    local buff = {}
    local max = -1
    return function(pos, b)
        if pos then
            buff[pos] = ("%02X"):format(b)
            if pos > max then
                max = pos
            end
        elseif max >= 0 then
            for i=0, max, 4 do
                local a = buff[i+0] or '00'
                local b = buff[i+1] or '00'
                local c = buff[i+2] or '00'
                local d = buff[i+3] or '00'
                print(a..b..c..d)
            end
        end
    end
end

function writers.make_verbose()
    local buff = {}
    local max = -1
    return function(pos, b)
        if pos then
            buff[pos] = b
            if pos > max then
                max = pos
            end
        elseif max >= 0 then
            for i=0, max, 4 do
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
        end
    end
end

function writers.make_tester()
    local buff = {}
    local max = -1
    return function(pos, b)
        if pos then
            buff[pos] = b
            if pos > max then
                max = pos
            end
        elseif max >= 0 then
            local s = ''
            local last_i = 0
            for i=0, max, 4 do
                local a = buff[i+0] or nil
                local b = buff[i+1] or nil
                local c = buff[i+2] or nil
                local d = buff[i+3] or nil
                if a or b or c or d then
                    a = a and ("%02X"):format(a) or '--'
                    b = b and ("%02X"):format(b) or '--'
                    c = c and ("%02X"):format(c) or '--'
                    d = d and ("%02X"):format(d) or '--'
                    if last_i ~= i - 4 then
                        s = s..('@%08X\n'):format(i)
                    end
                    s = s..a..b..c..d.."\n"
                    last_i = i
                end
            end
            return s
        end
    end
end

function writers.make_gameshark()
    local buff = {}
    local max = -1
    return function(pos, b)
        if pos then
            pos = pos % 0x80000000
            buff[pos] = b
            if pos > max then
                max = pos
            end
        elseif max >= 0 then
            for i=0, max, 2 do
                local a = buff[i+0]
                local b = buff[i+1]
                a = a and ("%02X"):format(a)
                b = b and ("%02X"):format(b)
                if a and b then
                    print(('81%06X %s'):format(i, a..b))
                elseif a then
                    print(('80%06X 00%s'):format(i, a))
                elseif b then
                    print(('80%06X 00%s'):format(i + 1, b))
                end
            end
        end
    end
end

return writers
