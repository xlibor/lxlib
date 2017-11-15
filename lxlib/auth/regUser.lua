
local lx, _M = oo{
    _cls_ = '',
    _mix_ = 'lxlib.auth.redirectUser'
}

local app, lf, tb, str, new = lx.kit()
local redirect = lx.h.redirect
-- local Registered = lx.use('lxlib.auth.events.registered')

function _M:showRegForm(ctx)

    return ctx:view('auth.reg')
end

function _M:reg(ctx)

    local request = ctx.req

    self:validator(request.all):validate()
    local user = self:create(request.all)
    -- app:fire(new(Registered, user))
    self:guard():login(user)
    
    return self:reged(request, user) or redirect(self:redirectPath())
end

function _M.__:guard()

    return app('auth'):guard()
end

function _M.__:reged(request, user)
end

return _M

