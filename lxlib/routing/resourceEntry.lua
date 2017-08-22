
local lx, _M, mt = oo{
    _cls_ = '',
    _static_ = {
        parameterMap = {},
        singularParameters = true,
        verbs = {
            create  = 'create',
            edit    = 'edit'
        }
    }
}

local app, lf, tb, str = lx.kit()

local static, router

function _M._init_(this)

    static = this.static
    
    if not router then
        if not app:isCmdMode() then
            router = app.router
        end
    end
end

function _M:new()

    local this = {
        resourceDefaults = {
            'index', 'create', 'store', 'show',
            'edit', 'update', 'destroy'
        },
        parameters = nil
    }

    return oo(this, mt)
end

function _M:reg(name, controller, options)

    options = options or {}
    if options.parameters and not self.parameters then
        self.parameters = options.parameters
    end
    
    if str.contains(name, '/') then
        self:prefixedResource(name, controller, options)
        
        return
    end
    
    local base = self:getResourceWildcard(str.last(name, '.'))
    local defaults = self.resourceDefaults
    local action
    for _, m in pairs(self:getResourceMethods(defaults, options)) do
        action = 'addResource' .. str.ucfirst(m)
        self[action](self, name, base, controller, options)
    end
end

function _M.__:prefixedResource(name, controller, options)

    local name, prefix = self:getResourcePrefix(name)
    
    local callback = function(router)
        router:resource(name, controller, options)
    end
    
    return self:getRouter():group({prefix = prefix}, callback)
end

function _M.__:getResourcePrefix(name)

    local segments = str.split(name, '/')
    
    local prefix = str.join(tb.slice(segments, 1, -2), '/')
    
    return tb.last(segments), prefix
end

function _M.__:getResourceMethods(defaults, options)

    if options.only then
        
        return tb.same(defaults, lf.needList(options.only))
    elseif options.except then
        
        return tb.diff(defaults, lf.needList(options.except))
    end
    
    return defaults
end

function _M:getResourceUri(resource)

    if not str.has(resource, '.') then
        
        return resource
    end
    
    local segments = str.split(resource, '.')
    local uri = self:getNestedResourceUri(segments)
    
    return str.replace(uri,
        '/{' .. self:getResourceWildcard(tb.last(segments)) .. '}',
         ''
    )
end

function _M.__:getNestedResourceUri(segments)

    return str.join(tb.map(segments, function(s)
        
        return s .. '/{' .. self:getResourceWildcard(s) .. '}'
    end), '/')
end

function _M.__:getResourceAction(resource, controller, method, options)

    local name = self:getResourceRouteName(resource, method, options)
    local action = {as = name, use = controller .. '@' .. method}
    if options.bar then
        action.bar = options.bar
    end

    return action
end

function _M.__:getResourceRouteName(resource, method, options)

    local name = resource
    local t = options.names
    if t then
        if type(t) == 'string' then
            name = t
        elseif t[method] then
            return t[method]
        end
    end
    
    local prefix = options.as and options.as .. '.' or ''

    if not self:getRouter():hasGroup() then
        
        return prefix .. name .. '.' .. method
    end
    
    return self:getGroupResourceName(prefix, name, method)
end

function _M.__:getGroupResourceName(prefix, resource, method)

    return str.trim(prefix .. resource .. '.' .. method, '.')
end

function _M:getResourceWildcard(value)

    if self.parameters and self.parameters[value] then
        value = self.parameters[value]
    elseif static.parameterMap[value] then
        value = static.parameterMap[value]
    elseif self.parameters == 'singular' or static.singularParameters then
        value = str.singular(value)
    end
    
    return str.replace(value, '-', '_')
end

function _M.__:addResourceIndex(name, base, controller, options)

    local uri = self:getResourceUri(name)
    local action = self:getResourceAction(name, controller, 'index', options)

    return self:getRouter():get(uri, action)
end

function _M.__:addResourceCreate(name, base, controller, options)

    local uri = self:getResourceUri(name) .. '/' .. static.verbs.create
    local action = self:getResourceAction(name, controller, 'create', options)

    return self:getRouter():get(uri, action)
end

function _M.__:addResourceStore(name, base, controller, options)

    local uri = self:getResourceUri(name)
    local action = self:getResourceAction(name, controller, 'store', options)

    return self:getRouter():post(uri, action)
end

function _M.__:addResourceShow(name, base, controller, options)

    local uri = self:getResourceUri(name) .. '/{' .. base .. '}'
    local action = self:getResourceAction(name, controller, 'show', options)

    return self:getRouter():get(uri, action)
end

function _M.__:addResourceEdit(name, base, controller, options)

    local uri = self:getResourceUri(name) .. '/{' .. base .. '}/' .. static.verbs.edit
    local action = self:getResourceAction(name, controller, 'edit', options)

    return self:getRouter():get(uri, action)
end

function _M.__:addResourceUpdate(name, base, controller, options)

    local uri = self:getResourceUri(name) .. '/{' .. base .. '}/update'
    local action = self:getResourceAction(name, controller, 'update', options)
    
    return self:getRouter():post(uri, action)
end

function _M.__:addResourceDestroy(name, base, controller, options)

    local uri = self:getResourceUri(name) .. '/{' .. base .. '}/delete'
    local action = self:getResourceAction(name, controller, 'destroy', options)
    
    return self:getRouter():post(uri, action)
end

function _M.s__.setSingularParameters(singular)

    singular = lf.needTrue(singular)
    static.singularParameters = singular
end

function _M.s__.getParameters()

    return static.parameterMap
end

function _M.s__.setParameters(parameters)

    parameters = parameters or {}
    static.parameterMap = parameters
end

function _M.s__.getVerbs()

    return static.verbs
end

function _M.s__.setVerbs(verbs)

    static.verbs = tb.merge(static.verbs, verbs)
end

function _M.__:getRouter()

    return router or app.router
end

return _M

