
local lx, _M = oo{
    _cls_ = '',
    _mix_ = {'auth.redirectUser'}
}

local app, lf, tb, str = lx.kit()
local lh = lx.h
local redirect, back, abort, route = lh.kit()
local trans = lx.h.trans

function _M:showLoginForm(c)

    return c:view('auth.login')
end

function _M:login(c)

    local request = c.req
    self:validateLogin(request)

    -- if self:hasTooManyLoginAttempts(request) then
    --     self:fireLockoutEvent(request)
        
    --     return self:sendLockoutResponse(request)
    -- end

    if self:attemptLogin(request) then
        
        return self:sendLoginResponse(request)
    end
    
    -- self:incrementLoginAttempts(request)
    
    return self:sendFailedLoginResponse(request)
end

function _M.__:validateLogin(request)

    self:validate(request, {
        [self:username()] = 'required',
        password = 'required'
    })
end

function _M.__:attemptLogin(request)

    return self:guard():attempt(self:credentials(request), request:has('remember'))
end

function _M.__:credentials(request)

    return request:only(self:username(), 'password')
end

function _M.__:sendLoginResponse(request)
    
    request.session:regenerate()
    -- self:clearLoginAttempts(request)

    return self:authenticated(request, self:guard():user())
        or redirect():intended(self:redirectPath())
end

function _M.__:authenticated(request, user)
end

function _M.__:sendFailedLoginResponse(request)

    local errors = {[self:username()] = trans('auth.failed')}
    if request.expectsJson then
        
        return response():json(errors, 422)
    end
    
    return redirect():back():withInput(request:only(self:username(), 'remember')):withErrors(errors)
end

function _M:username()

    return 'email'
end

function _M:logout(c)

    local request = c.req
    self:guard():logout()
    local session = request.session
    session:flush()
    session:regenerate()
    
    return redirect('/')
end

function _M.__:guard()

    return app.auth:guard()
end

return _M

