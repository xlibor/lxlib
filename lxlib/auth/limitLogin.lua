
local lx, _M = oo{
    _cls_ = ''
}

local app, lf, tb, str = lx.kit()
local redirect = lx.h.redirect

function _M.__:hasTooManyLoginAttempts(request)

    return self:limiter():tooManyAttempts(self:throttleKey(request), 5, 1)
end

function _M.__:incrementLoginAttempts(request)

    self:limiter():hit(self:throttleKey(request))
end

function _M.__:sendLockoutResponse(request)

    local seconds = self:limiter():availableIn(self:throttleKey(request))
    local message = app.lang.get('auth.throttle', {seconds = seconds})
    local errors = {[self:username()] = message}
    if request.expectsJson then
        
        return response():json(errors, 423)
    end
    
    return redirect():back():withInput(request:only(self:username(), 'remember')):withErrors(errors)
end

function _M.__:clearLoginAttempts(request)

    self:limiter():clear(self:throttleKey(request))
end

function _M.__:fireLockoutEvent(request)

    app:fire(new('lockout', request))
end

function _M.__:throttleKey(request)

    return str.lower(request:input(self:username())) .. '|' .. request.ip
end

function _M.__:limiter()

    return app('rateLimiter')
end

return _M

