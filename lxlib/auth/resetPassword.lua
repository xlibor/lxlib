
local lx, _M = oo{
    _cls_ = ''
}

local app, lf, tb, str = lx.kit()

local Password = lx.use('lxlib.auth.password.const')
local H = lx.h
local redirect, trans, bcrypt = H.redirect, H.trans, H.bcrypt

function _M:showResetForm(request, token)

    return view('auth.password.reset')
        :with{token = token, email = request.email}
end

function _M:reset(request)

    self:validate(request, self:rules(), self:validationErrorMessages())
    
    local response = self:broker():reset(self:credentials(request), function(user, password)
        self:resetPassword(user, password)
    end)
    
    local ret
    if response == Password.passwordReset then
        ret = self:sendResetResponse(response)
    else
        ret = self:sendResetFailedResponse(request, response)
    end

    return ret
end

function _M.__:rules()

    return {
        token = 'required',
        email = 'required|email',
        password = 'required|confirmed|min:6'
    }
end

function _M.__:validationErrorMessages()

    return {}
end

function _M.__:credentials(request)

    return request:only('email', 'password', 'password_confirmation', 'token')
end

function _M.__:resetPassword(user, password)

    user:forceFill{
        password = bcrypt(password),
        remember_token = str.random(60)
    }:save()

    self:guard():login(user)
end

function _M.__:sendResetResponse(response)

    return redirect(self:redirectPath()):with('status', trans(response))
end

function _M.__:sendResetFailedResponse(request, response)

    return redirect():back()
        :withInput(request:only('email'))
        :withErrors({email = trans(response)})
end

function _M:broker()

    return app.password:broker()
end

function _M.__:guard()

    return app('auth'):guard()
end

return _M

