
local lx, _M = oo{
    _cls_ = '',
    _ext_ = 'box'
}

local app, lf, tb, str, new = lx.kit()

function _M:reg()

    self:regDepends()
    self:regBonds()
    self:regAuthenticator()
    self:regUserResolver()
    self:regAccessGate()
    self:regRequestRebindHandler()
    self:regBars()
end

function _M:boot()

    self:regEvents()
    
    self:command('lxlib.auth.console', {
        ['make/auth'] = 'makeAuthCmd@run'
    })

    local custom = app:get('view.blade.custom')

    custom:add('can', function(text)
        return fmt('if App.gate:check(%s) then ', text)
    end)
    custom:add('canelse', function()
        return 'else '
    end)
    custom:add('endcan', function()

        return 'end;'
    end)

end

function _M.__:regEvents()

    app:listen('auth.sessionGuard', 'lxlib.auth.event.listener')
end

function _M.__:regDepends()
    
    app:bindFrom('lxlib.auth', {
        ['recaller']                    = 'recaller',
        ['auth.createUserProvider']     = 'createUserProvider',
        ['auth.guardHelper']            = 'guardHelper',
        ['auth.authenticateUser']       = 'authenticateUser',
        ['auth.regUser']                = 'regUser',
        ['auth.sendPwdResetEmail']      = 'sendPwdResetEmail',
        ['auth.redirectUser']           = 'redirectUser',
        ['auth.genericUser']            = 'genericUser',
        authenticatable                 = 'authenticatable',
        ['auth.user']                   = 'user'
    })

    app:bindFrom('lxlib.auth.guard', {
        ['auth.requestGuard']           = 'request',
        ['auth.sessionGuard']           = 'session',
        ['auth.tokenGuard']             = 'token'
    })

    app:bindFrom('lxlib.auth.provider', {
        ['auth.dbUserProvider']         = 'dbUser',
        ['auth.ormUserProvider']        = 'ormUser'
    })

    app:bindFrom('lxlib.auth.access', {
        handleAuthorization         = 'handleAuthorization',
        authAccessResponse          = 'response',
        authorizable                = 'authorizable',
        authorizeRequest            = 'authorizeRequest'
    })

    app:bindFrom('lxlib.auth.password', {
        canResetPassword            = 'canResetPassword'
    })

    app:bindFrom('lxlib.auth.excp', {
        'authenticationException',
        'authorizationException'
    })

end

function _M.__:regBonds()

    app:bond('authGuardBond', 'lxlib.auth.bond.guard')
    app:bondFrom('lxlib.auth.bond', {
        authenticatableBond     = 'authenticatable',
        authorizableBond        = 'access.authorizable',
        authGateBond            = 'access.gate',
        authFactoryBond         = 'factory',
        authUserProviderBond    = 'userProvider',
        statefulGuard           = 'statefulGuard',
        supportBasicAuth        = 'supportBasicAuth',
        canResetPasswordBond    = 'canResetPassword'
    })
end

function _M.__:regBars()

    app:single('lxlib.auth.bar.authenticate')
    app:single('lxlib.auth.bar.authenticateWithBasicAuth')
    app:single('lxlib.auth.bar.authorize')
end

function _M.__:regAuthenticator()

    local authManager = 'lxlib.auth.authManager'
    app:single('auth', authManager, function()
        
        app['auth.loaded'] = true
        
        return new(authManager)
    end)

    app:single('auth.driver', function()
        
        return app.auth:guard()
    end)
end

function _M.__:regUserResolver()

    app:bind('authenticatableBond', function()

        return lf.call(app.auth.userResolver)
    end)
end

function _M.__:regAccessGate()

    local gate = 'lxlib.auth.access.gate'
    app:single('gate', gate, function()
        
        return new(gate, function()
            
            return lf.call(app.auth.userResolver)
        end)
    end)
end

function _M.__:regRequestRebindHandler()

    app:rebinding('request', function(request)

        request:setUserResolver(function(guard)
            
            return lf.call(app.auth.userResolver, guard)
        end)
    end)
end

return _M

