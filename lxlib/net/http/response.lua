
local lx, _M, mt = oo{
    _cls_   = ''
}

local app, lf, tb, str = lx.kit()

function _M:new(status, headers, body, version, reason)

    version = version or '1.1'
    headers = headers or {}
    status = status or 200
    
    local this = {
        headers = headers, 
        body = body,
        protocol = version,
        statusCode = tonumber(status)
    }

    return oo(this, mt)
end

function _M:ctor()

end

function _M:getBody()

    return self.body or ''
end

function _M:getHeader(key)

    return self.headers[key]
end

function _M:getHeaders()

    return self.headers
end

function _M:getStatus()

    return self.statusCode
end

return _M
