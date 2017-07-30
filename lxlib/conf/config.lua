
local _M = {
    _cls_ = ''
}

local mt = { __index = _M }

local lx = require('lxlib')
local lf, tb = lx.f, lx.tb

function _M:new(items)
    
    local this = {
        items = items or {}
    }

    setmetatable(this, mt)

    return this
end

function _M:has(key)

    return tb.has(self.items, key)
end

function _M:get(key, default)

    return tb.get(self.items, key, default)
end

function _M:set(key, value)

    if lf.isTbl(key) then
        for innerKey, innerValue in pairs(key) do
            tb.set(self.items, innerKey, innerValue)
        end
    else
        tb.set(self.items, key, value)
    end
end

function _M:prepend(key, value)

    local array = self:get(key)
    tb.unshift(array, value)
    self:set(key, array)
end

function _M:push(key, value)

    local array = self:get(key)
    tapd(array, value)
    self:set(key, array)
end

function _M:all()

    return self.items
end

function _M:_get_(key)

    return self:get(key)
end

return _M

