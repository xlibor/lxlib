
local lx, _M, mt = oo{
    _cls_ = ''
}

local app, lf, tb, str = lx.kit()

local passthru = tb.l2d{
    'get', 'post', 'put', 'patch', 'delete', 'options', 'any'
}
local allowedAttributes = tb.l2d{
    'as', 'domain', 'bar', 'name', 'namespace', 'ns', 'prefix'
}
local aliases = {name = 'as'}

local router

function _M._init_()

    router = app:get('router')
end

function _M:new()

    local this = {
        attributes = {},
    }

    return oo(this, mt)
end

function _M:attribute(key, value)

    local t = allowedAttributes[key]
    if not t then
        lx.throw('invalidArgumentException',
            'Attribute [' .. key .. '] does not exist.'
        )
    end

    local attr = aliases[key] or key
    self.attributes[attr] = value
    
    return self
end

function _M:resource(name, controller, options)

    options = options or {}
    router:resource(name, controller, tb.merge(self.attributes, options))
end

function _M:group(callback)

    router:group(self.attributes, callback)
end

function _M:match(methods, uri, action)

    return router:match(methods, uri, self:compileAction(action))
end

function _M.__:registerRoute(method, uri, action)

    if not lf.isTbl(action) then
        action = tb.merge(self.attributes, action and {use = action} or {})
    end
    
    return router:__do(method, uri, self:compileAction(action))
end

function _M.__:compileAction(action)

    if not action then
        
        return self.attributes
    end
    if lf.isStr(action) or lf.isFunc(action) then
        action = {use = action}
    end
    
    return tb.merge(self.attributes, action)
end

function _M:_run_(method)

    local t = passthru[method]
    if t then
        return function(self, ...)
            return self:registerRoute(method, ...)
        end
    end
    t = allowedAttributes[method]
    if t then
        return function(self, ...)
            return self:attribute(method, ...)
        end
    end

    lx.throw('badMethodCallException', 'Method [' .. method .. '] does not exist.')
end

return _M

