
local lx, _M, mt = oo{
    _cls_   = '',
    _bond_  = 'cacheStoreBond'
}

local app, lf, tb, str, new = lx.kit()
local throw = lx.throw
local ssub = string.sub

function _M:new(connection, table)

    local this = {
        table = table,
        connection = connection
    }
    
    oo(this, mt)

    return this
end

function _M:get(key)

    local cache = self:query():where('key', '=', key):first()
 
    if cache then

        if lf.time() >= cache.expiration then
            self:forget(key)

            return nil, true
        end

        return cache.value
    end
end

function _M:put(key, value, seconds)

    local expiration = self:getTime() + seconds

    local q = self:query()
    q.style = 'replace'
    q:set{key = key, value = value, expiration = expiration}
    q:insert()

    return true
end

function _M:update(key, value)

    local q = self:query()
    q:set{value = value}
    q:where{key = key}:update()

    return true
end

function _M.__:getTime()

    return lf.time()
end

function _M:forever(key, value)

    self:put(key, value, 5256000 * 60)
end

function _M:forget(key)

    self:query():where('key', '=', key):delete()

    return true
end

function _M:flush()

    self:query():delete()
end

function _M.__:query()

    return self.connection:table(self.table)
end

function _M:getConnection()

    return self.connection
end

return _M

