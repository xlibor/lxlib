
local lx, _M, mt = oo{
    _cls_ = ' ArrayLoader',
    _bond_ = 'loaderInterface'
}

local app, lf, tb, str = lx.kit()

function _M:new()

    local this = {
        messages = {}
    }
    
    return oo(this, mt)
end

function _M:load(locale, group, namespace)

    namespace = namespace or '*'
    if self.messages[namespace][locale][group] then
        
        return self.messages[namespace][locale][group]
    end
    
    return {}
end

function _M:addNamespace(namespace, hint)
end

function _M:addMessages(locale, group, messages, namespace)

    namespace = namespace or '*'
    self.messages[namespace][locale][group] = messages
    
    return self
end

function _M:namespaces()

    return {}
end

return _M

