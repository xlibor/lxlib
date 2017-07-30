
local lx, _M, mt = oo{
    _cls_   = '',
    _bond_  = 'countable'
}

local app, lf, tb, str, new = lx.kit()
local throw = lx.throw

local slen = string.len
local routerVerbs

function _M:new()

    local this = {
        routes = {},
        allRoutes = {},
        nameList = {},
        actionList = {},
        uriList = {}
    }

    oo(this, mt)

    return this
end

function _M:ctor()

    local router = app:getBaseMt('router')

    routerVerbs = router.verbs
end

function _M:count()

    local allRoutes = self.allRoutes

    return tb.count(allRoutes)
end

function _M:match(req)

    local method = req.method
    local routes = self:get(method)

    local route = self:check(routes, req)

    if route then
        return route:bind(req)
    end

    local others = self:checkForAlternateVerbs(req)
    if #others > 0 then

        return self:getRouteForMethods(req, others)
    else
        throw('notFoundHttpException', 'not matched any route')
    end
end

function _M:check(routes, req, includingMethod)

    includingMethod = lf.needTrue(includingMethod)

    for _, route in pairs(routes) do
        if route:matches(req, includingMethod) then 

            return route
        end
    end
end

function _M:checkForAlternateVerbs(req)

    local methods = tb.diff(routerVerbs, {req.method})
    local others = {}

    for _, method in ipairs(methods) do

        if self:check(self:get(method), req, false) then
            tapd(others, method)
        end
    end

    return others
end

function _M:getRouteForMethods(req, methods)

    if req.method == 'options' then
        return new('route', 'options', req.path, function()
            return new(
                'response', '', 200, {
                    Allow = str.join(methods, ',')
                }
            )
        end):setBar(lx.n.obj())
    end

    self:methodNotAllowed(req.method, methods)
end

function _M:methodNotAllowed(current, others)

    throw('methodNotAllowedHttpException', current, others)
end

function _M:get(method)

    if not method then
        return self:getRoutes()
    end

    return self.routes[method] or {}
end

function _M:getRoutes()

    local ret = {}
    local allRoutes = self.allRoutes
    for _, v in pairs(allRoutes) do
        tapd(ret, v)
    end

    return ret
end

function _M:add(route)

    self:addToCols(route)
    self:addLookups(route)
    
    return route
end

function _M:addToCols(route)

    local domainAndUri = route:getDomain() .. route:getUri()
 
    local methods = route:getMethods()
    local tRoute

    for _, method in pairs(methods) do
        tRoute = self.routes[method]
        if not tRoute then
            self.routes[method] = {}
        end

        tapd(self.routes[method], route)
        self.allRoutes[method .. domainAndUri] = route
    end

end

function _M:addLookups(route)

    local action = route:getAction()
    local as = action.as
    
    self.uriList[route.uri] = route.uri

    if as then
        self.nameList[as] = route
    end
    
    if action.use then
        self:addToActionList(action, route)
    end
end

function _M:addToNameList(route, name)

    if name then
        self.nameList[name] = route
    end
end

function _M:addToActionList(action, route)

    local key = str.trim(action.use, '\\')
 
    self.actionList[key] = route
end

function _M:getByName(name)

    return self.nameList[name]
end

function _M:hasNamedRoute(name)

    return self:getByName(name) and true or false
end

function _M:hasUri(routeUri)

    return self.uriList[routeUri] and true or false
end

return _M

