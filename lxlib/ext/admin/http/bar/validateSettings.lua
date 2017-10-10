
local lx, _M, mt = oo{
    _cls_ = ''
}

local app, lf, tb, str = lx.kit()

-- Handle an incoming request.
-- @param \Illuminate\Http\Request request
-- @param \Closure                 next
-- @return mixed

function _M:handle(request, next)

    local settingsName = request:route():parameter('settings')
    app():singleton('itemconfig', function(app)
        configFactory = app('admin_config_factory')
        
        return configFactory:make(configFactory:getSettingsPrefix() .. settingsName, true)
    end)
    
    return next(request)
end

return _M

