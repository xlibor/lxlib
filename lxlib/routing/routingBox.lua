
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
        return new(router, app:make('lxlib.routing.dispatcher'))
    end)
end

function _M.__:regUrlGenerator()

    app:single('url', function()
        local routes = app.router:getRoutes()
        
        app:instance('routes', routes)
        
        local url = app:make('lxlib.routing.urlGenerator', routes)

        return url
    end)
end

function _M.__:regRedirector()

    app:keep('redirect', function()
        local redirector = new('lxlib.routing.redirector', app.url)
        local sessionStore = app:get('session.store')
        if sessionStore then
            redirector:setSession(sessionStore)
        end
        
        return redirector
    end)
end

function _M.__:regDepends()
    
    app:bindFrom('lxlib.routing', {
        'route', 'routeGroup', 'controller',
        'pipeline',
    })

    app:single('lxlib.routing.dispatcher')
    app:single('lxlib.routing.base.routeCompiler')
    app:single('routeMatchers', function()
        local matchers = {
            new 'lxlib.routing.matching.methodMatcher',
            new 'lxlib.routing.matching.schemeMatcher',
            new 'lxlib.routing.matching.hostMatcher',
            new 'lxlib.routing.matching.uriMatcher'
        }

        return matchers
    end)

    app:bond('urlRoutable', 'lxlib.routing.bond.urlRoutable')
    app:single('lxlib.routing.bar.replaceBinding')
end

return _M

