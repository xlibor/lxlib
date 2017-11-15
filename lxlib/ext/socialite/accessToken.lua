
local lx, _M = oo{
    _cls_ = '',
    _ext_ = 'attr'
}

local app, lf, tb, str = lx.kit()
local throw = lx.throw

function _M:ctor(attrs)

    if lf.isEmpty(attrs.access_token) then
        throw('invalidArgumentException', 'The key "access_token" could not be empty.')
    end
end

-- Return the access token string.
-- @return string

function _M:getToken()

    return self:getAttr('access_token')
end

function _M:toStr()

    return self:getToken() or ''
end

return _M

