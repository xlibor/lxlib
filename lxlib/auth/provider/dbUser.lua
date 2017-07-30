
local lx, _M, mt = oo{
    _cls_ = '',
    _bond_ = 'authUserProviderBond'
}

local app, lf, tb, str, new = lx.kit()

function _M:new(conn, hasher, table)

    local this = {
        conn = conn,
        hasher = hasher,
        table = table
    }

    return oo(this, mt)
end

function _M:retrieveById(identifier)

    local user = self:getQuery():find(identifier)
    
    return self:getGenericUser(user)
end

function _M:retrieveByToken(identifier, token)

    local user = self:getQuery()
        :where{id = identifier, remember_token = token}
        :first()
    
    return self:getGenericUser(user)
end

function _M:updateRememberToken(user, token)

    self:getQuery()
        :where{id = user:getAuthIdentifier()}
        :update{remember_token = token}
end

function _M:retrieveByCredentials(credentials)

    local query = self:getQuery()
    for key, value in pairs(credentials) do
        if not str.contains(key, 'password') then
            query:where(key, value)
        end
    end
    
    local user = query:first()
    
    return self:getGenericUser(user)
end

function _M.__:getQuery()

    return self.conn:table(self.table)
end

function _M.__:getGenericUser(user)

    if user then
        
        return new('auth.genericUser', user)
    end
end

function _M:validateCredentials(user, credentials)

    return self.hasher:check(credentials['password'], user:getAuthPassword())
end

return _M

