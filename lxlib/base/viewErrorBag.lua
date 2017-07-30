
local lx, _M, mt = oo{
    _cls_ = '',
    _bond_ = 'countable'
}

local app, lf, tb, str, new = lx.kit()

function _M:new()

    local this = {
        bags = {}
    }
    
    return oo(this, mt)
end

function _M:hasBag(key)

    key = key or 'default'
    
    return self.bags[key]
end

function _M:getBag(key)

    return tb.get(self.bags, key) or new('msgBag')
end

function _M:getBags()

    return self.bags
end

function _M:put(key, bag)

    self.bags[key] = bag
    
    return self
end

function _M:count()

    return self:getBag('default'):count()
end

function _M:_get_(key)

    return self:getBag(key)
end

function _M:_set_(key, value)

    self:put(key, value)
end

function _M:getDefaultBag()

    return self:getBag('default')
end

function _M:_run_(method)

    return 'getDefaultBag'
end

return _M

