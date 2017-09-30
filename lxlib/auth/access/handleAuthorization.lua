
local lx, _M = oo{
    _cls_ = ''
}

local app, lf, tb, str, new = lx.kit()
local throw = lx.throw

function _M:allow(message)

    return new('response', message)
end

function _M:deny(message)

    message = message or 'This action is unauthorized.'
    throw('authorizationException', message)
end

return _M

