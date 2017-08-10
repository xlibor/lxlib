
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
        local routes = app:get('router'):getRoutes()
        
        app:instance('routes', routes)
        
        local url = app:make('urlGenerator', routes,
            app:rebinding('request', self:requestRebinder(), true)
        )
        url:setSessionResolver(function()
            
            return app:get('session')
        end)
        
        app:rebinding('routes', function(routes)
            app:get('url'):setRoutes(routes)
        end)

        return url
    end)
end

function _M.__:regRedirector()

    app:keep('redirect', function()
        local redirector = new('redirector', app.url)
        
        if app['session.store'] then
            redirector:setSession(app['session.store'])
        end
        
        return redirector
    end)
end

function _M.__:requestRebinder()

    return function(request)
        app.url:setRequest(request)
    end
end

function _M.__:regDepends()
    
    app:bindFrom('lxlib.routing', {
        'route', 'routeGroup', 'routeCol', 'controller',
        'routeEntry', 'resourceEntry', 'redirector'
    })
     
    app:single('ctlerDispatcher',     'lxlib.routing.dispatcher')

    app:bind('routeBase',             'lxlib.routing.base.route')
    app:single('routeCompiler',     'lxlib.routing.base.routeCompiler')
    app:bind('compiledRoute',         'lxlib.routing.base.compiledRoute')

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

    app:single('urlGenerator', 'lxlib.routing.urlGenerator')
    app:bond('urlRoutable', 'lxlib.routing.bond.urlRoutable')
    app:single('lxlib.routing.bar.replaceBinding')
end

return _M

