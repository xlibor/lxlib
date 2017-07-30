
local lx, _M = oo{ 
    _cls_ = ''
}

local app, lf, tb, str = lx.kit()

function _M:cookie(...)

    return self:withCookie(...)
end

function _M:withCookie(...)

    local ck, args = lf.mustArgs(...)
    if not ck then
        ck = app:make('simpleCookie', ...)
    end

    local headers = self.headers
    headers:setCookie(ck)

    return self
end

function _M:header(key, value)

    self.headers:set(key, value)

    return self
end

function _M:withHeaders(needHeaders)

    local headers = self.headers

    for k, v in pairs(needHeaders) do
        headers:set(k, v)
    end

    return self
end

return _M

