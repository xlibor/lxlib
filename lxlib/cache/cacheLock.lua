
local lx, _M, mt = oo{
    _cls_ = '',
}

local app, lf, tb, str = lx.kit()
local throw = lx.throw

local shcache = require('lxlib.resty.shcache')

function _M:new()

    local this = {
    }
    
    oo(this, mt)

    return this
end

function _M:ctor(lookup, doer)

    self.dict = doer.shdict
    self:init(lookup, doer)
end

function _M:init(lookup, doer)

    local lock, err = shcache:new(ngx.shared[self.dict],
        {
            external_lookup = lookup
        },
        {
            positive_ttl = doer.pttl,
            negative_ttl = doer.nttl,
            actualize_ttl = 0,
            name = 'lxCache',
        }
    )

    if not lock and err then
        error(err)
    end

    self.lock = lock

    return self
end

function _M:load(key)

    local lock = self.lock
    local data, fromCache = lock:load(key)
    local staleData = lock.stale_data

    if data then
        if fromCache then
            if lock.cache_state == 5 then
                data = nil
            end
            -- local info = staleData and "cache stale" or "cache hit"
            -- info = info .. lock.cache_state
            -- echo( info )
        else
            -- echo "cache miss (valid data)"
        end
    else
        if fromCache then
            -- echo "cache hit negative"
        else
            -- echo "cache miss (bad data)"
        end
    end

    return data, fromCache
end

function _M.put(key, value, seconds)

end

return _M

