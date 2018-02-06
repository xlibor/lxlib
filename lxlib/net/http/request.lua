
local lx, _M, mt = oo{
    _cls_   = ''
}

local app, lf, tb, str = lx.kit()

function _M:new(method, uri, headers, body, version, query)

    local this = {
        method      = str.upper(method),
        uri         = uri,
        headers     = headers or {},
        body        = body,
        protocol    = version or '1.1',
        query       = query
    }

    return oo(this, mt)
end

function _M:ctor()

end

return _M

