
local lx, _M, mt = oo{
    _cls_     = '',
    _bond_  = 'throwable'
}

local app, lf, tb, str = lx.kit()

local ssub, sgsub, smatch, sfind = string.sub, string.gsub, string.match, string.find

function _M:new(msg, code, prev)

    local this = {
        msg         = msg or '',
        code        = code or 0,
        prev        = prev
    }
 
    oo(this, mt)
 
    return this
end

function _M:ctor()

    local prev = self.prev

    if prev then
        if not self.file then
            self.file = prev.file
            self.line = prev.line
            self.trace = prev.trace
        end
    end
end

function _M:getMsg()

    local msg = self.msg

    return msg
end

_M.getMessage = _M.getMsg

function _M:getFile()

    local file = self.file

    return file
end

function _M:getLine()

    local line = self.line

    return line
end

function _M:getCode()

    local code = self.code

    return code
end

function _M:getTrace()

    local trace = self.trace

    return trace
end

function _M:getPrev()

    local prev = self.prev

    return prev
end

_M.getPrevious = _M.getPrev

function _M:toStr(showTrace)

    local s = 'exception [' .. self.__cls .. ']' ..
        ' with message \'' .. self:getMsg() .. '\'' ..
        ' in ' .. self:getFile() .. ':' .. self:getLine()

    if showTrace then
        s = s .. self:getTrace()
    end

    return s
end

function _M.c__:getTraceList()
    
    local trace = self.trace

    trace = sgsub(trace, '\t', '')
    local list = str.split(trace, '\n')
    local info
    local ret = {}
    local file, line, func, t
    local oldFile, oldLine

    local pos = 3
    if not self:__is 'errorException' then 
        pos = 5
    end

    for i = pos, #list do
        info = list[i]
        file, line, func = smatch(info, '(.*):(%d*): in function (.*)')
        if not file and info ~= '...' then
            file, func = smatch(info, '(.*): in function (.*)')
        end

        if not func then
            file, line = smatch(info, '(.*):(%d*): in')
        end

        if func then
            t = ssub(func, 1, 1)
            if t == '<' then
                oldLine = line
                tapd(ret, {file = file, line = line})
                file, line = smatch(info, '<(.*):(%d*)>')
                if oldLine ~= line then
                    tapd(ret, {file = file, line = line})
                end
                file = nil
            end
        end
        if file then
            tapd(ret, {file = file, line = line, func = func})
        end
    end

    return ret
end

return _M

