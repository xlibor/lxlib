
local lx, _M = oo{
    _cls_ = ''
}

local app, lf, tb, str = lx.kit()

function _M:ctor()

    rawset(self, 'rememberTokenName', 'remember_token')
end

function _M:getAuthIdentifierName()

    return self:getKeyName()
end

function _M:getAuthIdentifier()

    return self:getKey()
end

function _M:getAuthPassword()

    return self.password
end

function _M:getRememberToken()

    local t = self:getRememberTokenName()
    if t then
        
        return self[t]
    end
end

function _M:setRememberToken(value)

    local t = self:getRememberTokenName()
    if t then
        self[t] = value
    end
end

function _M:getRememberTokenName()

    return self.rememberTokenName
end

return _M

