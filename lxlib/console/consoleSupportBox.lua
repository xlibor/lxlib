
local _M = {
    _cls_ = '',
    _ext_ = 'groupBox'
}

local mt = { __index = _M }

local lx = require('lxlib')
local app = lx.app()

function _M:ctor()

    self.group = {
        'lxlib.console.consoleBox',
        'lxlib.db.shiftBox',
        'lxlib.db.seedBox',
        'lxlib.carrier.carrierBox',
        'lxlib.testing.unitBox'
    }

end

return _M

