
local _M = {
    _cls_    = ''    
}

local mt = { __index = _M }

local lx = require('lxlib') 
local app, lf, tb, str = lx.kit()
local throw = lx.throw

function _M:new()

    local this = {
        resolvers    = {},
        resolved    = {}
    }

    setmetatable(this, mt)

    return this
end

function _M:reg(engine, resolver)

    self.resolved[engine] = nil
    self.resolvers[engine] = resolver
end

function _M:resolve(engine)

    local resolved = self.resolved[engine]
    if resolved then 
        return resolved
    end

    local resolver = self.resolvers[engine]
    if resolver then
        resolved = resolver()
        self.resolved[engine] = resolved

        return resolved
    end

    engine = tostring(engine) or 'unkonwn'
    throw('invalidArgumentException', 'engine ' .. engine .. ' not found')
end

return _M

