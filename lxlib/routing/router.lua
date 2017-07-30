
local lx, _M, mt = oo{
    _cls_ = '',
    verbs = {'get', 'head', 'post', 'put', 'patch', 'delete', 'options'}
}

local app, lf, tb, str, new = lx.kit()

local sgsub, slower = string.gsub, string.lower

function _M:new(disper)

    local this = {
        routes              = new('routeCol'),
        bars                = lx.n.obj(),
        barGroups           = lx.n.obj(),
        groups              = lx.n.obj(),
        patterns            = {},
        binders             = {},
        disper              = disper,
        defaultNamespace    = false,
        currentRoute        = false,
    }

    oo(this, mt)

    return this
end

function _M:dispatch(req)

    self:dispatchToRoute(req)

    return self:prepareResponse(req)
end

function _M:dispatchToRoute(req)

    local route = self:findRoute(req)

    req.route = route

    self:runRoute(route, req)
end

function _M:findRoute(req)

    local route = self.routes:match(req)
    if route then
        self.currentRoute = route
    end

    return route
end

function _M:current()

    return self.currentRoute
end

function _M:currentRouteNamed(name)

    local currentRoute = self.currentRoute
    if not currentRoute then
        return false
    end

    return currentRoute:named(name)
end

function _M:currentRouteName()

    local currentRoute = self.currentRoute

    return currentRoute and currentRoute:getName()
end

function _M:is(...)

    local patterns = lf.needArgs(...)
    local name = self:currentRouteName()
    if not name then return end
    for _, pattern in ipairs(patterns) do
        if str.is(name, pattern) then
            return true
        end
    end

    return false
end

function _M:prepareResponse(req)

    local ctx = ngx.ctx.lxAppContext
    local response = ctx.resp
    response:prepare(req)

    return response
end

function _M:runRoute(route, req)

    if route then
        route:run(req)
    else
        error('route is nil')
    end
end

function _M:get(uri, action)

    return self:addRoute({'get', 'head'}, uri, action)

end

function _M:post(uri, action)

    return self:addRoute({'post'}, uri, action)
 
end

function _M:head(uri, action)

    return self:addRoute({'head'}, uri, action)
end

function _M:put(uri, action)

    return self:addRoute({'put'}, uri, action)
end

function _M:patch(uri, action)

    return self:addRoute({'patch'}, uri, action)
end

function _M:delete(uri, action)

    return self:addRoute({'delete'}, uri, action)
end

function _M:add(uri, action)

    return self:addRoute({'get', 'post'}, uri, action)
end

function _M:match(methods, uri, action)

    return self:addRoute(methods, uri, action)
end

function _M:any(uri, action)

    return self:addRoute({'get', 'head', 'post', 'put', 'patch', 'delete'}, uri, action)
end

function _M:pattern(key, pattern)

    local vt = type(key)
    if vt == 'table' then
        local patterns = key
        for key, pattern in pairs(patterns) do
            self.patterns[key] = pattern
        end
    else
        self.patterns[key] = pattern
    end
end

function _M:getPatterns()

    return self.patterns
end

function _M:bind(key, binder)

    local vt = type(binder)
    if vt == 'string' then
        local class, method = str.parseCallback(binder, 'bind')
        local cls = new('class', class)
        if cls:is('model') then
            binder = self:bindModel(class)
        else
            binder = function(value, route)
                local obj = app:make(class)
                local action = obj[method]

                return action(obj, value, route)
            end
        end
    end

    key = str.gsub(key, '%-', '_')
    self.binders[key] = binder
end

function _M.__:bindModel(class, callback)

    return function(value)

        local instance = app:make(class)
        local model = instance
            :where(instance:getRouteKeyName(), value):first()
        if model then
            return model
        end
        if callback then
            return callback(value)
        end

        lx.throw('modelNotFoundException', class)
    end
end

function _M:model(key, class, callback)

    local binder = self:bindModel(class, callback)
    key = str.gsub(key, '%-', '_')
    self.binders[key] = binder
end

function _M:replaceBinding(route)

    if not next(self.binders) then
        return
    end

    local params = route:getParams()
    local binder

    for k, v in pairs(params) do
        binder = self.binders[k]
        if binder then
            v = self:performBinding(binder, v, route)
            route:updateParam(k, v)
        end
    end
end

function _M.__:performBinding(binder, value, route)

    return binder(value, route)
end

function _M:group(attrs, cb)

    self:updateGroups(attrs)

    if cb then
        cb(self)
    end

    self.groups:pop()
 
end

function _M:updateGroups(attrs)

    local rg = new('routeGroup', attrs)
 
    if not rg.key then
        rg.key = 'group_' .. math.random(1, 9999)
    end
    local groups = self.groups
    if groups:count() > 0 then
        rg:mergeWith(self.groups:last())
    else
        if rg.namespace then
            if self.defaultNamespace then
                rg.namespace = self.defaultNamespace .. '.' .. rg.namespace
            end
        else
            rg.namespace = self.defaultNamespace
        end
    end

    self.groups:add(rg, rg.key)
 
end

function _M:hasGroup()

    if self.groups:count() > 0 then 
        return true
    end
end

function _M.__:checkMethods(methods)

    local hasGet, hasHead
    for i, v in ipairs(methods) do
        v = slower(v)
        methods[i] = v
        if not hasGet and v == 'get' then hasGet = true end
        if not hasHead and v == 'head' then hasHead = true end
    end

    if hasGet and not hasHead then
        tapd(methods, 'head')
    end

end

function _M:addRoute(methods, uri, action)

    self:checkMethods(methods)
    local routes = self.routes
    local route = self:createRoute(methods, uri, action)
    routes:add(route)

    return route
end
 
function _M:createRoute(methods, uri, action)
     
    uri = str.neat(uri, '/')

    local route = self:newRoute(methods, uri, action)
     
    if self:hasGroup() then
        self:mergeGroupIntoRoute(route)
    else
        route:setNamespace(self.defaultNamespace)
    end

    self:updateRouteBar(route)

    self:addWhereToRoute(route)

    return route
end

function _M:addWhereToRoute(route)

    local where = route.action.where or {}
    where = tb.merge(self.patterns, where)
    route.wheres = where
end

function _M:mergeGroupIntoRoute(route)

    local rg = self.groups:last()
    rg:mergeInto(route)

end

function _M:updateRouteBar(route)

    local newBars = lx.n.obj()
    local bars = route.action.bar
    if not bars then
        route.action.bar = newBars
        return
    end

    bars = lf.needList(bars)

    if next(bars) then
        local routerBars = self.bars
        local bar, barList

        local barGroups = self.barGroups
        if barGroups:count() > 0 then
            barGroups = barGroups:all()
        else
            barGroups = {}
        end

        for _, v in ipairs(bars) do
            local vt, barValue
            v, barValue = self:parseBarParams(v)
            bar = routerBars:get(v)
            if bar then
                if type(bar) == 'function' then
                    barValue = bar
                    bar = v
                end
                newBars:add(barValue, bar)
            else
                barList = barGroups[v]
                if barList then
                    for _, vv in ipairs(barList) do
                        bar, barValue = self:parseBarParams(vv)
                        newBars:add(barValue, bar)
                    end
                else
                    newBars:add(barValue, v)
                end
            end

        end
    end

    route.action.bar = newBars
end

function _M.__:parseBarParams(bar)

    local barValue, paramsStr, barParams
    local vt = type(bar)

    if vt == 'string' then
        if str.find(bar, ':') then
            bar, paramsStr = str.divide(bar, ':')
            barValue = str.split(paramsStr, ',')
        else
            barValue = bar
        end
    elseif vt == 'function' then
        barValue = bar
    end

    return bar, barValue
end

function _M:getRouteBar(nick)

    local bar 
    local routerBars = self.bars
 
    bar = routerBars:get(nick)
    if bar then

        return bar
    end
 
    local barGroups = self.barGroups
    if barGroups:count() > 0 then
        barGroups = barGroups:all()
 
        local barList = barGroups[nick]
        if barList then
            return barList
        end
    end

end

function _M:newRoute(methods, uri, action)

    action = action or {}
    local route = new('route', methods, uri, action)
    
    return route
end

function _M:setBars(bars)

    local nick, bar
    for k, v in pairs(bars) do
        nick, bar = v[1], v[2]
        self.bars:set(nick, bar)
    end
end

function _M:setBar(name, bar)

    self.bars:set(name, bar)
end

function _M:setBarGroups(barGroups)

    local nick, group
    
    for k, v in pairs(barGroups) do
        nick, group = k, v
        self.barGroups:set(nick, group)
    end
end

function _M:setBarGroup(nick, group)

    self.barGroups:set(nick, group)
end

function _M:getRoutes()

    return self.routes
end

function _M:resources(resources)

    for name, controller in pairs(resources) do
        self:resource(name, controller)
    end
end

function _M:resource(name, controller, options)

    options = options or {}

    local registrar = new('resourceEntry', self)

    registrar:reg(name, controller, options)
end

function _M:_run_(method)

    return function(self, ...)
        local entry = new('routeEntry', self)

        return entry:attribute(method, ...)
    end

end

return _M

