
local _M = {
    _cls_ = ''
}

local mt = { __index = _M }

local lx = require('lxlib')
local app, lf, tb, str, new = lx.kit()

local sfind, ssub, gsub, smatch, slen = string.find, string.sub, string.gsub, string.match, string.len

local router, disper

function _M._init_()

    if not app:isCmdMode() then
        router = app:get('router')
    end
    disper = app:get('router').disper
end

function _M:new(methods, uri, action, bar)

    local this = {
        uri = uri,
        methods = lf.needList(methods),
        action = action,
        defaults = {},
        wheres = {},
        parameters = {},
        parameterNames = {},
        compiled = nil
    }

    setmetatable(this, mt)

    this:checkAction()

    return this
end

function _M:ctor()

    _M.matchers = app:get('routeMatchers')

    local methodDict = tb.flip(self.methods, true)

    self.methodDict = methodDict
end

function _M:checkAction()

    local action = self.action
    local actionType = type(action)
    local ctler, ctlerMethod, cb
    local vt

    if actionType == 'string' then
        if sfind(action, '@') then
            ctler, ctlerMethod = str.div(action, '@')
        end
        action = { use = ctler, by = ctlerMethod }
    elseif actionType == 'function' then
        action = { cb = action }
    elseif actionType == 'table' then
        cb = action[1]
        if cb then
            table.remove(action, 1)
            action.cb = cb
        end
        ctler = action.use
        if ctler then
            vt = type(ctler)
            if vt == 'string' then
                if sfind(ctler, '@') then
                    ctler, ctlerMethod = str.div(ctler, '@')
                    action.use = ctler
                    action.by = ctlerMethod
                end
            elseif vt == 'function' then
                action.use = nil
                action.cb = ctler
            end
        end
    end
    
    local bar = action.bar
    if bar then
        local vt = type(bar)
        if vt == 'string' then
            bar = {bar}
        elseif vt == 'function' then
            local barName = str.random(8)
            local router = router or app:get('router')
            router:setBar(barName, bar)
            bar = {barName}
        end
    else
        bar = {}
    end

    action.bar = bar
    self.action = action
end

function _M:getPrefix()

    local prefix = self.action.prefix

    return prefix
end

function _M:setPrefix(prefix)

    if prefix then
        local uri = str.rtrim(prefix, '/') .. '/' .. str.ltrim(self.uri, '/')
        self.uri = str.trim(uri, '/')
    end
    
    return self
end

function _M:setBar(bar)
    
    self.action.bar = bar
    return self
end

_M.bar = _M.setBar

function _M:name(name)

    local as = self.action.as
    if as then
        self.action.as = as .. '.' .. name
    else
        self.action.as = name
    end

    local router = router or app:get('router')
    router.routes:addToNameList(self, self.action.as)

    return self
end

function _M:named(name)

    if not name then return end
    local defedName = self:getName()
    if not defedName then return false end

    return defedName == name
end

function _M:setNamespace(namespace)

    if namespace then
        if self.action.use then
            self.action.use = namespace .. '.' .. self.action.use
        end
    end
end

function _M:where(name, expression)

    local nameType = type(name)
    if nameType == 'string' then
        self.wheres[name] = expression
    elseif nameType == 'table' then
        for k, v in pairs(name) do 
            self.wheres[k] = v
        end
    end

    return self
end

function _M:default(name, value)

    local nameType = type(name)
    if nameType == 'string' then
        self.defaults[name] = value
    elseif nameType == 'table' then
        for k, v in pairs(name) do 
            self.defaults[k] = v
        end
    end

    return self
end

function _M:matches(req, includingMethod)

    self:compileRoute()

    includingMethod = lf.needTrue(includingMethod)

    local matchers = self:getMatchers()

    for _, matcher in ipairs(matchers) do
        if not matcher:match(self, req, includingMethod) then
            return false
        end
    end

    return true
end

function _M:validate(req)

    local compiled = self.compiled
    local pattern = compiled.pathRegex

    local path = req.path
    if ssub(path, -1) ~= '/' then
        path = path .. '/'
    end

    local pathMatched = sfind(path, pattern)
     
    return pathMatched
end

function _M:getMatchers()

    local matchers = _M.matchers
    if matchers then
        return matchers
    end

end

function _M:compileRoute()

    local compiled = self.compiled
    if compiled then return end

    local optionals
    local uri = self.uri
    local domain = self:getDomain()
    local wheres = self.wheres

    local baseRoute = new('routeBase', uri, optionals, wheres, {}, domain)
    
    self.compiled = baseRoute:compile()
end

function _M:bind(req)

    self.params = nil
    self:bindParameters(req)

    return self
end

function _M:bindParameters(req)

    local pathParameters, pathVars = self:bindPathParameters(req)
    local hostParameters, hostVars = self:bindHostParameters(req)

    if #hostVars > 0 then
        for i, v in ipairs(pathVars) do
            tapd(hostParameters, pathParameters[i])
            tapd(hostVars, v)
        end
        self.parameters = hostParameters
        self.parameterNames = hostVars
    else
        self.parameters = pathParameters
        self.parameterNames = pathVars
    end
end

function _M:bindPathParameters(req)

    local compiled = self.compiled
    local pattern = compiled.pathRegex
    local vars = compiled.pathVars

    local path = req.path

    if ssub(path, 1, 1) ~= '/' then
        path = '/' .. path
    end

    local matches = { smatch(path, pattern) }
    local parameters = self:replaceDefault(matches, vars)
    if #vars == 0 then
        parameters = {}
    end

    return parameters, vars
end

function _M:bindHostParameters(req)

    local compiled = self.compiled
    local pattern = compiled.hostRegex
    local vars = compiled.hostVars

    local host = req.host

    local matches = { smatch(host, pattern) }
    local parameters = self:replaceDefault(matches, vars)
    if #vars == 0 then
        parameters = {}
    end

    return parameters, vars
end

function _M:updateParam(key, value)

    local params = self:getParams()
    params[key] = value
    for i, name in ipairs(self.parameterNames) do
        if name == key then
            self.parameters[i] = value
            break
        end
    end
end

function _M:param(key, default)

    local params = self:getParams()
    local t = tb.get(params, key)
    if t and default and slen(t) == 0 then
        return default
    end

    return t
end

_M.parameter = _M.param

function _M:getParams()

    if not self.params then
        self.params = tb.combine(self.parameterNames, self.parameters)
    end

    return self.params
end

function _M:hasParameter(name)

    return not lf.isNil(self:param(name))
end

function _M:replaceDefault(matches, vars)

    local defaults = self.defaults
    local key, value
    for k, v in pairs(matches) do
        v = v or ''
        if slen(v) == 0 then
            key = vars[k]
            value = defaults[key]
            if value then
                matches[k] = value
            end
        end
    end

    return matches
end

function _M:run(req)

    local action = self.action
    local ctler, ctlerMethod, as, cb = 
        action.use, action.by or 'index', action.as, action.cb

    if ctler then
        self:runCtler(req, ctler, ctlerMethod)
    else
        if cb then
            self:runCallable(req, cb)
        end
    end
end

function _M:runCallable(req, callback)

    local params = self.parameters
    local context = app:ctx()
    if not rawget(context, 'req') then
        context.req = req
    end
    local params = self.parameters
    local context = app:ctx()
    local pl = app:make('pipeline', app)
    local bars = self:getBar()

    if bars:count() > 0 then
        pl:send(context):through(bars):deal(function()
            local ret = callback(context, unpack(params))

            if ret then
                context:output(ret)
            end
        end)
    else
        local ret = callback(context, unpack(params))

        if ret then
            context:output(ret)
        end
    end
end

function _M:runCtler(req, ctler, ctlerMethod)

    disper:dispatch(self, req, ctler, ctlerMethod)
end

function _M:getName()

    return self.action.as
end

function _M:getBar()

    return self.action.bar
end

function _M:getDomain()

    return self.action.domain or ''
end

function _M:getUri()
    
    return self.uri or ''
end

function _M:getMethods()
    
    return self.methods or {}
end

function _M:getAction()
    
    return self.action
end

function _M:domain()

    return self.action.domain
end

function _M:httpOnly()

    local httpOnly = self.action.http

    return httpOnly
end

function _M:httpsOnly()

    local httpsOnly = self.action.https

    return httpsOnly
end

function _M:secure()

    return self:httpsOnly()
end

return _M

