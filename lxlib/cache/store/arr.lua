
local lx, _M, mt = oo{
    _cls_   = '',
    _bond_  = 'cacheStoreBond'
}

local app, lf, tb, str, new = lx.kit()

function _M:new()

    local this = {
        storage = {}
    }
    
    oo(this, mt)

    return this
end

function _M:get(key)

    local payload = self.storage[key]
    if payload then
        local value, expire = payload[1], payload[2]
        if lf.time() >= expire then
            self:forget(key)

            return nil, true
        end

        return value, nil, expire
    end
end

function _M:put(key, value, seconds)

    local expire = self:getTime() + seconds
 
    self.storage[key] = {value, expire}

    return true
end

function _M:update(key, value)

    local t = self.storage[key]
    if t then
        t[1] = value
    end

    return true
end

function _M:forever(key, value)

    self:put(key, value, 5256000 * 60)
end

function _M:forget(key)

    self.storage[key] = nil

    return true
end

function _M:flush()

    self.storage = {}
end

function _M.__:getTime()

    return lf.time()
end

return _M

