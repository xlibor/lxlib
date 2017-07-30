
local lx, _M, mt = oo{
    _cls_ = ''
}

local cookieBase = require('lxlib.cookie.base.cookies')

local app, lf, tb, str = lx.kit()

function _M:new()

    local this = {
        path = '/',
        domain = nil, 
        secure = false,
        base = cookieBase:new(),
        queuedCks = {}
    }
 
    oo(this, mt)

    return this
end

function _M:make(name, value, minutes, path, domain, secure, httpOnly)
    
    minutes = minutes or 0
    httpOnly = lf.needTrue(httpOnly)
    path, domain, secure = self:getPathAndDomain(path, domain, secure)
 
    return app:make('simpleCookie', name, value, minutes, path, domain, secure, httpOnly)
end

function _M:getPathAndDomain(path, domain, secure)

    path = path or self.path
    domain = domain or self.domain
    secure = secure or self.secure

    return path, domain, secure
end

function _M:setDefaultPathAndDomain(path, domain, secure)

    self.path = path
    self.domain = domain
    self.secure = secure
end

function _M:getQueuedCookies()
    
    return self.queuedCks
end

function _M:forever(name, value, path, domain, secure, httpOnly)

    return self:make(name, value, 2628000, path, domain, secure, httpOnly)
end

function _M:forget(name, path, domain)

    return self:make(name, nil, -2628000, path, domain)
end

function _M:queue(...)

    local ck = lf.mustArgs(...)
    if not ck then
        ck = self:make(...)
    end

    self.queuedCks[ck.name] = ck
end

function _M:unqueue(name)
    
    self.queuedCks[name] = nil
end

function _M:queued(key, default)

    return tb.get(self.queuedCks, key, default)
end

function _M:hasQueued(key)

    if self:queued(key) then
        return true
    end
end

function _M:set(...)

    local ck = lf.mustArgs(...)
 
    self.base:set(...)
end

function _M:get(...)

    return self.base:get(...)
end

return _M

