
local lx, _M, mt = oo{ 
    _cls_       = '',
    _ext_       = 'runtimeException',
    _bond_      = 'httpExceptionBond'
}

local app, lf, tb, str, new = lx.kit()

function _M:new(statusCode, msg, headers, code, prev)

    local this = {
        statusCode = statusCode,
        msg = msg or '',
        headers = headers,
        code = cdoe or 0,
        prev = prev
    }
    
    oo(this, mt)
 
    return this
end

function _M:getStatusCode()

    return self.statusCode
end

function _M:getHeaders()

    return self.headers
end

return _M

