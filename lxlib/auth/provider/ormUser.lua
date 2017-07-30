
local lx, _M, mt = oo{
    _cls_   = '',
    _bond_  = 'authUserProviderBond'
}

local app, lf, tb, str, new = lx.kit()

function _M:new(hasher, model)

    local this = {
        hasher = hasher,
        model = model
    }

    oo(this, mt)

    return this
end

function _M:retrieveById(identifier)

    return self:createModel():newQuery():find(identifier)
end

function _M:retrieveByToken(identifier, token)

    local model = self:createModel()
    
    return model:newQuery()
        :where(model:getAuthIdentifierName(), identifier)
        :where(model:getRememberTokenName(), token)
        :first()
end

function _M:updateRememberToken(user, token)

    user:setRememberToken(token)
    local timestamps = user.timestamps
    user.timestamps = false
    user:save()
    user.timestamps = timestamps
end

function _M:retrieveByCredentials(credentials)

    if lf.isEmpty(credentials) then
        
        return
    end
    
    local query = self:createModel():newQuery()
    for key, value in pairs(credentials) do
        if not str.contains(key, 'password') then
            query:where(key, value)
        end
    end
    
    return query:first()
end

function _M:validateCredentials(user, credentials)

    local plain = credentials['password']

    return self.hasher:check(plain, user:getAuthPassword())
end

function _M:createModel()

    local class = self.model
    
    return new(class)
end

return _M

