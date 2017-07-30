
local lx, _M = oo{
    _cls_ = ''
}

local app, lf, tb, str = lx.kit()

local Password = lx.use('lxlib.auth.password.const')
local trans, back = lx.h.trans, lx.h.back

function _M:showLinkRequestForm(c)

    return c:view('auth.password.email')
end

function _M:sendResetLinkEmail(request)

    self:validate(request, {email = 'required|email'})
    
    local response = self:broker():sendResetLink(request:only('email'))
    
    local ret
    if response == Password.resetLinkSent then
        self:sendResetLinkResponse(response)
    else
        self:sendResetLinkFailedResponse(request, response)
    end
end

function _M.__:sendResetLinkResponse(response)

    return back():with('status', trans(response))
end

function _M.__:sendResetLinkFailedResponse(request, response)

    return back():withErrors{email = trans(response)}
end

function _M:broker()

    return app.password:broker()
end

return _M

