
local lx, _M, mt = oo{
    _cls_ = ''
}

local app, lf, tb, str = lx.kit()

function _M:new()

    local this = {
        manager = app:get('session.manager')
    }

    return oo(this, mt)
end

function _M:handle(ctx, next)

    ctx.sessionHandled = true

    local session
    if self.sessionConfigured then
        session = self:startSession(ctx.req)
        ctx.req:setSession(session)
    end

    next(ctx)

    if self.sessionConfigured then
        self:storeCurrentUrl(ctx.req, session)
        self:gc(session)
        self:addCookieToResponse(ctx.resp, session)
    end
end

function _M.d__:sessionConfigured()

    if tb.get(self.manager:getSessionConfig(), 'driver') then
        return true
    else
        return false
    end
end

function _M:startSession(req)

    local session = self:getSession(req)
    session:setRequestOnHandler(req)
    session:start()

    return session
end

function _M:getSession(req)
    
    local session = self.manager:driver()
    local sid = req.cookies:get(session.name)
 
    session:setId(sid)

    return session
end

function _M:storeCurrentUrl(req, session)

end

function _M:gc(session)

    local config = self.manager:getSessionConfig()

end

function _M:addCookieToResponse(response, session)

    if self:usingCookieSessions() then
        self.manager:driver():save()
    end
 
    local config = self.manager:getSessionConfig()
    if self:sessionIsPersistent(config) then
        local ssName, ssId = session.name, session.id
        local expire = self:getCookieExpire()
        local path, domain = config.path, config.domain
        local secure = config.secure or false

        local cookie = app:make('simpleCookie', ssName, ssId, expire, path, domain, secure)

        response.headers:setCookie(cookie)
    end
end

function _M:getCookieExpire()

    local config = self.manager:getSessionConfig()
    local lifetime = config.lifetime
    local expire = 0

    if not config.expireOnClose then
        expire = lifetime
    end

    return expire
end

function _M:sessionIsPersistent(config)
    
    config = config or self.manager:getSessionConfig()
    local driver = config.driver
    if driver then
        return true
    end
end

function _M.c__:usingCookieSessions()

    if not self.sessionConfigured then
        return false
    end

    if self.manager:driver():getHandler():__is('session.cookieHandler') then
        return true
    end
end

function _M:over(ctx)

    if ctx.sessionHandled and self.sessionConfigured and not self:usingCookieSessions() then

        self.manager:driver():save()
    end
end

return _M

