
local lx, _M, mt = oo{
    _cls_ = ''
}

local app, lf, tb, str = lx.kit()

-- Handle an incoming request.
-- @param \Illuminate\Http\Request request
-- @param \Closure                 next
-- @return mixed

function _M:handle(request, next)

    local config = app('itemconfig')
    --if the model doesn't exist at all, redirect to 404
    if not config then
        abort(404, 'Page not found')
    end
    --check the permission
    local p = config:getOption('permission')
    --if the user is simply not allowed permission to this model, redirect them to the dashboard
    if not p then
        
        return redirect():route('admin_dashboard')
    end
    --get the settings data if it's a settings page
    if config:getType() == 'settings' then
        config:fetchData(app('admin_field_factory'):getEditFields())
    end
    --otherwise if this is a response, return that
    if is_a(p, 'Illuminate\\Http\\JsonResponse') or is_a(p, 'Illuminate\\Http\\Response') or is_a(p, 'Illuminate\\Http\\RedirectResponse') then
        
        return p
    end
    
    return next(request)
end

return _M

