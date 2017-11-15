
local lx, _M, mt = oo{
    _cls_ = ''
}

local app, lf, tb, str = lx.kit()

-- Handle an incoming request.
-- @param \Illuminate\Http\Request request
-- @param \Closure                 next
-- @return mixed

function _M:handle(request, next)

    local redirectUri
    local redirectKey
    local loginUrl
    local configFactory = app('admin_config_factory')
    --get the admin check closure that should be supplied in the config
    local permission = app:conf('admin.permission')
    local response = permission()
    --if this is a simple false value, send the user to the login redirect
    if not (response) then
        loginUrl = url(app:conf('admin.login_path', 'user/login'))
        redirectKey = app:conf('admin.login_redirect_key', 'redirect')
        redirectUri = request:url()
        
        return redirect():guest(loginUrl):with(redirectKey, redirectUri)
    elseif is_a(response, 'Illuminate\\Http\\JsonResponse') or is_a(response, 'Illuminate\\Http\\Response') then
        
        return response
    elseif is_a(response, 'Illuminate\\Http\\RedirectResponse') then
        redirectKey = app:conf('admin.login_redirect_key', 'redirect')
        redirectUri = request:url()
        
        return response:with(redirectKey, redirectUri)
    end
    
    return next(request)
end

return _M

