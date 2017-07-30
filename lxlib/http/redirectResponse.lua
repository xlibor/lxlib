
local lx, _M = oo{
    _cls_ = '',
    _ext_ = 'baseResponse',
    _mix_ = 'responseMix'
}

local app, lf, tb, str, new = lx.kit()
local throw = lx.throw

function _M:ctor(url, status, headers)

    status = status or 302
    headers = headers or {}
    self.__skip = true
    self:__super('ctor', '', status, headers)

    self:setTargetUrl(url)

    if not self:isRedirect() then
        throw(
            'invalidArgumentException',
            fmt('The HTTP status code is not a redirect ("%s" given)', status)
        )
    end

end

function _M:getTargetUrl()

    return self.targetUrl
end

function _M:setTargetUrl(url)

    if lf.isEmpty(url) then
        throw('invalidArgumentException', 'cannot redirect to an empty URL.')
    end

    self.targetUrl = url

    -- do return self end

    self:setContent(
        fmt([[<!DOCTYPE html>
<html>
    <head>
        <meta charset="UTF-8" />
        <meta http-equiv="refresh" content="1;url=%s" />

        <title>Redirecting to %s</title>
    </head>
    <body>
        Redirecting to <a href="%s">%s</a>.
    </body>
</html>]], url, url, url, url)
    )

    self.headers:set('Location', url)

    return self
end

function _M:with(key, value)

    key = lf.isTbl(key) and key or {[key] = value}
    for k, v in pairs(key) do
        self.session:flash(k, v)
    end
    
    return self
end

function _M:withCookies(cookies)

    for _, cookie in pairs(cookies) do
        self.headers:setCookie(cookie)
    end
    
    return self
end

function _M:withInput(input)

    self.session:flashInput(input or self.request.all)
    
    return self
end

function _M:onlyInput(...)

    return self:withInput(self.request:only(...))
end

function _M:exceptInput(...)

    return self:withInput(self.request:except(...))
end

function _M:withErrors(provider, key)

    key = key or 'default'
    local value = self:parseErrors(provider)

    self.session:flash('errors',
        self.session:get('errors', new('viewErrorBag')):put(key, value)
    )

    return self
end

function _M.__:parseErrors(provider)

    if lf.isA(provider, 'msgProvider') then
        
        return provider:getMsgBag()
    end
    
    provider = lf.asTbl(provider)

    return new('msgBag', provider)
end

function _M:getOriginalContent()
end

function _M:getRequest()

    return self.request
end

function _M:setRequest(request)

    self.request = request
end

function _M:getSession()

    return self.session
end

function _M:setSession(session)

    self.session = session
end

function _M:__call(method)
 
    if str.startsWith(method, 'with') then
        
        return self:with(str.snake(str.substr(method, 4)), parameters[0])
    end

    lx.throw('badMethodCallException', "Method [{method}] does not exist on Redirect.")
end

return _M

