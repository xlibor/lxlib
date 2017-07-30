
local _M = {
    _cls_    = ''
}

local lx = require('lxlib')
local lf, tb, str = lx.f, lx.tb, lx.str
local sfind, smatch = string.find, string.match



function _M.parse(args, cmd)

    if cmd then
        return _M.parseWithCmd(args, cmd)
    end

    local args = str.split(args, '&@#')

    local mainCmd, subCmd
    local cmdArgs = {}
    local t
    local arg1 = tb.shift(args)
    local rawArgs = args

    if sfind(arg1, ':') then
        t = str.split(arg1, ':')
        mainCmd, subCmd = unpack(t)
    else
        mainCmd = arg1
    end
 
    local cmdArgs = {}
    local needSkip, t
    local varName, varValue

    for i, v in ipairs(args) do
        if str.startWith(v, '%-%-') then
            varName, varValue = smatch(v, '%-%-(%w+)=?(.*)')
            if varName then
                if lf.isFalseStr(varValue) then
                    varValue = false
                else
                    varValue = varValue or true
                end
                cmdArgs[varName] = varValue
            end
        elseif str.startWith(v, '%-') then
            varName = smatch(v, '%-(%w+)')
            t = args[i+1]
            if t then
                if not str.startWith(t, '%-') then
                    if lf.isFalseStr(t) then
                        varValue = false
                    else
                        varValue = t or true
                    end
                    cmdArgs[varName] = varValue
                end
            else
                cmdArgs[varName] = true
            end
        else
            tapd(cmdArgs, v)
        end
    end

    local uri
    if not subCmd then
        uri = mainCmd
        local t = str.split(uri, '/')
        if #t == 1 then
            subCmd = mainCmd
        else
            subCmd = tb.pop(t)
            mainCmd = str.join(t, '/')
        end
    else
        uri = mainCmd .. '/' .. subCmd
    end

    return {
        mainCmd = mainCmd,
        subCmd    = subCmd,
        uri = uri,
        cmdArgs = cmdArgs,
        rawArgs = rawArgs
    }
end

function _M.parseWithCmd(args, cmd)

    local mainCmd, subCmd
    local t

    if sfind(cmd, ':') then
        t = str.split(cmd, ':')
        mainCmd, subCmd = unpack(t)
    else
        mainCmd = cmd
    end

    local uri
    if not subCmd then
        uri = mainCmd
    else
        uri = mainCmd .. '/' .. subCmd
    end

    return {
        mainCmd = mainCmd,
        subCmd    = subCmd,
        uri = uri,
        cmdArgs = args,
        rawArgs = args
    }
end

return _M

