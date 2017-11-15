
local _M = { 
    _cls_    = '',
    _ext_    = 'lxlib.db.conn.connection'
}

local mt = { __index = _M }

local lx = require('lxlib')
local app = lx.app()

function _M:ctor()

end

return _M

