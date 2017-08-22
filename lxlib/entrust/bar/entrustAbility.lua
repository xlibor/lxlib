
local lx, _M, mt = oo{
    _cls_ = ''
}

local app, lf, tb, str = lx.kit()
local abort = lx.h.abort

function _M:new()

    local this = {
    }
    
    return oo(this, mt)
end

-- Creates a new instance of the middleware.
-- @param guard auth

function _M:ctor(auth)

    self.auth = auth
end

-- Handle an incoming request.
-- @param request request
-- @param func next
-- @param roles
-- @param permissions
-- @param bool validateAll
-- @return mixed

function _M:handle(c, next, roles, permissions, validateAll)

    local request = c.req
    
    validateAll = validateAll or false
    if self.auth:guest() or not request:user():ability(
        str.split(roles, '|'), str.split(permissions, '|'),
        {validate_all = validateAll}
    ) then
        abort(403)
    end
    
    return next(request)
end

return _M

