
local lx, _M, mt = oo{
    _cls_       = '',
    _bond_      = {'arrable', 'jsonable', 'strable'}
}

local app, lf, tb, str = lx.kit()

function _M:new(attrs)

    local this = {
        attrs = attrs or {}
    }

    return oo(this, mt)
end

function _M:getAttrs()

    return self.attrs
end

function _M:getAttr(name, default)

    local t = self.attrs[name]

    return lf.isset(t) and t or default
end

function _M:setAttr(name, value)

    self.attrs[name] = value
    return self
end

function _M:merge(attrs)

    self.attrs = tb.merge(self.attrs, attrs)
    
    return self
end

function _M:toArr()

    return self.attrs
end

function _M:toJson()

    return lf.jsen(self.attrs)
end

function _M:toStr()

    return self:toJson()
end

function _M:_get_(key)

    return self:getAttr(key)
end

function _M:_set_(key, value)

    self:setAttr(key, value)
end

return _M

