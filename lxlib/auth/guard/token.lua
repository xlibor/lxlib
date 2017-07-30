
local lx, _M, mt = oo{
    _cls_   = '',
    _bond_  = 'authGuardBond',
    _mix_   = 'auth.guardHelper'
}

local app, lf, tb, str = lx.kit()

function _M:new(provider, request)

    local this = {
        provider = provider,
        request = request,
        inputKey = 'api_token',
        storageKey = 'api_token'
    }

    return oo(this, mt)
end

function _M:user()

    local user = self._user
    if user then
        
        return user
    end

    local token = self:getTokenForRequest()
    if not lf.isEmpty(token) then
        user = self.provider:retrieveByCredentials({[self.storageKey] = token})
    end
    
    self._user = user

    return user
end

function _M:getTokenForRequest()

    local token = self.request:query(self.inputKey)
    if lf.isEmpty(token) then
        token = self.request:input(self.inputKey)
    end
    if lf.isEmpty(token) then
        token = self.request:bearerToken()
    end
    if lf.isEmpty(token) then
        token = self.request:getPassword()
    end
    
    return token
end

function _M:validate(credentials)

    credentials = credentials or {}
    if lf.isEmpty(credentials[self.inputKey]) then
        
        return false
    end
    credentials = {[self.storageKey] = credentials[self.inputKey]}
    if self.provider:retrieveByCredentials(credentials) then
        
        return true
    end
    
    return false
end

function _M:setRequest(request)

    self.request = request
    
    return self
end

return _M

