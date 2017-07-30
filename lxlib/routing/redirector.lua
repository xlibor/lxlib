
local lx, _M, mt = oo{
    _cls_ = ''
}

local app, lf, tb, str, new = lx.kit()

function _M:new(generator)

    local this = {
        generator = generator,
        session = nil
    }
    
    return oo(this, mt)
end

function _M:home(status)

    status = status or 302
    
    return self:to(self.generator:route('home'), status)
end

function _M:back(status, headers, fallback)

    fallback = fallback or false
    headers = headers or {}
    status = status or 302
    
    return self:createRedirect(self.generator:previous(fallback), status, headers)
end

function _M:refresh(status, headers)

    headers = headers or {}
    status = status or 302
    
    return self:to(self.generator:getRequest():path(), status, headers)
end

function _M:guest(path, status, headers, secure)

    headers = headers or {}
    status = status or 302
    self.session:put('url.intended', self.generator:full())
    
    return self:to(path, status, headers, secure)
end

function _M:intended(default, status, headers, secure)

    headers = headers or {}
    status = status or 302
    default = default or '/'
    local path = self.session:pull('url.intended', default)

    return self:to(path, status, headers, secure)
end

function _M:to(path, status, headers, secure)

    headers = headers or {}
    status = status or 302
    
    local resp = self:createRedirect(
        self.generator:to(path, {}, secure), status, headers
    )

    return resp
end

function _M:away(path, status, headers)

    headers = headers or {}
    status = status or 302
    
    return self:createRedirect(path, status, headers)
end

function _M:secure(path, status, headers)

    headers = headers or {}
    status = status or 302
    
    return self:to(path, status, headers, true)
end

function _M:route(route, parameters, status, headers)

    headers = headers or {}
    status = status or 302
    parameters = parameters or {}
    
    return self:to(self.generator:route(route, parameters), status, headers)
end

function _M:action(action, parameters, status, headers)

    headers = headers or {}
    status = status or 302
    parameters = parameters or {}
    
    return self:to(self.generator:action(action, parameters), status, headers)
end

function _M.__:createRedirect(path, status, headers)

    local resp = new('redirectResponse', path, status, headers)

    if self.session then
        resp:setSession(self.session)
    end
    resp:setRequest(self.generator:getRequest())

    local ctx = app:ctx()
    ctx.resp = resp

    
    return resp
end

function _M:getUrlGenerator()

    return self.generator
end

function _M:setSession(session)

    self.session = session
end

return _M

