
local lx, _M, mt = oo{
    _cls_ = ''
}

local app, lf, tb, str = lx.kit()

local auth

function _M._init_()

    auth = app.auth
end

function _M:new()

    return oo({}, mt)
end

function _M:handle(context, next, guards)

    self:authenticate(guards)
    
    return next(context)
end

function _M.__:authenticate(guards)

    if lf.isEmpty(guards) then
        return auth:authenticate()
    end

    for _, guard in pairs(guards) do
        if auth:guard(guard):check() then
            
            return auth:shouldUse(guard)
        end
    end

    lx.throw('authenticationException', 'Unauthenticated.', guards)
end

return _M

