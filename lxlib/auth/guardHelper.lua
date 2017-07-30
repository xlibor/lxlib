
local lx, _M = oo{
    _cls_ = ''
}

local app, lf, tb, str = lx.kit()

function _M:ctor()

end

function _M:authenticate()

    local user = self:user()

    if user then
        
        return user
    end

    lx.throw('authenticationException')
end

function _M:check()

    return self:user() and true or false
end

function _M:guest()

    return not self:check()
end

function _M:getId()

    local user = self:user()
    if user then

        return user:getAuthIdentifier()
    end
end

function _M:id()

    return self:getId()
end

function _M:setUser(user)

    self._user = user
    
    return self
end

return _M

