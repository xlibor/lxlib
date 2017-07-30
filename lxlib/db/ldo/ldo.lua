
local _M = { 
    _cls_    = '',
    _bond_    = 'ldoBond'
}

local mt = { __index = _M }

local lx = require('lxlib')
local app, lf, tb, str = lx.kit()
local throw = lx.throw

function _M:new(config)
    
    local this = {
        config = config
    }

    setmetatable(this, mt)

    return this
end

function _M:exec(sql)
 
end

function _M:query(sql)

end

function _M:prepare(str, options)

end

function _M:beginTransaction()

end

function _M:commit()

end

function _M:rollback()

end

function _M:inTransaction()

end

function _M:getAttribute()

end

function _M:setAttr()

end

function _M:lastInsertId()

end

function _M:errorInfo()

end

function _M:errorCode()

end

function _M:getAvailableDrivers()

end

function _M:quote()

end

return _M

