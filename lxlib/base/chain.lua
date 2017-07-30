
local _M = {
    _cls_    = '',
    _bond_     = {'arrable', 'jsonable'},
    _get_run_ = true
}

local mt = {__index = _M}
local lx = require('lxlib')
local app, lf, tb, str = lx.kit()

function _M:new()

    local this = {
        attrs = {},
        appendStyle = 0,
        listMode = false,
        appends = {}
    }

    setmetatable(this, mt)

    return this
end

function _M:ctor(attrs)

    if attrs then
        for k, v in pairs(attrs) do
            self:set(k, v)
        end
    end
end

function _M:get(key, default)

    local t = self.attrs[key]

    return lf.isset(t) and t or lf.value(default)
end

function _M:set(key, value, ...)

    if self.listMode then
        value = {value, ...}
    end
    local appendStyle = self.appendStyle
    if appendStyle == 0 then
        self.attrs[key] = value
    elseif appendStyle == 1 then
        tb.mapd(self.attrs, key, value)
    elseif appendStyle == 2 then
        if self.appends[key] then
            tb.mapd(self.attrs, key, value)
        else
            self.attrs[key] = value
        end
    end

end

function _M:toArr()

    return self.attrs
end

function _M:toJson()

    return lf.jsen(self.attrs)
end

function _M:_get_(key)

    return self:get(key)
end

function _M:_set_(key, value)

    self:set(key, value)
end

function _M:_run_(method)

    return function(self, ...)

        self:set(method, ...)

        return self
    end
end

return _M

