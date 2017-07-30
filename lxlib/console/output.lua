
local _M = { 
    _cls_ = ''
}

local mt = { __index = _M }

local lx = require('lxlib')
local app, lf, tb, str = lx.kit()

local slen, slower = string.len, string.lower

function _M:new()

    local this = {
    }

    setmetatable(this, mt)

    return this
end

function _M:ctor()

    self.formatter = app:make('outputFormatter')
end

function _M:ask(question, default)

    self:line(question, 'question')
    local ret = io.stdin:read("*l")

    if slen(ret) == 0 then ret = nil end

    return ret or default
end

function _M:confirm(question, default)

    self:line('<question>'..question..'</question><info> yes or no</info>')
    local ret = io.stdin:read("*l")
    
    if slen(ret) > 0 then
        ret = slower(ret)
        if ret == 'y' or ret == 'ye' or ret == 'yes' then
            return true
        else
            return false
        end
    else
        return default and true or false
    end
end

function _M:line(msg, style)

    msg = lf.toStr(msg)
    msg = {text = msg, style = style}
    self:writeln(msg)
end

function _M:writeln(msgs, options)

    self:write(msgs, true, options)
end

function _M:write(msgs, newline, options)

    msgs = lf.needList(msgs)

    -- if newline then self:doWrite('\n') end
     
    local len = #msgs

    for i, msg in ipairs(msgs) do
        if type(msg) ~= 'table' then
            msg = {text = msg}
        end
        msg = self.formatter:format(msg)
        self:doWrite(msg, (i == len) and newline)
    end

end

function _M:doWrite(msg, last)

    if last then
        exec(fmt([[echo -e "%s"]], msg))
    else
        exec(fmt([[echo -e -n "%s"]], msg))
    end
end

return _M

