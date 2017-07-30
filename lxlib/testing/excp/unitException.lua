
local lx, _M, mt = oo{
    _cls_ = '',
    _ext_ = 'runtimeException'
}

local app, lf, tb, str = lx.kit()

function _M:ctor(message, code, previous)

    code = code or 0
    message = message or ''
    self.__skip = true
    self:__super(_M, 'ctor', message, code, previous)
end

-- @return string

function _M:toStr(showTrace)

    local string = self:getMsg()
    local trace = self:getTrace()
    if trace and showTrace then
        string = string .. "\n" .. trace
    end
    
    return string
end

return _M

