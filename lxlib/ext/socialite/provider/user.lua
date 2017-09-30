
local lx, _M, mt = oo{
    _cls_ = '',
    _ext_ = 'socialite.abstractUser'
}

local app, lf, tb, str = lx.kit()

function _M:ctor()

    self.token = nil
    self.refreshToken = nil
    self.expiresIn = nil
end

function _M:setToken(token)

    self.token = token
    
    return self
end

-- Set the refresh token required to obtain a new access token.
-- @param  string  refreshToken
-- @return self

function _M:setRefreshToken(refreshToken)

    self.refreshToken = refreshToken
    
    return self
end

-- Set the number of seconds the access token is valid for.
-- @param  int  expiresIn
-- @return self

function _M:setExpiresIn(expiresIn)

    self.expiresIn = expiresIn
    
    return self
end

return _M

