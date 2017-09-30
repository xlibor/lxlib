
local lx, _M = oo{ 
    _cls_ = '',
    _ext_ = 'box'
}

local app, lf, tb, str, new = lx.kit()

function _M:reg()

    self:regDepends()
    self:regUrlGenerator()
    self:regRedirector()
    self:regRouter()
end

function _M:boot()

end

function _M.__:regRouter()

    local router = 'lxlib.routing.router'
    app:single('router', router, function()
        return new(router, app:make('ctlerDispatcher'))
    end)
end

function _M.__:regUrlGenerator()

    app:single('url', function()
        local routes = app.router:getRoutes()
        
        app:instance('routes', routes)
        
        local url = app:make('urlGenerator', routes)

        return url
    end)
end

function _M.__:regRedirector()

    app:keep('redirect', function()
        local redirector = new('redirector', app.url)
        local sessionStore = app:get('session.store')
        if sessionStore then
            redirector:setSession(sessionStore)
        end
        
        return redirector
    end)
end

function _M.__:regDepends()
    
    app:bindFrom('lxlib.routing', {
        'route', 'routeGroup', 'routeCol', 'controller',
        'routeEntry', 'resourceEntry', 'redirector',
        'urlGenerator', 'pipeline',
    })

    app:single('ctlerDispatcher',       'lxlib.routing.dispatcher')

    app:bind('routeBase',               'lxlib.routing.base.route')
    app:single('routeCompiler',         'lxlib.routing.base.routeCompiler')
    app:bind('compiledRoute',           'lxlib.routing.base.compiledRoute')

    app:bindFrom('lxlib.routing.matching', {
        'hostMatcher', 'methodMatcher',
        'schemeMatcher', 'uriMatcher'
    })

    app:single('routeMatchers', function()
        local matchers = {
            new 'methodMatcher',
            new 'schemeMatcher',
            new 'hostMatcher',
            new 'uriMatcher'
        }

        return matchers
    end)

    app:bond('urlRoutable', 'lxlib.routing.bond.urlRoutable')
    app:single('lxlib.routing.bar.replaceBinding')
end

return _M

