
local lx, _M, mt = oo{
    _cls_   = '',
    _bond_  = 'cacheStoreBond'
}

local app, lf, tb, str = lx.kit()
local throw = lx.throw

function _M:new(redis, connName)

    local this = {
        redis = redis,
        connName = connName or 'default'
    }
    
    oo(this, mt)

    return this
end

function _M:connection()

    return self.redis:connection(self.connName)
end

function _M:get(key)

    local value = self:connection():get(key)
    
    if value then
        return value
    end
end

function _M:put(key, value, seconds)
 
    return self:connection():setex(key, seconds, value)
end

function _M:update(key, value)

    local conn = self:connection()

    local ttl = conn:ttl(key)
    if ttl > 0 then
        return conn:setex(key, ttl, value)
    elseif ttl == 0 then
        return false
    else
        return conn:set(key, value)
    end
end

function _M:forever(key, value)

    return self:connection():set(key, value)
end

function _M:forget(key)

    return self:connection():del(key)
end

function _M:flush()

    self:connection():flushdb()
end

function _M:getConnection()

    return self.connName
end

function _M:setConnection(connName)

    self.connName = connName
end

function _M:getRedis()

    return self.redis
end

return _M

