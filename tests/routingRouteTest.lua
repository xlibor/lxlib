
local lx, _Ms = oos{}

local app, lf, tb, str = lx.kit()
local use, new

local _mv = {}
local Request = lx.use('request')
local ReplaceBinding = 'lxlib.routing.bar.replaceBinding'
local RouteGroup = lx.use('routeGroup')
local ResourceEntry = lx.use('resourceEntry')

local _M = _Ms{
    _cls_ = 'main',
    _ext_ = 'unit.testCase'
}

function _M:ctor()

    if not use then
        use, new = lx.ns(self)
    end
end

function _M.__:getRouter()

    app:cancelShare('request', 'response')
    
    app:instance('router', nil)
    app:instance('context', nil)
    local router = lx.new('router')
    local response = lx.new('response')
    ngx.ctx.lxAppContext = lx.new('context')
    local ctx = app:ctx()
    ctx.bars = {}
    ctx.resp = response

    return router
end

function _M:testBasicDispatchingOfRoutes()

    local router = self:getRouter()
    router:get('foo/bar', function()
        
        return 'hello'
    end)

    local t = router:dispatch(Request.create('foo/bar', 'get'))

    self:assertEquals('hello', router:dispatch(Request.create('/foo/bar', 'get')):getContent())

    router = self:getRouter()
    router:get('foo/bar', function()

        return 'hello'
    end)
    self:assertEquals('hello', router:dispatch(Request.create('foo/bar', 'get')):getContent())

    router = self:getRouter()
    local route = router:get('foo/bar', {domain = 'api.{name}.bar', function(c, name)

        return name
    end})
    route = router:get('foo/bar', {domain = 'api.{name}.baz', function(c, name)

        return name
    end})

    self:assertEquals('taylor', router:dispatch(Request.create('http://api.taylor.bar/foo/bar', 'get')):getContent())
    self:assertEquals('dayle', router:dispatch(Request.create('http://api.dayle.baz/foo/bar', 'get')):getContent())

    router = self:getRouter()
    route = router:get('foo/{age}', {domain = 'api.{name}.bar', function(c, name, age)
        
        return name .. age
    end})
    self:assertEquals('taylor25', router:dispatch(Request.create('http://api.taylor.bar/foo/25', 'get')):getContent())
    
    router = self:getRouter()
    router:get('foo/bar', function()
        
        return 'hello'
    end)
    router:post('foo/bar', function()
        
        return 'post hello'
    end)
    self:assertEquals('hello', router:dispatch(Request.create('foo/bar', 'get')):getContent())
    self:assertEquals('post hello', router:dispatch(Request.create('foo/bar', 'POST')):getContent())
    
    router = self:getRouter()
    router:get('foo/{bar}', function(c, name)
        
        return name
    end)
    self:assertEquals('taylor', router:dispatch(Request.create('foo/taylor', 'get')):getContent())
    
    router = self:getRouter()
    router:get('foo/{name}/{age?}', function(c, name, age)

        return name .. age
    end):default('age', 25)
    self:assertEquals('taylor25', router:dispatch(Request.create('foo/taylor', 'get')):getContent())
    
    router = self:getRouter()
    router:get('foo/{name}/boom/{age?}/{location?}', function(c, name, age, location)
        
        return name .. age .. location
    end):default{age = 25, location = 'AR'}
    self:assertEquals('taylor30AR', router:dispatch(Request.create('foo/taylor/boom/30', 'get')):getContent())
    
    router = self:getRouter()
    router:get('{name}/{age?}', function(c, name, age)
        
        return name .. age
    end):default{age = 25}

    self:assertEquals('taylor25', router:dispatch(Request.create('taylor', 'get')):getContent())

    router = self:getRouter()
    router:get('{age?}', function(c, age)
        
        return age
    end):default{age = 25}
    self:assertEquals('25', router:dispatch(Request.create('/', 'get')):getContent())
    self:assertEquals('30', router:dispatch(Request.create('30', 'get')):getContent())

    router = self:getRouter()
    router:get('{name?}/{age?}', {as = 'foo', function(c, name, age)
        
        return name .. age
    end}):default{age = 25, name = 'taylor'}
    self:assertEquals('taylor25', router:dispatch(Request.create('/', 'get')):getContent())
    self:assertEquals('fred25', router:dispatch(Request.create('fred', 'get')):getContent())
    self:assertEquals('fred30', router:dispatch(Request.create('fred/30', 'get')):getContent())
    self:assertTrue(router:currentRouteNamed('foo'))
    self:assertTrue(router:is('foo'))
    self:assertFalse(router:is('bar'))

    router = self:getRouter()
    router:patch('foo/bar', {as = 'foo', function()
        
        return 'bar'
    end})
    self:assertEquals('bar', router:dispatch(Request.create('foo/bar', 'PATCH')):getContent())
    self:assertEquals('foo', router:currentRouteName())

    router = self:getRouter()
    router:get('foo/bar', function()
        
        return 'hello'
    end)
    self:assertEmpty(router:dispatch(Request.create('foo/bar', 'HEAD')):getContent())
    router = self:getRouter()
    router:any('foo/bar', function()
        
        return 'hello'
    end)
    self:assertEmpty(router:dispatch(Request.create('foo/bar', 'HEAD')):getContent())
    router = self:getRouter()
    router:get('foo/bar', function()
        
        return 'first'
    end)
    router:get('foo/bar', function()
        
        return 'second'
    end)

    self:assertEquals('first', router:dispatch(Request.create('foo/bar', 'get')):getContent())
 
    router = self:getRouter()
    router:get('foo/bar', {boom = 'auth', function()
        
        return 'closure'
    end})
    self:assertEquals('closure', router:dispatch(Request.create('foo/bar', 'get')):getContent())
end

function _M:testClosureMiddleware()

    local router = self:getRouter()
    local middleware = function(context, next)

        return 'caught'
    end
    local route = router:get('foo/bar', {bar = middleware, function()
        
        return 'hello'
    end})

    self:assertEquals('caught', router:dispatch(Request.create('foo/bar', 'get')):getContent())
end

function _M:testDefinedClosureMiddleware()

    local router = self:getRouter()
    router:setBar('foo', function(context, next)

        return 'caught'
    end)
    router:get('foo/bar', {bar = 'foo', function()
        
        return 'hello'
    end})

    self:assertEquals('caught', router:dispatch(Request.create('foo/bar', 'get')):getContent())
end

function _M:testControllerClosureMiddleware()

    local router = self:getRouter()
    router:setBar('foo', function(context, next)
        context:setArg('foo-middleware', 'foo-middleware')
        
        return next(context)
    end)
    router:get('foo/bar', {use = 'routeTestClosureMiddlewareController@index', bar = 'foo' })
    self:assertEquals('index-foo-middleware-controller-closure', router:dispatch(Request.create('foo/bar', 'get')):getContent())
end

-- function _M:testFluentRouting()

--     local router = self:getRouter()
--     router:get('foo/bar'):uses(function()
        
--         return 'hello'
--     end)
--     self:assertEquals('hello', router:dispatch(Request.create('foo/bar', 'get')):getContent())
    -- router:post('foo/bar'):uses(function()
        
    --     return 'hello'
    -- end)
    -- self:assertEquals('hello', router:dispatch(Request.create('foo/bar', 'POST')):getContent())
    -- router:get('foo/bar'):uses(function()
        
    --     return 'middleware'
    -- end):middleware('routeTestControllerMiddleware')
    -- self:assertEquals('middleware', router:dispatch(Request.create('foo/bar')):getContent())
    -- self:assertContains('routeTestControllerMiddleware', router:getCurrentRoute():middleware())
    -- router:get('foo/bar')
    -- router:dispatch(Request.create('foo/bar', 'get'))
-- end

-- function _M:testFluentRoutingWithControllerAction()

--     local router = self:getRouter()
--     router:get('foo/bar'):uses('routeTestControllerStub@index')
--     self:assertEquals('Hello World', router:dispatch(Request.create('foo/bar', 'get')):getContent())
--     router = self:getRouter()
--     router:group({namespace = 'app'}, function(router)
--         router:get('foo/bar'):uses('routeTestControllerStub@index')
--     end)
--     local action = router:getRoutes():getRoutes()[0]:getAction()
--     self:assertEquals('app.routeTestControllerStub@index', action['controller'])
-- end

function _M:testMiddlewareGroups()

    local router = self:getRouter()

    router:setBarGroup('web', {'routingTestMiddlewareGroupOne', 'routingTestMiddlewareGroupTwo:taylor'})
    local route = router:get('foo/bar', {bar = 'web', function()
        
        return 'hello'
    end})

    self:assertEquals('caught taylor', router:dispatch(Request.create('foo/bar', 'get')):getContent())
end

function _M:testMiddlewareGroupsCanReferenceOtherGroups()

    local router = self:getRouter()

    router:setBarGroup('web', {'routingTestMiddlewareGroupOne', 'routingTestMiddlewareGroupTwo:abigail'})
    router:get('foo/bar', {bar = 'web', function()
        
        return 'hello'
    end})
    self:assertEquals('caught abigail', router:dispatch(Request.create('foo/bar', 'get')):getContent())
end

function _M:testFluentRouteNamingWithinAGroup()

    local router = self:getRouter()
    router:group({as = 'foo'}, function()
        router:get('bar', function()
            
            return 'bar'
        end):name('bar')
    end)
    self:assertEquals('bar', router:dispatch(Request.create('bar', 'get')):getContent())

    self:assertEquals('foo.bar', router:currentRouteName())
end

function _M:testOptionsResponsesAreGeneratedByDefault()

    local router = self:getRouter()
    router:get('foo/bar', function()
        
        return 'hello'
    end)
    router:post('foo/bar', function()
        
        return 'hello'
    end)
    local response = router:dispatch(Request.create('foo/bar', 'OPTIONS'))

    self:assertEquals(200, response:getStatusCode())

    self:assertEquals('get,head,post', response.headers:get('Allow'))
end

function _M:testHeadDispatcher()

    local router = self:getRouter()
    local r = router:match({'get', 'post'}, 'foo', function()
        
        return 'bar'
    end)

    local response = router:dispatch(Request.create('foo', 'OPTIONS'))
    self:assertEquals(200, response:getStatusCode())
    self:assertEquals('get,head,post', response.headers:get('Allow'))
    response = router:dispatch(Request.create('foo', 'HEAD'))
    self:assertEquals(200, response:getStatusCode())
    self:assertEmpty(response:getContent())

    router = self:getRouter()
    router:match({'get'}, 'foo', function()
        
        return 'bar'
    end)
    response = router:dispatch(Request.create('foo', 'OPTIONS'))
    self:assertEquals(200, response:getStatusCode())
    self:assertEquals('get,head', response.headers:get('Allow'))

    router = self:getRouter()
    router:match({'POST'}, 'foo', function()
        
        return 'bar'
    end)
    response = router:dispatch(Request.create('foo', 'OPTIONS'))
    self:assertEquals(200, response:getStatusCode())
    self:assertEquals('post', response.headers:get('Allow'))
end

function _M:testNonGreedyMatches()

    local route = lx.new('route', 'get', 'images/{id}.{ext}', function()
    end)
    local request1 = Request.create('images/1.png', 'get')
    self:assertTrue(route:matches(request1))
    route:bind(request1)
    self:assertTrue(route:hasParameter('id'))
    self:assertFalse(route:hasParameter('foo'))
    self:assertEquals('1', route:parameter('id'))
    self:assertEquals('png', route:parameter('ext'))
    local request2 = Request.create('images/12.png', 'get')
    self:assertTrue(route:matches(request2))
    route:bind(request2)
    self:assertEquals('12', route:parameter('id'))
    self:assertEquals('png', route:parameter('ext'))
    -- Test parameter() default value
    route = lx.new('route', 'get', 'foo/{foo?}', function()
    end)
    local request3 = Request.create('foo', 'get')
    self:assertTrue(route:matches(request3))
    route:bind(request3)
    self:assertEquals('bar', route:parameter('foo', 'bar'))
end

function _M:testRouteParametersDefaultValue()

    local router = self:getRouter()
    router:get('foo/{bar?}', {use = 'routeTestControllerWithParameterStub@returnParameter'}):default('bar', 'foo')
    self:assertEquals('foo', router:dispatch(Request.create('foo', 'get')):getContent())
    router:get('foo/{bar?}', {use = 'routeTestControllerWithParameterStub@returnParameter'}):default('bar', 'foo')
    self:assertEquals('bar', router:dispatch(Request.create('foo/bar', 'get')):getContent())
    router:get('foo/{bar?}', function(bar)
        
        return bar
    end):default('bar', 'foo')
    self:assertEquals('foo', router:dispatch(Request.create('foo', 'get')):getContent())
end

function _M:testControllerCallActionMethodParameters()

    local router = self:getRouter()
    -- Has one argument but receives two
    _mv.controller_callAction_parameters = nil
    local prefix = str.random()
    router:get(prefix .. '/{one}/{two}', 'routeTestAnotherControllerWithParameterStub@oneArgument')
    router:dispatch(Request.create(prefix .. '/one/two', 'get'))
    self:assertEquals({one = 'one', two = 'two'}, _mv.controller_callAction_parameters)
    -- Has two arguments and receives two
    _mv.controller_callAction_parameters = nil
    prefixr = str.random()
    router:get(prefix .. '/{one}/{two}', 'routeTestAnotherControllerWithParameterStub@twoArguments')
    router:dispatch(Request.create(prefix .. '/one/two', 'get'))
    self:assertEquals({one = 'one', two = 'two'}, _mv.controller_callAction_parameters)
    -- Has two arguments but with different names from the ones passed from the route
    _mv.controller_callAction_parameters = nil
    prefix = str.random()
    router:get(prefix .. '/{one}/{two}', 'routeTestAnotherControllerWithParameterStub@differentArgumentNames')
    router:dispatch(Request.create(prefix .. '/one/two', 'get'))
    self:assertEquals({one = 'one', two = 'two'}, _mv.controller_callAction_parameters)
    -- Has two arguments with same name but argument order is reversed
    _mv.controller_callAction_parameters = nil
    prefix = str.random()
    router:get(prefix .. '/{one}/{two}', 'routeTestAnotherControllerWithParameterStub@reversedArguments')
    router:dispatch(Request.create(prefix .. '/one/two', 'get'))
    self:assertEquals({one = 'one', two = 'two'}, _mv.controller_callAction_parameters)
    -- No route parameters while method has parameters
    _mv.controller_callAction_parameters = nil
    prefix = str.random()
    router:get(prefix .. '', 'routeTestAnotherControllerWithParameterStub@oneArgument')
    router:dispatch(Request.create(prefix, 'get'))
    self:assertEquals({}, _mv.controller_callAction_parameters)

    router = self:getRouter()
    -- With model bindings
    _mv.controller_callAction_parameters = nil

    prefix = str.random()
    local route = router:get(prefix .. '/{user}/{team?}', {bar = ReplaceBinding, use = 'routeTestAnotherControllerWithParameterStub@withModels'})

    router:bind('team', 'routingTestTeamModel')
    router:dispatch(Request.create(prefix .. '/1/abc', 'get'))

    local values = tb.values(_mv.controller_callAction_parameters)
    self:assertEquals(1, values[1])
    self:assertInstanceOf('model', values[2])
end

function _M:testLeadingParamDoesntReceiveForwardSlashOnEmptyPath()

    local router = self:getRouter()
    local outer_one = 'abc1234'
    -- a string that is not one we're testing
   local r =  router:get('{one?}', {use = function(c, one)
        outer_one = one
        
        return one
    end, where = {one = '.'}})
    self:assertEquals('a/b/c/', router:dispatch(Request.create('/a/b/c')):getContent())
    self:assertEquals('a/b/c/', outer_one)
    self:assertEquals('foo/', router:dispatch(Request.create('/foo', 'get')):getContent())
    self:assertEquals('foo/bar/baz/', router:dispatch(Request.create('/foo/bar/baz', 'get')):getContent())
end

function _M:testRoutesDontMatchNonMatchingPathsWithLeadingOptionals()

    local router = self:getRouter()
    router:get('{baz?}', function(age)
        
        return age
    end)
    self:assertException('notFoundHttpException', function()
        self:assertEquals('25', router:dispatch(Request.create('foo/bar', 'get')):getContent())
    end)
end

function _M:testRoutesDontMatchNonMatchingDomain()

    local router = self:getRouter()
    local route = router:get('foo/bar', {domain = 'api.foo.bar', function()
        
        return 'hello'
    end})
    self:assertException('notFoundHttpException', function()
        self:assertEquals('hello', router:dispatch(Request.create('http://api.baz.boom/foo/bar', 'get')):getContent())
    end)
end

function _M:testMatchesMethodAgainstRequests()

    -- Basic
    local router = self:getRouter()
    local request = Request.create('foo/bar', 'get')
    local route = lx.new('route', 'get', 'foo/{bar}', function()
    end)
    self:assertTrue(route:matches(request))

    local router = self:getRouter()
    request = Request.create('foo/bar', 'get')
    route = lx.new('route', 'get', 'foo', function()
    end)
    self:assertFalse(route:matches(request))
    -- Method checks
    
    request = Request.create('foo/bar', 'get')
    route = lx.new('route', 'get', 'foo/{bar}', function()
    end)
    self:assertTrue(route:matches(request))
    request = Request.create('foo/bar', 'POST')
    route = lx.new('route', 'get', 'foo', function()
    end)
    self:assertFalse(route:matches(request))
    -- Domain checks
    
    request = Request.create('http://something.foo.com/foo/bar', 'get')
    route = lx.new('route', 'get', 'foo/{bar}', {domain = '{foo}.foo.com', function()
    end})
    self:assertTrue(route:matches(request))
    request = Request.create('http://something.bar.com/foo/bar', 'get')
    route = lx.new('route', 'get', 'foo/{bar}', {domain = '{foo}.foo.com', function()
    end})
    self:assertFalse(route:matches(request))
    -- HTTPS checks
    
    request = Request.create('https://foo.com/foo/bar', 'get')
    route = lx.new('route', 'get', 'foo/{bar}', {https = true, function()
    end})
    self:assertTrue(route:matches(request))
    request = Request.create('https://foo.com/foo/bar', 'get')
    route = lx.new('route', 'get', 'foo/{bar}', {https = true, function()
    end})
    self:assertTrue(route:matches(request))
    request = Request.create('http://foo.com/foo/bar', 'get')
    route = lx.new('route', 'get', 'foo/{bar}', {https = true, function()
    end})
    self:assertFalse(route:matches(request))
    -- HTTP checks
    
    request = Request.create('https://foo.com/foo/bar', 'get')
    route = lx.new('route', 'get', 'foo/{bar}', {http = true, function()
    end})
    self:assertFalse(route:matches(request))
    request = Request.create('http://foo.com/foo/bar', 'get')
    route = lx.new('route', 'get', 'foo/{bar}', {http = true, function()
    end})
    self:assertTrue(route:matches(request))
    request = Request.create('http://foo.com/foo/bar', 'get')
    route = lx.new('route', 'get', 'foo/{bar}', {function()
    end})
    self:assertTrue(route:matches(request))
end

function _M:testWherePatternsProperlyFilter()

    local router = self:getRouter()

    local request = Request.create('foo/123', 'get')
    local route = lx.new('route', 'get', 'foo/{bar}', function()
    end)
    route:where('bar', '[0-9]+')
    self:assertTrue(route:matches(request))
    request = Request.create('foo/123abc', 'get')
    route = lx.new('route', 'get', 'foo/{bar}', function()
    end)
    route:where('bar', '[0-9]+')
    self:assertFalse(route:matches(request))

    request = Request.create('foo/123abc', 'get')
    route = lx.new('route', 'get', 'foo/{bar}', {where = {bar = '[0-9]+'}, function()
    end})
    route:where('bar', '[0-9]+')
    self:assertFalse(route:matches(request))
    -- Optional
    
    request = Request.create('foo/123', 'get')
    route = lx.new('route', 'get', 'foo/{bar?}', function()
    end)
    route:where('bar', '[0-9]')
    self:assertTrue(route:matches(request))
    request = Request.create('foo/123', 'get')
    route = lx.new('route', 'get', 'foo/{bar?}', {where = {bar = '[0-9]+'}, function()
    end})
    route:where('bar', '[0-9]')
    self:assertTrue(route:matches(request))
    request = Request.create('foo/123', 'get')
    route = lx.new('route', 'get', 'foo/{bar?}/{baz?}', function()
    end)
    route:where('bar', '[0-9]')
    self:assertTrue(route:matches(request))
    request = Request.create('foo/123/foo', 'get')
    route = lx.new('route', 'get', 'foo/{bar?}/{baz?}', function()
    end)
    route:where('bar', '[0-9]')
    self:assertTrue(route:matches(request))
    request = Request.create('foo/123abc', 'get')
    route = lx.new('route', 'get', 'foo/{bar?}', function()
    end)
    route:where('bar', '[0-9]+')
    self:assertFalse(route:matches(request))
end

function _M:testDotDoesNotMatchEverything()

    local router = self:getRouter()

    local route = lx.new('route', 'get', 'images/{id}.{ext}', function()
    end)
    local request1 = Request.create('images/1.png', 'get')
    self:assertTrue(route:matches(request1))
    route:bind(request1)
    self:assertEquals('1', route:parameter('id'))
    self:assertEquals('png', route:parameter('ext'))
    local request2 = Request.create('images/12.png', 'get')
    self:assertTrue(route:matches(request2))
    route:bind(request2)
    self:assertEquals('12', route:parameter('id'))
    self:assertEquals('png', route:parameter('ext'))
end

function _M:testRouteBinding()

    local router = self:getRouter()
    router:get('foo/{bar}', {bar = ReplaceBinding, use = function(c, name)
        
        return name
    end})
    router:bind('bar', function(value)
        
        return str.upper(value)
    end)
    self:assertEquals('TAYLOR', router:dispatch(Request.create('foo/taylor', 'get')):getContent())
end

function _M:testRouteClassBinding()

    local router = self:getRouter()
    router:get('foo/{bar}', {bar = ReplaceBinding, use = function(c, name)
        
        return name
    end})
    router:bind('bar', 'routeBindingStub')
    self:assertEquals('TAYLOR', router:dispatch(Request.create('foo/taylor', 'get')):getContent())
end

function _M:testRouteClassMethodBinding()

    local router = self:getRouter()
    router:get('foo/{bar}', {bar = ReplaceBinding, use = function(c, name)
        
        return name
    end})
    router:bind('bar', 'routeBindingStub@find')
    self:assertEquals('dragon', router:dispatch(Request.create('foo/Dragon', 'get')):getContent())
end

function _M:testModelBinding()

    local router = self:getRouter()
    router:get('foo/{bar}', {bar = ReplaceBinding, use = function(c, name)
        
        return name
    end})
    router:model('bar', 'routeModelBindingStub')
    self:assertEquals('TAYLOR', router:dispatch(Request.create('foo/taylor', 'get')):getContent())
end

function _M:testModelBindingWithNullReturn()

    local router = self:getRouter()
    router:get('foo/{bar}', {bar = ReplaceBinding, use = function(name)
        
        return name
    end})
    router:model('bar', 'routeModelBindingNullStub')
    self:assertException('modelNotFoundException', function()
        router:dispatch(Request.create('foo/taylor', 'get')):getContent()
    end)
end

function _M:testModelBindingWithCustomNullReturn()

    local router = self:getRouter()
    router:get('foo/{bar}', {bar = ReplaceBinding, use = function(c, name)
        
        return name
    end})
    router:model('bar', 'routeModelBindingNullStub', function()
        
        return 'missing'
    end)
    self:assertEquals('missing', router:dispatch(Request.create('foo/taylor', 'get')):getContent())
end

function _M:testModelBindingWithBindingClosure()

    local router = self:getRouter()
    router:get('foo/{bar}', {bar = ReplaceBinding, use = function(c, name)
        
        return name
    end})
    router:model('bar', 'routeModelBindingNullStub', function(value)
        
        return lx.new('routeModelBindingClosureStub'):findAlternate(value)
    end)
    self:assertEquals('tayloralt', router:dispatch(Request.create('foo/TAYLOR', 'get')):getContent())
end

function _M:testModelBindingWithCompoundParameterName()

    local router = self:getRouter()
    router:resource('foo-bar', 'routeTestResourceControllerWithModelParameter', {bar = ReplaceBinding})
    router:model('foo-bar', 'routingTestUserModel')
    self:assertEquals('12345', router:dispatch(Request.create('foo-bar/12345', 'get')):getContent())
end

function _M:testModelBindingWithCompoundParameterNameAndRouteBinding()

    local router = self:getRouter()
    router:model('foo_bar', 'routingTestUserModel')

    router:resource('foo-bar', 'routeTestResourceControllerWithModelParameter', {bar = ReplaceBinding})

    self:assertEquals('12345', router:dispatch(Request.create('foo-bar/12345', 'get')):getContent())
end

function _M:testGroupMerging()

    local old = {prefix = 'foo/bar/'}
    self:assertEquals({prefix = 'foo/bar/baz', namespace = nil, where = {}, bar = {}}, RouteGroup.merge({prefix = 'baz'}, old))
    old = {domain = 'foo'}
    self:assertEquals({
        domain = 'baz',
        prefix = nil,
        namespace = nil,
        where = {},
        bar = {}
    }, RouteGroup.merge({domain = 'baz'}, old))

    old = {as = 'foo.'}
    self:assertEquals({
        as = 'foo.bar',
        prefix = nil,
        namespace = nil,
        where = {},
        bar = {}
    }, RouteGroup.merge({as = 'bar'}, old))
    old = {where = {var1 = 'foo', var2 = 'bar'}}
    self:assertEquals({prefix = nil, namespace = nil, where = {var1 = 'foo', var2 = 'baz', var3 = 'qux'}, bar = {}}, RouteGroup.merge({where = {var2 = 'baz', var3 = 'qux'}}, old))
    old = {}
    self:assertEquals({prefix = nil, namespace = nil, where = {var1 = 'foo', var2 = 'bar'}, bar = {}}, RouteGroup.merge({where = {var1 = 'foo', var2 = 'bar'}}, old))
end

function _M:testRouteGrouping()

    -- getPrefix() method
    
    local router = self:getRouter()
    router:group({prefix = 'foo'}, function()
        router:get('bar', function()
            
            return 'hello'
        end)
    end)
    local routes = router:getRoutes()
    routes = routes:getRoutes()
    self:assertEquals('foo', routes[1]:getPrefix())
end

function _M:testRouteGroupingWithAs()

    local router = self:getRouter()
    router:group({prefix = 'foo', as = 'foo.'}, function()
        router:get('bar', {as = 'bar', function()
            
            return 'hello'
        end})
    end)
    local routes = router:getRoutes()
    local route = routes:getByName('foo.bar')
    self:assertEquals('foo/bar', route.uri)
end

function _M:testNestedRouteGroupingWithAs()

    -- nested with all layers present
    
    local router = self:getRouter()
    router:group({prefix = 'foo', as = 'Foo::'}, function()
        router:group({prefix = 'bar', as = 'Bar::'}, function()
            router:get('baz', {as = 'baz', function()
                
                return 'hello'
            end})
        end)
    end)
    local routes = router:getRoutes()
    local route = routes:getByName('Foo::Bar::baz')
    self:assertEquals('foo/bar/baz', route.uri)
    -- nested with layer skipped
    
    router = self:getRouter()
    router:group({prefix = 'foo', as = 'Foo::'}, function()
        router:group({prefix = 'bar'}, function()
            router:get('baz', {as = 'baz', function()
                
                return 'hello'
            end})
        end)
    end)
    routes = router:getRoutes()
    route = routes:getByName('Foo::baz')
    self:assertEquals('foo/bar/baz', route.uri)
end

function _M:testRouteMiddlewareMergeWithMiddlewareAttributesAsStrings()

    local router = self:getRouter()
    router:group({prefix = 'foo', bar = 'boo:foo'}, function()
        router:get('bar', {bar = 'baz:gaz', function()
            
            return 'hello'
        end})
    end)
    local routes = router:getRoutes():getRoutes()

    local route = routes[1]

    self:assertEquals({boo = {'foo'}, baz = {'gaz'}}, route:getBar():all())
end

function _M:testRoutePrefixing()

    -- Prefix route
    
    local router = self:getRouter()
    router:get('foo/bar', function()
        
        return 'hello'
    end)
    local routes = router:getRoutes()
    routes = routes:getRoutes()
    routes[1]:setPrefix('prefix')
    self:assertEquals('prefix/foo/bar', routes[1].uri)
    -- Use empty prefix
    
    router = self:getRouter()
    router:get('foo/bar', function()
        
        return 'hello'
    end)
    routes = router:getRoutes()
    routes = routes:getRoutes()
    routes[1]:setPrefix('/')

    self:assertEquals('foo/bar', routes[1].uri)
    -- Prefix homepage
    
    router = self:getRouter()
    router:get('/', function()
        
        return 'hello'
    end)
    routes = router:getRoutes()
    routes = routes:getRoutes()
    routes[1]:setPrefix('prefix')
    self:assertEquals('prefix', routes[1].uri)
end

function _M:testMergingControllerUses()

    local router = self:getRouter()
    router:group({namespace = 'namespace'}, function()
        router:get('foo/bar', 'controller@action')
    end)
    local routes = router:getRoutes():getRoutes()
    local action = routes[1]:getAction()
    self:assertEquals({'namespace.controller', 'action'}, {action.use, action.by})
    router = self:getRouter()
    router:group({namespace = 'namespace'}, function()
        router:group({namespace = 'nested'}, function()
            router:get('foo/bar', 'controller@action')
        end)
    end)
    routes = router:getRoutes():getRoutes()
    action = routes[1]:getAction()

    self:assertEquals({'namespace.nested.controller', 'action'}, {action.use, action.by})
    router = self:getRouter()
    router:group({prefix = 'baz'}, function()
        router:group({namespace = 'namespace'}, function()
            router:get('foo/bar', 'controller@action')
        end)
    end)
    routes = router:getRoutes():getRoutes()
    action = routes[1]:getAction()
    self:assertEquals({'namespace.controller', 'action'}, {action.use, action.by})
end

function _M:testInvalidActionException()

    local router = self:getRouter()
    router:get('/', {use = 'routeTestControllerStub'})
    router:dispatch(Request.create('/'))
end

function _M:testResourceRouting()

    local router = self:getRouter()
    router:resource('foo', 'FooController')
    local routes = router:getRoutes()
 
    self:assertCount(11, routes)
    router = self:getRouter()
    router:resource('foo', 'FooController', {only = {'update'}})
    routes = router:getRoutes()
    self:assertCount(1, routes)
    router = self:getRouter()
    router:resource('foo', 'FooController', {only = {'show', 'destroy'}})
    routes = router:getRoutes()
    self:assertCount(3, routes)
    router = self:getRouter()
    router:resource('foo', 'FooController', {except = {'show', 'destroy'}})
    routes = router:getRoutes()
    self:assertCount(8, routes)
    router = self:getRouter()
    router:resource('foo-bars', 'FooController', {only = {'show'}})
    routes = router:getRoutes()
    self:assertTrue(routes:hasUri('foo-bars/{foo_bars}'))
    router = self:getRouter()
    router:resource('foo-bar.foo-baz', 'FooController', {only = {'show'}})
    routes = router:getRoutes()
    routes = routes:getRoutes()
    self:assertEquals('foo-bar/{foo_bar}/foo-baz/{foo_baz}', routes[1].uri)
    router = self:getRouter()
    router:resource('foo-bars', 'FooController', {only = {'show'}, as = 'prefix'})
    routes = router:getRoutes()
    routes = routes:getRoutes()
    self:assertEquals('foo-bars/{foo_bars}', routes[1].uri)
    self:assertEquals('prefix.foo-bars.show', routes[1]:getName())
    ResourceEntry.setVerbs({create = 'ajouter', edit = 'modifier'})
    router = self:getRouter()
    router:resource('foo', 'FooController')
    routes = router:getRoutes()
    self:assertEquals('foo/ajouter', routes:getByName('foo.create').uri)
    self:assertEquals('foo/{foo}/modifier', routes:getByName('foo.edit').uri)
end

function _M:testResourceRoutingParameters()

    ResourceEntry.setSingularParameters()
    local router = self:getRouter()
    router:resource('foos', 'FooController')
    router:resource('foos.bars', 'FooController')
    local routes = router:getRoutes()

    self:assertTrue(routes:hasUri('foos/{foo}'))
    self:assertTrue(routes:hasUri('foos/{foo}/bars/{bar}'))
    ResourceEntry.setParameters({foos = 'oof', bazs = 'b'})
    router = self:getRouter()
    router:resource('bars.foos.bazs', 'FooController')
    routes = router:getRoutes()
    self:assertTrue(routes:hasUri('bars/{bar}/foos/{oof}/bazs/{b}'))
    ResourceEntry.setParameters()
    ResourceEntry.setSingularParameters(false)
    router = self:getRouter()
    router:resource('foos', 'FooController', {parameters = 'singular'})
    router:resource('foos.bars', 'FooController', {parameters = 'singular'})
    routes = router:getRoutes()
    self:assertTrue(routes:hasUri('foos/{foo}'))
    self:assertTrue(routes:hasUri('foos/{foo}/bars/{bar}'))
    router = self:getRouter()
    router:resource('foos.bars', 'FooController', {parameters = {foos = 'foo', bars = 'bar'}})
    routes = router:getRoutes()
    self:assertTrue(routes:hasUri('foos/{foo}/bars/{bar}'))
end

function _M:testResourceRouteNaming()

    local router = self:getRouter()
    router:resource('foo', 'FooController')
    self:assertTrue(router:getRoutes():hasNamedRoute('foo.index'))
    self:assertTrue(router:getRoutes():hasNamedRoute('foo.show'))
    self:assertTrue(router:getRoutes():hasNamedRoute('foo.create'))
    self:assertTrue(router:getRoutes():hasNamedRoute('foo.store'))
    self:assertTrue(router:getRoutes():hasNamedRoute('foo.edit'))
    self:assertTrue(router:getRoutes():hasNamedRoute('foo.update'))
    self:assertTrue(router:getRoutes():hasNamedRoute('foo.destroy'))
    router = self:getRouter()
    router:resource('foo.bar', 'FooController')
    self:assertTrue(router:getRoutes():hasNamedRoute('foo.bar.index'))
    self:assertTrue(router:getRoutes():hasNamedRoute('foo.bar.show'))
    self:assertTrue(router:getRoutes():hasNamedRoute('foo.bar.create'))
    self:assertTrue(router:getRoutes():hasNamedRoute('foo.bar.store'))
    self:assertTrue(router:getRoutes():hasNamedRoute('foo.bar.edit'))
    self:assertTrue(router:getRoutes():hasNamedRoute('foo.bar.update'))
    self:assertTrue(router:getRoutes():hasNamedRoute('foo.bar.destroy'))
    router = self:getRouter()
    router:resource('prefix/foo.bar', 'FooController')
    self:assertTrue(router:getRoutes():hasNamedRoute('foo.bar.index'))
    self:assertTrue(router:getRoutes():hasNamedRoute('foo.bar.show'))
    self:assertTrue(router:getRoutes():hasNamedRoute('foo.bar.create'))
    self:assertTrue(router:getRoutes():hasNamedRoute('foo.bar.store'))
    self:assertTrue(router:getRoutes():hasNamedRoute('foo.bar.edit'))
    self:assertTrue(router:getRoutes():hasNamedRoute('foo.bar.update'))
    self:assertTrue(router:getRoutes():hasNamedRoute('foo.bar.destroy'))
    router = self:getRouter()
    router:resource('foo', 'FooController', {names = {index = 'foo', show = 'bar'}})
    self:assertTrue(router:getRoutes():hasNamedRoute('foo'))
    self:assertTrue(router:getRoutes():hasNamedRoute('bar'))
    router = self:getRouter()
    router:resource('foo', 'FooController', {names = 'bar'})
    self:assertTrue(router:getRoutes():hasNamedRoute('bar.index'))
    self:assertTrue(router:getRoutes():hasNamedRoute('bar.show'))
    self:assertTrue(router:getRoutes():hasNamedRoute('bar.create'))
    self:assertTrue(router:getRoutes():hasNamedRoute('bar.store'))
    self:assertTrue(router:getRoutes():hasNamedRoute('bar.edit'))
    self:assertTrue(router:getRoutes():hasNamedRoute('bar.update'))
    self:assertTrue(router:getRoutes():hasNamedRoute('bar.destroy'))
end

function _M:testRouterPatternSetting()

    local router = self:getRouter()
    router:pattern('test', 'pattern')
    self:assertEquals({test = 'pattern'}, router:getPatterns())
    router = self:getRouter()
    router:pattern({test = 'pattern', test2 = 'pattern2'})
    self:assertEquals({test = 'pattern', test2 = 'pattern2'}, router:getPatterns())
end

function _M:testControllerRouting()

    _mv['route.test.controller.middleware'] = nil
    _mv['route.test.controller.except.middleware'] = nil
    _mv['route.test.controller.middleware.class'] = nil
    _mv['route.test.controller.middleware.parameters.one'] = nil
    _mv['route.test.controller.middleware.parameters.two'] = nil
    local router = self:getRouter()
    router:get('foo/bar', 'routeTestControllerStub@index')
    self:assertEquals('Hello World', router:dispatch(Request.create('foo/bar', 'get')):getContent())
    self:assertTrue(_mv['route.test.controller.middleware'])
    self:assertEquals('lxlib.http.response', _mv['route.test.controller.middleware.class'])
    self:assertEquals(0, _mv['route.test.controller.middleware.parameters.one'])
    self:assertEquals({'foo', 'bar'}, _mv['route.test.controller.middleware.parameters.two'])
    self:assertFalse(_mv['route.test.controller.except.middleware'])
end

function _M:testCallableControllerRouting()

    local router = self:getRouter()
    router:get('foo/bar', 'routeTestControllerCallableStub@bar')
    router:get('foo/baz', 'routeTestControllerCallableStub@baz')
    self:assertEquals('bar', router:dispatch(Request.create('foo/bar', 'get')):getContent())
    self:assertEquals('baz', router:dispatch(Request.create('foo/baz', 'get')):getContent())
end

function _M:testControllerMiddlewareGroups()

    _mv['route.test.controller.middleware'] = nil
    _mv['route.test.controller.middleware.class'] = nil
    local router = self:getRouter()
    router:setBarGroup('web', {'routeTestControllerMiddleware', 'routeTestControllerMiddlewareTwo'})
    router:get('foo/bar', 'routeTestControllerMiddlewareGroupStub@index')
    self:assertEquals('caught', router:dispatch(Request.create('foo/bar', 'get')):getContent())
    self:assertTrue(_mv['route.test.controller.middleware'])
    self:assertEquals('lxlib.http.response', _mv['route.test.controller.middleware.class'])
end

function _M:testImplicitBindings()

    local router = self:getRouter()
    router:get('foo/{bar}', {bar = ReplaceBinding, use = function(c, bar)
        self:assertEquals('routingTestUserModel', bar.__nick)
        
        return bar.value
    end})
    router:model('bar', 'routingTestUserModel')
    self:assertEquals('taylor', router:dispatch(Request.create('foo/taylor', 'get')):getContent())
end

function _M:testImplicitBindingsWithOptionalParameter()

    local router = self:getRouter()
    router:model('bar', 'routingTestUserModel')
    router:get('foo/{bar?}', {bar = ReplaceBinding, use = function(c, bar)
        self:assertEquals('routingTestUserModel', bar.__nick)
        
        return bar.value
    end})
    self:assertEquals('taylor', router:dispatch(Request.create('foo/taylor', 'get')):getContent())
    router = self:getRouter()
    router:model('bar', 'routingTestUserModel')
    router:get('bar/{foo?}', function(c, foo)
        self:assertEmpty(foo)
    end)
    router:dispatch(Request.create('bar', 'get')):getContent()
end

local _M = _Ms{
    _cls_ = 'routeTestControllerStub',
    _ext_ = 'controller'
}

function _M:ctor()

    self:setBar('routeTestControllerMiddleware')
    self:setBar('routeTestControllerParameterizedMiddlewareOne:0')
    self:setBar('routeTestControllerParameterizedMiddlewareTwo:foo,bar')
    self:setBar('routeTestControllerExceptMiddleware', {except = 'index'})
end

function _M:index()

    return 'Hello World'
end

local _M = _Ms{
    _cls_ = 'routeTestControllerCallableStub',
    _ext_ = 'controller'
}

function _M:callAction(context, method, arguments)

    arguments = arguments or {}
    
    return method
end

local _M = _Ms{
    _cls_ = 'routeTestControllerMiddlewareGroupStub',
    _ext_ = 'controller'
}

function _M:ctor()

    self:setBar('web')
end

function _M:index()

    return 'Hello World'
end

local _M = _Ms{
    _cls_ = 'routeTestControllerWithParameterStub',
    _ext_ = 'controller'
}

function _M:returnParameter(c, bar)

    bar = bar or ''
    
    return bar
end

local _M = _Ms{
    _cls_ = 'routeTestAnotherControllerWithParameterStub',
    _ext_ = 'controller'
}

function _M:callAction(c, method, parameters)

    _mv.controller_callAction_parameters = parameters
end

function _M:oneArgument(c, one)

end

function _M:twoArguments(c, one, two)

end

function _M:differentArgumentNames(c, bar, baz)

end

function _M:reversedArguments(c, two, one)

end

function _M:withModels(c, user, team)

end

local _M = _Ms{
    _cls_ = 'routeTestResourceControllerWithModelParameter',
    _ext_ = 'controller'
}

function _M:show(c, fooBar)

    return fooBar.value
end

local _M = _Ms{
    _cls_ = 'routeTestClosureMiddlewareController',
    _ext_ = 'controller'
}

function _M:ctor()

    self:setBar(function(context, next)
        next(context)
        local req, resp = context()

        return resp:getContent() .. '-' .. req['foo-middleware'] .. '-controller-closure'
    end)
end

function _M:index()

    return 'index'
end

local _M = _Ms{
    _cls_ = 'routeTestControllerMiddleware'
}

function _M:handle(context, next)

    _mv['route.test.controller.middleware'] = true
    next(context)
    local response = context.resp
    _mv['route.test.controller.middleware.class'] = response.__cls
    
    return response
end

local _M = _Ms{
    _cls_ = 'routeTestControllerMiddlewareTwo'
}

function _M:handle(context, next)

    return lx.new('response', 'caught')
end

local _M = _Ms{
    _cls_ = 'routeTestControllerParameterizedMiddlewareOne'
}

function _M:handle(context, next, parameter)

    _mv['route.test.controller.middleware.parameters.one'] = parameter
    
    return next(context)
end

local _M = _Ms{
    _cls_ = 'routeTestControllerParameterizedMiddlewareTwo'
}

function _M:handle(context, next, parameter1, parameter2)

    _mv['route.test.controller.middleware.parameters.two'] = {parameter1, parameter2}
    
    return next(context)
end

local _M = _Ms{
    _cls_ = 'routeTestControllerExceptMiddleware'
}

function _M:handle(context, next)

    _mv['route.test.controller.except.middleware'] = true
    
    return next(context)
end

local _M = _Ms{
    _cls_ = 'routeBindingStub'
}

function _M:bind(value, route)

    return str.upper(value)
end

function _M:find(value, route)

    return str.lower(value)
end

local _M = _Ms{
    _cls_ = 'routeModelBindingStub',
    _ext_ = 'model'
}

function _M:ctor()

    self.table = 'stub'
end

function _M:getRouteKeyName()

    return 'id'
end

function _M:where(key, value)

    self.value = value
    
    return self
end

function _M:first()

    return str.upper(self.value)
end

local _M = _Ms{
    _cls_ = 'routeModelBindingNullStub'
}

function _M:getRouteKeyName()

    return 'id'
end

function _M:where(key, value)

    return self
end

function _M:first()

end

local _M = _Ms{
    _cls_ = 'routeModelBindingClosureStub'
}

function _M:findAlternate(value)

    return str.lower(value) .. 'alt'
end

local _M = _Ms{
    _cls_ = 'routingTestMiddlewareGroupOne'
}

function _M:handle(context, next)
    
    return next(context)
end

local _M = _Ms{
    _cls_ = 'routingTestMiddlewareGroupTwo'
}

function _M:handle(context, next, who)

    who = who or 'unknown'
    return  'caught ' .. who
end

local _M = _Ms{
    _cls_ = 'routingTestUserModel',
    _ext_ = 'model'
}

function _M:getRouteKeyName()

    return 'id'
end

function _M:where(key, value)

    self.value = value
    
    return self
end

function _M:first()

    return self
end

function _M:firstOrFail()

    return self
end

local _M = _Ms{
    _cls_ = 'routingTestTeamModel',
    _ext_ = 'model'
}

function _M:ctor()

    self.table = 'team'
end

function _M:getRouteKeyName()

    return 'id'
end

function _M:where(key, value)

    self.value = value
    
    return self
end

function _M:first()

    return self
end

function _M:firstOrFail()

    return self
end

local _M = _Ms{
    _cls_ = 'routingTestExtendedUserModel',
    _ext_ = 'routingTestUserModel'
}

local _M = _Ms{
    _cls_ = ''
}

function _M:__invoke()

    return 'hello'
end

return _Ms

