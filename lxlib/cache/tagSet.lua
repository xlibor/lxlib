
local lx, _M, mt = oo{
    _cls_   = ''
}

local app, lf, tb, str = lx.kit()
local throw = lx.throw

function _M:new(shd, names)

    local this = {
        shd = shd,
        names = names
    }
    
    return oo(this, mt)
end

function _M:reset()

    tb.walk(self.names, {self, 'resetTag'})
end

function _M:tagId(name)

    local shd = self.shd

    return shd:get(self:tagKey(name)) or self:resetTag(name)
end

function _M.__:tagIds()

    return tb.map(self.names, {self, 'tagId'})
end

function _M:getNamespace()

    return str.join(self:tagIds(), '|')
end

function _M:resetTag(name)

    local id = str.random(10)
    local shd = self.shd
    shd:set(self:tagKey(name), id)
    
    return id
end

function _M:tagKey(name)

    return 'tag:' .. name .. ':key'
end

function _M:getNames()

    return self.names
end

return _M

