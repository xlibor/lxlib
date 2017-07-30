
local lx, _M, mt = oo{
    _cls_   = '',
    _bond_  = 'authenticatableBond'
}

local app, lf, tb, str = lx.kit()

function _M:new(attributes)

    local this = {
        attributes = attributes
    }

    oo(this, mt)

    return this
end

function _M:getAuthIdentifierName()

    return 'id'
end

function _M:getAuthIdentifier()

    local name = self:getAuthIdentifierName()
    
    return self.attributes[name]
end

function _M:getAuthPassword()

    return self.attributes['password']
end

function _M:getRememberToken()

    return self.attributes[self:getRememberTokenName()]
end

function _M:setRememberToken(value)

    self.attributes[self:getRememberTokenName()] = value
end

function _M:getRememberTokenName()

    return 'remember_token'
end

function _M:_get_(key)

    return self.attributes[key]
end

function _M:_set_(key, value)

    self.attributes[key] = value
end

return _M

