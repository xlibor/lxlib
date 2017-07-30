
local _M = {
    _cls_ = ''
}

local mt = { __index = _M }

local lx = require('lxlib')
local new = lx.new

function _M:new(path, defaults, requirements, options, host, schemes, methods, condition)

    local this = {
        path = path or '',
        host = host or '',
        schemes = schemes or {},
        methods = methods or {},
        defaults = defaults or {},
        requirements = requirements or {},
        options = options or {},
        compiled = nil,
        condition = condition or '',
        compiler = new 'routeCompiler'
    }

    setmetatable(this, mt)

    return this
end

function _M:compile()

    local compiled = self.compiled
    if compiled then
        return compiled
    end

    compiled = self.compiler:compile(self)
    self.compiled = compiled

    return compiled
end
 
function _M:getHost()

    return self.host or ''
end

function _M:getPath()
    
    return self.path or ''
end

function _M:getRequirement(key)

    return self.requirements[key]
end

function _M:getDefault(key)
    
    return self.defaults[key]
end

return _M

