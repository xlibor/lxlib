
local lx, _M, mt = oo{
    _cls_   = '',
    _ext_   = 'attr',
    _bond_  = 'socialite.userBond'
}

local app, lf, tb, str = lx.kit()

function _M:ctor()

end

function _M:getId()

    return self:getAttr('id')
end

-- Get the nickname / username for the user.
-- @return string

function _M:getNickname()

    return self:getAttr('nickname')
end

-- Get the full name of the user.
-- @return string

function _M:getName()

    return self:getAttr('name')
end

-- Get the e-mail address of the user.
-- @return string

function _M:getEmail()

    return self:getAttr('email')
end

-- Get the avatar / image URL for the user.
-- @return string

function _M:getAvatar()

    return self:getAttr('avatar')
end

function _M:setToken(token)

    self:setAttr('token', token)
    
    return self
end

-- Set the refresh token required to obtain a new access token.
-- @param  string  refreshToken
-- @return self

function _M:setRefreshToken(refreshToken)

    self:setAttr('refreshToken', refreshToken)
    
    return self
end

-- Set the number of seconds the access token is valid for.
-- @param  int  expiresIn
-- @return self

function _M:setExpiresIn(expiresIn)

    self:setAttr('expiresIn', expiresIn)
    
    return self
end

-- Get the authorized token.

function _M:getToken()

    return self:getAttr('token')
end

_M.getAccessToken = _M.getToken

-- Get the original attributes.
-- @return table

function _M:getOriginal()

    return self:getAttr('original')
end

function _M:getProviderName()

    return self:getAttr('provider')
end

function _M:setProviderName(provider)

    self:setAttr('provider', provider)

    return self
end

return _M

