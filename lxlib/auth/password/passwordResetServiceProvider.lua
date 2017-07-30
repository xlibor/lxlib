
local lx, _M, mt = oo{
    _cls_ = '',
    _ext_ = 'box'
}

local app, lf, tb, str = lx.kit()

function _M:new()

    local this = {
    }
end

function _M:register()

    self:registerPasswordBroker()
end

function _M.__:registerPasswordBroker()

    app:single('auth.password', function(app)
        
        return new('passwordBrokerManager',app)
    end)
    app:bind('auth.password.broker', function(app)
        
        return app:make('auth.password'):broker()
    end)
end

function _M:provides()

    return {'auth.password', 'auth.password.broker'}
end

return _M

