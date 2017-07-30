
local _M = { 
    _cls_    = '',
    _ext_    = 'baseConnector',
    _bond_    = 'connectorBond'
}

local mt = { __index = _M }

local lx = require('lxlib')
local app = lx.app()
local d = lx.def

function _M:new()
    
    local this = {
        driver = 'sqlite'
    }

    setmetatable(this, mt)

    return this
end

function _M:connect(config)
     
    local filePath = config.database
    if filePath then
        config.database = app.dbDir .. d.dirSep .. filePath
    end

    local connection = self:createConnection(config)

    return connection
end

return _M

