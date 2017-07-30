
local lx, _M, mt = oo{
    _cls_ = '',
    _ext_ = 'exception'
}

local app, lf, tb, str = lx.kit()

function _M:ctor(msg, guards)

    guards = guards or {}
    msg = msg or 'Unauthenticated.'
    self.msg = msg
    self.guards = guards
end

function _M:getGuards()

    return self.guards
end

return _M

