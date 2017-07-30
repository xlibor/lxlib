
local _M = {
    _cls_ = ''
}

local mt = { __index = _M }

local lx = require('lxlib')

function _M:new(storeKey, updateThreshold)

    local this = {
        storeKey = storeKey or '',
        updateThreshold = updateThreshold or 0,
        name = '__metadata',
        meta = { c = 0, u = 0, l = 0},
        lastUsed = 0
    }

    setmetatable(this, mt)
    return this
end

function _M:init(tbl)

    self.meta = tbl
    if tbl.c then
        self.lastUsed = tbl.u
        local timestamp = lx.f.timestamp()
        if timestamp - tbl.u >= self.updateThreshold then
            self.meta.u = timestamp
        end
    else
        self:stampCreated()
    end
end

function _M:getLifetime()

    return self.meta.l
end

function _M:stampNew(lifetime)

    self:stampCreated(lifetime)
end

function _M:getStoreKey()

    return self.storeKey
end

function _M:getCreated()

    return self.meta.c
end

function _M:getLastUsed()

    return self.lastUsed
end

function _M:stampCreated(lifetime)
    
    local timestamp = lx.f.timestamp()
    self.meta.c = timestamp
    self.meta.u = timestamp
    self.lastUsed = timestamp
    self.meta.l = lifetime or 0
end

return _M

