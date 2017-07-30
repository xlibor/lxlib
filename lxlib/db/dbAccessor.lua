
local _M = {
    _cls_    = '',
    _ext_    = 'db.manager'
}

local lx = require('lxlib').load(_M)
local app = lx.app()

function _M:ctor()

end

function _M:conn(name)

    local conn = self:connection(name)

    return conn
end

function _M:_run_(method)

    return 'connection'
end

return _M

