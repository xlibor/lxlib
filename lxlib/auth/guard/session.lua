
local lx, _M, mt = oo{
    _cls_   = '',
    _bond_  = {'statefulGuard', 'supportBasicAuth'},
    _mix_   = 'lxlib.auth.guardHelper'
}

local app, lf, tb, str, new = lx.kit()
local events

function _M._init_()

    events = app.events
end

function _M:new(name, provider, session, request)

    local this = {
        name = name,
        provider = provider,
        lastAttempted = nil,
        viaRemember = false,
        session = session,
        cookie = nil,
        request = request,
        loggedOut = false,
        recallAttempted = false,
        eventable = true,
    }

    oo(this, mt)

    return this
end

function _M:user()

    if self.loggedOut then

        return
    end

    local user = self._user

    if user then

        return user
    end

    local id = self.session:get(self:getName())

    if id then
        user = self.provider:retrieveById(id)
        if user then
            self:fireAuthenticatedEvent(user)
        end
    end
    
    local recaller = self:recaller()
    if not user and recaller then
        user = self:userFromRecaller(recaller)
        if user then
            self:updateSession(user:getAuthIdentifier())
            self:fireLoginEvent(user, true)
        end
    end
    
    self._user = user

    return user
end

function _M.__:userFromRecaller(recaller)

    if not recaller:valid() or self.recallAttempted then
        
        return
    end
    
    self.recallAttempted = true
    local user = self.provider:retrieveByToken(recaller.id, recaller.token)
    self.viaRemember = user
    
    return user
end

function _M.__:recaller()

    if not self.request then
        
        return
    end
    local recaller = self.request.cookies:get(self:getRecallerName())
    if recaller then
        
        return new('lxlib.auth.recaller', recaller)
    end
end

function _M:getId()

    if self.loggedOut then
        
        return
    end
    
    local user = self:user()
    return user and user:getAuthIdentifier() or self.session:get(self:getName())
end

function _M:once(credentials)

    credentials = credentials or {}
    self:fireAttemptEvent(credentials)
    if self:validate(credentials) then
        self:setUser(self.lastAttempted)
        
        return true
    end
    
    return false
end

function _M:onceUsingId(id)

    local user = self.provider:retrieveById(id)
    if user then
        self:setUser(user)
        
        return user
    end
    
    return false
end

function _M:validate(credentials)

    credentials = credentials or {}
    local user = self.provider:retrieveByCredentials(credentials)
    self.lastAttempted = user
    
    return self:hasValidCredentials(user, credentials)
end

function _M:basic(field, extraConditions)

    extraConditions = extraConditions or {}
    field = field or 'email'
    if self:check() then
        
        return
    end
    
    if self:attemptBasic(self:getRequest(), field, extraConditions) then
        
        return
    end
    
    return self:failedBasicResponse()
end

function _M:onceBasic(field, extraConditions)

    extraConditions = extraConditions or {}
    field = field or 'email'
    local credentials = self:basicCredentials(self:getRequest(), field)
    if not self:once(tb.merge(credentials, extraConditions)) then
        
        return self:failedBasicResponse()
    end
end

function _M.__:attemptBasic(request, field, extraConditions)

    extraConditions = extraConditions or {}
    if not request.user then
        
        return false
    end
    
    return self:attempt(tb.merge(self:basicCredentials(request, field), extraConditions))
end

function _M.__:basicCredentials(request, field)

    return {field = request.user, password = request.pwd}
end

function _M.__:failedBasicResponse()

    return new('response','Invalid credentials.', 401, {['WWW-Authenticate'] = 'Basic'})
end

function _M:attempt(credentials, remember)

    remember = remember or false
    credentials = credentials or {}

    self:fireAttemptEvent(credentials, remember)
    local user = self.provider:retrieveByCredentials(credentials)
    self.lastAttempted = user

    if self:hasValidCredentials(user, credentials) then
        self:login(user, remember)
        
        return true
    end

    self:fireFailedEvent(user, credentials)
    
    return false
end

function _M.__:hasValidCredentials(user, credentials)

    return user and self.provider:validateCredentials(user, credentials)
end

function _M:loginUsingId(id, remember)

    remember = remember or false
    local user = self.provider:retrieveById(id)
    if user then
        self:login(user, remember)
        
        return user
    end
    
    return false
end

function _M:login(user, remember)

    remember = remember or false
    self:updateSession(user:getAuthIdentifier())
    
    if remember then
        self:ensureRememberTokenIsSet(user)
        self:queueRecallerCookie(user)
    end

    self:fireLoginEvent(user, remember)
    self:setUser(user)
end

function _M.__:updateSession(id)

    self.session:put(self:getName(), id)
    self.session:migrate(true)
end

function _M.__:ensureRememberTokenIsSet(user)

    if lf.isEmpty(user:getRememberToken()) then
        self:cycleRememberToken(user)
    end
end

function _M.__:queueRecallerCookie(user)

    self:getCookieJar():queue(
        self:createRecaller(
            user:getAuthIdentifier() .. '|' .. user:getRememberToken()
        )
    )
end

function _M.__:createRecaller(value)

    return self:getCookieJar():forever(self:getRecallerName(), value)
end

function _M:logout()

    local user = self:user()

    self:clearUserDataFromStorage()
    if user then
        self:cycleRememberToken(user)
    end

    self:fireLogoutEvent(user)

    self._user = nil
    self.loggedOut = true
end

function _M.__:clearUserDataFromStorage()

    self.session:remove(self:getName())
    if self:recaller() then
        self:getCookieJar():queue(self:getCookieJar():forget(self:getRecallerName()))
    end
end

function _M.__:cycleRememberToken(user)

    local token = str.random(60)
    user:setRememberToken(token)
    self.provider:updateRememberToken(user, token)
end

function _M:attempting(callback)

    events:listen(self.__nick .. '@attempting', callback)

end

function _M.__:fireAttemptEvent(credentials, remember)

    if not self.eventable then return end

    remember = remember or false

    events:fire(self, 'attempting', credentials, remember)

end

function _M.__:fireLoginEvent(user, remember)

    if not self.eventable then return end

    remember = remember or false
    events:fire(self, 'login', user, remember)
end

function _M.__:fireAuthenticatedEvent(user)

    if not self.eventable then return end

    events:fire(self, 'authenticated', user)
end

function _M.__:fireFailedEvent(user, credentials)

    if not self.eventable then return end

    events:fire(self, 'failed', user, credentials)
end

function _M.__:fireLogoutEvent(user)

    if not self.eventable then return end

    events:fire(self, user)
end

function _M:getLastAttempted()

    return self.lastAttempted
end

function _M:getName()

    return 'login_' .. self.name .. '_' .. lf.sha1(self.__name)
end

function _M:getRecallerName()

    return 'remember_' .. self.name .. '_' .. lf.sha1(self.__name)
end

function _M:viaRemember()

    return self.viaRemember
end

function _M:getCookieJar()

    if not self.cookie then
        lx.throw('runtimeException', 'Cookie jar has not been set.')
    end
    
    return self.cookie
end

function _M:setCookieJar(cookie)

    self.cookie = cookie
end

function _M:getSession()

    return self.session
end

function _M:getProvider()

    return self.provider
end

function _M:setProvider(provider)

    self.provider = provider
end

function _M:setUser(user)

    self._user = user
    self.loggedOut = false
    self:fireAuthenticatedEvent(user)
    
    return self
end

function _M:getRequest()

    return self.request or app:get('request')
end

function _M:setRequest(request)

    self.request = request
    
    return self
end

return _M

