
local lx, _M, mt = oo{
    _cls_   = '',
    _ext_   = 'cache.doer'
}

local app, lf, tb, str = lx.kit()
local throw = lx.throw

function _M:ctor(store, config, tags)

    self.tags = tags
end

function _M:warpKey(key)

    local t = self:taggedItemKey(key)

    return t
end

function _M:flush()

    if self.enable then
        self.tags:reset()
    end
end

function _M:taggedItemKey(key)

    return lf.sha1(self.tags:getNamespace()) .. ':' .. key
end

return _M

