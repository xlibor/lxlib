
local _M = { 
    _cls_    = '',
    _ext_    = 'baseConnector',
    _bond_    = 'connectorBond'
}

local mt = { __index = _M }

local lx = require('lxlib')
local app = lx.app()

function _M:new()
    
    local this = {
        driver = 'mysql'
    }

    setmetatable(this, mt)

    return this
end

function _M:connect(config)
 
    local connection = self:createConnection(config)

    return connection
end

return _M

